import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/activite_model.dart';
import '../models/enfant_model.dart';
import 'database_service.dart';
import 'eveil_service.dart';

/// Une activité recommandée + la raison (IA explicable)
class Recommandation {
  final ActiviteModel activite;
  final String raison;
  final int score;
  const Recommandation(this.activite, this.raison, this.score);
}

/// Résultat d'un domaine de développement
class DomaineBilan {
  final String categorie;
  final String label;
  final int nbSeances;
  final double scoreMoyen;
  final int minutes;

  const DomaineBilan({
    required this.categorie,
    required this.label,
    required this.nbSeances,
    required this.scoreMoyen,
    required this.minutes,
  });

  String get niveau {
    if (nbSeances == 0) return 'Non exploré';
    if (scoreMoyen >= 80) return 'Très bien';
    if (scoreMoyen >= 50) return 'En bonne voie';
    return 'À stimuler';
  }
}

/// Bilan complet de développement
class BilanEveil {
  final List<DomaineBilan> domaines;
  final int totalSeances;
  final int totalMinutes;
  final String texte;
  final bool geminiDisponible;

  const BilanEveil({
    required this.domaines,
    required this.totalSeances,
    required this.totalMinutes,
    required this.texte,
    required this.geminiDisponible,
  });
}

class IAEveilService {
  // La clé n'est JAMAIS écrite dans le code : elle est passée au lancement
  // avec --dart-define=GEMINI_API_KEY=xxxx
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  static const Map<String, String> _labels = {
    'langage': 'Langage',
    'memoire': 'Mémoire',
    'logique': 'Logique',
    'motricite': 'Motricité',
  };

  // ── 1. Recommandation d'activités (moteur local, explicable) ──────────────
  static Future<List<Recommandation>> recommander(EnfantModel enfant, {int nb = 3}) async {
    final ageMois = EveilService.ageEnMois(enfant.dateNaissance);
    final activites = await EveilService.getActivitesPourAge(ageMois);
    final stats = await EveilService.getStatsParCategorie(enfant.id);
    final favoris = await EveilService.getFavoris(enfant.id);
    final derniers = await _derniereFoisParActivite(enfant.id);
    final now = DateTime.now();

    final recos = <Recommandation>[];
    for (final a in activites) {
      int score = 0;
      String raison = 'Adaptée à ses $ageMois mois';
      final stat = stats[a.categorie];

      if (stat == null) {
        score += 40;
        raison = 'Nouveau domaine à découvrir : ${a.categorieLabel}';
      } else if (stat['score_moyen']! < 60) {
        score += 30;
        raison = 'Pour renforcer : ${a.categorieLabel}';
      }

      if (favoris.contains(a.id)) {
        score += 20;
        if (stat != null && stat['score_moyen']! >= 60) {
          raison = 'Une de ses activités préférées ❤️';
        }
      }

      final derniere = derniers[a.id];
      if (derniere == null) {
        score += 15; // jamais faite
      } else if (now.difference(derniere).inHours < 24) {
        score -= 30; // déjà faite aujourd'hui → varier
      }

      recos.add(Recommandation(a, raison, score));
    }

    recos.sort((x, y) => y.score.compareTo(x.score));
    return recos.take(nb).toList();
  }

  static Future<Map<int, DateTime>> _derniereFoisParActivite(String enfantId) async {
    final db = await DatabaseService.database;
    final rows = await db.rawQuery('''
      SELECT activite_id, MAX(created_at) AS d
      FROM seances_jeu
      WHERE enfant_id = ?
      GROUP BY activite_id
    ''', [int.parse(enfantId)]);

    final map = <int, DateTime>{};
    for (final r in rows) {
      final s = r['d'] as String?;
      if (s == null) continue;
      // SQLite stocke en UTC "2026-11-09 08:30:00"
      final d = DateTime.tryParse('${s.replaceFirst(' ', 'T')}Z')?.toLocal();
      if (d != null) map[r['activite_id'] as int] = d;
    }
    return map;
  }

  // ── 2. Bilan de développement (statistiques + Gemini) ─────────────────────
  static Future<BilanEveil> genererBilan(EnfantModel enfant) async {
    final ageMois = EveilService.ageEnMois(enfant.dateNaissance);
    final stats = await EveilService.getStatsParCategorie(enfant.id);

    final domaines = _labels.entries.map((e) {
      final s = stats[e.key];
      return DomaineBilan(
        categorie: e.key,
        label: e.value,
        nbSeances: (s?['nb'] ?? 0).toInt(),
        scoreMoyen: (s?['score_moyen'] ?? 0).toDouble(),
        minutes: ((s?['duree_totale'] ?? 0) / 60).round(),
      );
    }).toList();

    final totalSeances = domaines.fold<int>(0, (t, d) => t + d.nbSeances);
    final totalMinutes = domaines.fold<int>(0, (t, d) => t + d.minutes);

    final (texte, ok) = await _appelGemini(enfant, ageMois, domaines, totalSeances);

    return BilanEveil(
      domaines: domaines,
      totalSeances: totalSeances,
      totalMinutes: totalMinutes,
      texte: texte,
      geminiDisponible: ok,
    );
  }

  static Future<(String, bool)> _appelGemini(
      EnfantModel enfant,
      int ageMois,
      List<DomaineBilan> domaines,
      int totalSeances,
      ) async {
    if (_apiKey.isEmpty || totalSeances == 0) {
      return (_fallback(enfant, ageMois, domaines, totalSeances), false);
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-3.8-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(temperature: 0.6, maxOutputTokens: 1024),
      );

      final il = enfant.sexe == 'F' ? 'elle' : 'il';
      final domainesStr = domaines
          .map((d) => '- ${d.label} : ${d.nbSeances} séance(s), score moyen '
          '${d.scoreMoyen.round()} %, niveau "${d.niveau}"')
          .join('\n');

      final prompt = '''
Tu es un assistant IA de l'application PediCare, spécialisé dans l'éveil et le développement de l'enfant.
Rédige un bilan de développement en français pour les parents de ${enfant.prenom}.

Données :
- Prénom : ${enfant.prenom}
- Sexe : ${enfant.sexe == 'F' ? 'Fille' : 'Garçon'}
- Âge : $ageMois mois
- Nombre total d'activités réalisées : $totalSeances
- Résultats par domaine :
$domainesStr

Instructions :
- 4 à 6 phrases, ton bienveillant et clair
- Compare brièvement aux étapes de développement attendues pour $ageMois mois (langage, mémoire, logique, motricité)
- Souligne le point fort de ${enfant.prenom}
- Propose 2 activités concrètes à faire à la maison pour le domaine le plus faible ou non exploré
- Utilise "$il" et le prénom ${enfant.prenom}
- Termine en rappelant que ce bilan ne remplace pas l'avis du pédiatre
- Texte pur, sans markdown, sans listes
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';
      if (text.isEmpty) {
        return (_fallback(enfant, ageMois, domaines, totalSeances), false);
      }
      return (text, true);
    } catch (_) {
      return (_fallback(enfant, ageMois, domaines, totalSeances), false);
    }
  }

  /// Bilan local si pas de clé API ou pas de réseau
  static String _fallback(
      EnfantModel enfant, int ageMois, List<DomaineBilan> domaines, int total) {
    final prenom = enfant.prenom;
    if (total == 0) {
      return "$prenom n'a pas encore réalisé d'activité. Commencez par un jeu "
          'adapté à ses $ageMois mois pour obtenir un premier bilan.';
    }

    final explores = domaines.where((d) => d.nbSeances > 0).toList()
      ..sort((a, b) => b.scoreMoyen.compareTo(a.scoreMoyen));
    final nonExplores =
    domaines.where((d) => d.nbSeances == 0).map((d) => d.label.toLowerCase()).toList();
    final fort = explores.first;
    final faible = explores.last;

    final b = StringBuffer('$prenom ($ageMois mois) a réalisé $total activité(s). ');
    b.write('Son point fort est : ${fort.label.toLowerCase()} (${fort.scoreMoyen.round()} %). ');
    if (explores.length > 1 && faible.scoreMoyen < 60) {
      b.write('${faible.label} mérite d\'être stimulé(e) avec des jeux courts et réguliers. ');
    }
    if (nonExplores.isNotEmpty) {
      b.write('Domaines à découvrir : ${nonExplores.join(', ')}. ');
    }
    b.write("Ce bilan est indicatif et ne remplace pas l'avis du pédiatre.");
    return b.toString();
  }
}