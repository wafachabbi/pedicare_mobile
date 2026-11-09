import '../../data/nutrition_catalogue.dart';
import '../../models/assistant_models.dart';
import '../../models/enfant_model.dart';
import '../../models/journal_alimentaire_model.dart';
import '../../models/journal_symptome_model.dart';
import '../../models/nutrition_models.dart';
import '../../models/prise_medicament_model.dart';
import '../../models/traitement_model.dart';
import '../journal_alimentaire_service.dart';
import '../journal_symptome_service.dart';
import '../nutrition_service.dart';
import '../traitement_service.dart';
import 'base_connaissances.dart';
import 'embeddings_service.dart';

/// Passage retrouvé pour une question, avec son score de pertinence.
class PassageTrouve {
  final Passage passage;
  final double score;
  const PassageTrouve(this.passage, this.score);
}

/// Dossier de l'enfant transmis au LLM : faits issus de SQLite (lecture seule).
class DossierEnfant {
  final String prenom;
  final int ageMois;
  final String sexe;
  final List<String> allergies;
  final List<String> traitements;
  final List<String> consignes;
  final List<String> symptomesRecents;
  final int repasRecents;

  const DossierEnfant({
    required this.prenom,
    required this.ageMois,
    required this.sexe,
    this.allergies = const [],
    this.traitements = const [],
    this.consignes = const [],
    this.symptomesRecents = const [],
    this.repasRecents = 0,
  });

  String get ageLabel => ageMois < 24 ? '$ageMois mois' : '${ageMois ~/ 12} ans';

  /// Faits lisibles, un par ligne.
  List<String> get faits => [
        '$prenom, ${sexe == 'F' ? 'fille' : 'garçon'}, $ageLabel.',
        'Allergies : ${allergies.isEmpty ? 'aucune connue' : allergies.join(', ')}.',
        if (traitements.isEmpty)
          'Aucun traitement en cours.'
        else
          'Traitements en cours : ${traitements.join(' ; ')}.',
        if (consignes.isNotEmpty) 'Consignes du pédiatre : ${consignes.join(' ; ')}.',
        if (symptomesRecents.isNotEmpty)
          'Journal de santé (7 derniers jours) : ${symptomesRecents.join(' ; ')}.',
        if (repasRecents > 0) '$repasRecents repas notés ces 3 derniers jours.',
      ];
}

/// RAG de l'assistant : recherche des passages pertinents (BM25 local
/// + embeddings Gemini optionnels), construction du prompt avec le dossier de
/// l'enfant, puis citations des sources.
class RagService {
  RagService._();

  /// Nombre de passages transmis au LLM.
  static const int nbPassages = 4;

  /// En dessous de ce score BM25, un passage n'est pas jugé pertinent.
  static const double seuilPertinence = 2.0;

  // ══ Recherche ═════════════════════════════════════════════════════════════

  /// Recherche lexicale BM25 (synchrone, hors ligne).
  static List<PassageTrouve> rechercherBm25(String question,
      {int? ageMois, int k = nbPassages, BaseConnaissances? base}) {
    final b = base ?? BaseConnaissances.instance;
    final scores = b.scoresBm25(question);
    final trouves = <PassageTrouve>[];
    for (var i = 0; i < b.passages.length; i++) {
      var s = scores[i];
      if (s <= 0) continue;
      final p = b.passages[i];
      // Un passage hors de la tranche d'âge de l'enfant est fortement pénalisé.
      if (ageMois != null && !p.concerneAge(ageMois)) s *= 0.3;
      trouves.add(PassageTrouve(p, s));
    }
    trouves.sort((a, b) => b.score.compareTo(a.score));
    return _diversifier(
        trouves.where((t) => t.score >= seuilPertinence).toList(), k);
  }

  /// Recherche hybride : BM25 + similarité sémantique, fusionnés par
  /// Reciprocal Rank Fusion (RRF). Repli sur BM25 seul si pas d'embeddings.
  static Future<List<PassageTrouve>> rechercher(String question,
      {int? ageMois, int k = nbPassages}) async {
    final bm25 = rechercherBm25(question, ageMois: ageMois, k: 12);
    final base = BaseConnaissances.instance;
    final sims = await EmbeddingsService.similarites(question, base.passages);
    if (sims == null) return bm25.take(k).toList();

    final rangsSemantiques = List<int>.generate(base.passages.length, (i) => i)
      ..sort((a, b) => sims[b].compareTo(sims[a]));
    final rrf = <String, double>{};
    final parId = <String, Passage>{};
    for (var r = 0; r < bm25.length; r++) {
      final p = bm25[r].passage;
      rrf[p.id] = (rrf[p.id] ?? 0) + 1 / (60 + r + 1);
      parId[p.id] = p;
    }
    for (var r = 0; r < 12 && r < rangsSemantiques.length; r++) {
      final i = rangsSemantiques[r];
      if (sims[i] < 0.5) break; // trop éloigné sémantiquement
      final p = base.passages[i];
      if (ageMois != null && !p.concerneAge(ageMois)) continue;
      rrf[p.id] = (rrf[p.id] ?? 0) + 1 / (60 + r + 1);
      parId[p.id] = p;
    }
    final fusion = rrf.entries
        .map((e) => PassageTrouve(parId[e.key]!, e.value))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return _diversifier(fusion, k);
  }

  /// Au plus 2 passages par fiche, pour couvrir plusieurs aspects.
  static List<PassageTrouve> _diversifier(List<PassageTrouve> tries, int k) {
    final parFiche = <String, int>{};
    final res = <PassageTrouve>[];
    for (final t in tries) {
      final n = parFiche[t.passage.ficheId] ?? 0;
      if (n >= 2) continue;
      parFiche[t.passage.ficheId] = n + 1;
      res.add(t);
      if (res.length == k) break;
    }
    return res;
  }

  // ══ Dossier de l'enfant (lecture seule) ═══════════════════════════════════

  static Future<DossierEnfant> chargerDossier(EnfantModel enfant) async {
    final now = DateTime.now();
    final allergies = await NutritionService.getAllergies(enfant.id);
    final consignes = await NutritionService.getConseils(enfant.id);
    final traitements = await TraitementService.getActifs(enfant.id);
    final prises = await TraitementService.getPrises(
        enfantId: enfant.id, depuis: now.subtract(const Duration(days: 7)));
    final symptomes = await JournalSymptomeService.getEntreesPeriode(
        enfant.id, now.subtract(const Duration(days: 6)), now);
    final repas = await JournalAlimentaireService.getEntreesPeriode(
        enfant.id, now.subtract(const Duration(days: 2)), now);
    return construireDossier(
      enfant: enfant,
      allergies: allergies,
      consignes: consignes,
      traitements: traitements,
      prises: prises,
      symptomes: symptomes,
      repas: repas,
      maintenant: now,
    );
  }

  /// Construction pure du dossier (testable sans base de données).
  static DossierEnfant construireDossier({
    required EnfantModel enfant,
    List<AllergieAlimentaireModel> allergies = const [],
    List<ConseilNutritionModel> consignes = const [],
    List<TraitementModel> traitements = const [],
    List<PriseMedicamentModel> prises = const [],
    List<JournalSymptomeModel> symptomes = const [],
    List<JournalAlimentaireModel> repas = const [],
    DateTime? maintenant,
  }) {
    final ids = NutritionService.allergenesEnfant(allergies,
        allergiesProfil: enfant.allergies);
    final libres = allergies
        .where((a) => allergeneParId(a.allergene) == null)
        .map((a) => a.allergene);
    return DossierEnfant(
      prenom: enfant.prenom,
      ageMois: NutritionService.ageEnMois(enfant.dateNaissance, le: maintenant),
      sexe: enfant.sexe,
      allergies: {...ids.map(libelleAllergene), ...libres}.toList(),
      traitements: [
        for (final t in traitements)
          [
            t.nom,
            if (t.posologie.isNotEmpty) t.posologie,
            if (t.heures.isNotEmpty) '${t.heures.length}×/jour',
            _observance(prises.where((p) => p.traitementId == t.id)),
          ].where((s) => s.isNotEmpty).join(', '),
      ],
      consignes: consignes.map((c) => c.texte).toList(),
      symptomesRecents: [
        for (final s in symptomes.take(7))
          '${s.date.day}/${s.date.month} : ${s.resumeCourt}'
              '${s.temperature == null ? '' : ' (${s.temperature!.toStringAsFixed(1)} °C)'}',
      ],
      repasRecents: repas.length,
    );
  }

  static String _observance(Iterable<PriseMedicamentModel> prises) {
    final s = ObservanceStats.depuis(prises);
    if (s.taux == null) return '';
    return 'observance ${(s.taux! * 100).round()} % sur 7 jours';
  }

  // ══ Génération ════════════════════════════════════════════════════════════

  /// Prompt « ancré » : le LLM ne doit répondre qu'avec les sources fournies.
  static String construirePrompt({
    required String question,
    required DossierEnfant dossier,
    required List<PassageTrouve> passages,
    List<MessageIA> historique = const [],
    bool urgent = false,
  }) {
    final echanges = historique.length > 6
        ? historique.sublist(historique.length - 6)
        : historique;
    final sources = StringBuffer();
    for (var i = 0; i < passages.length; i++) {
      final p = passages[i].passage;
      sources.writeln('[${i + 1}] ${p.titreComplet} (source : ${p.source})');
      sources.writeln(p.texte);
      sources.writeln();
    }
    return '''
Tu es l'assistant pédiatrique de l'application PediCare. Tu réponds en français
à un parent, avec des phrases simples et bienveillantes (8 phrases maximum).

DOSSIER DE L'ENFANT (données de l'application) :
${dossier.faits.map((f) => '- $f').join('\n')}

SOURCES (base de connaissances PediCare) :
${passages.isEmpty ? '(aucune source pertinente trouvée)' : sources.toString().trim()}

RÈGLES STRICTES :
- réponds UNIQUEMENT à partir des SOURCES et du DOSSIER ci-dessus ;
- cite les sources utilisées avec leur numéro entre crochets, ex. [1] ou [2] ;
- si les sources ne permettent pas de répondre, dis-le clairement et conseille de consulter le pédiatre ;
- adapte la réponse à l'âge, aux allergies et aux traitements de l'enfant ;
- aucun diagnostic, aucune dose de médicament, ne jamais conseiller de modifier ou arrêter un traitement prescrit ;
${urgent ? '- la question contient des signes d\'alerte : commence par demander d\'appeler le SAMU (190 en Tunisie, 15 en France) ;\n' : ''}- texte brut, sans markdown.
${echanges.isEmpty ? '' : '\nÉCHANGES PRÉCÉDENTS :\n${echanges.map((m) => '${m.duParent ? 'Parent' : 'Assistant'} : ${m.texte}').join('\n')}\n'}
QUESTION DU PARENT : $question
''';
  }

  /// Sources numérotées correspondant aux passages.
  static List<SourceCitee> sourcesDe(List<PassageTrouve> passages) => [
        for (var i = 0; i < passages.length; i++)
          SourceCitee(
            numero: i + 1,
            passageId: passages[i].passage.id,
            titre: passages[i].passage.titreComplet,
            source: passages[i].passage.source,
          ),
      ];

  /// Garde les sources effectivement citées ([n]) dans la réponse du LLM.
  /// Si aucune citation n'est trouvée, toutes les sources fournies sont gardées.
  static List<SourceCitee> sourcesCitees(String reponse, List<SourceCitee> toutes) {
    final cites = RegExp(r'\[(\d+)\]')
        .allMatches(reponse)
        .map((m) => int.parse(m.group(1)!))
        .toSet();
    final gardees = toutes.where((s) => cites.contains(s.numero)).toList();
    return gardees.isEmpty ? toutes : gardees;
  }

  /// Réponse extractive (sans LLM) : les passages retrouvés, cités.
  static String reponseExtractive({
    required String question,
    required DossierEnfant dossier,
    required List<PassageTrouve> passages,
  }) {
    if (passages.isEmpty) {
      return 'Je n\'ai pas trouvé d\'information fiable dans la base PediCare pour '
          'cette question. Je peux vous renseigner sur la fièvre, la toux, la gastro, '
          'le sommeil, l\'alimentation, les médicaments ou les gestes d\'urgence. '
          'Pour toute inquiétude, parlez-en au pédiatre de ${dossier.prenom}.';
    }
    final b = StringBuffer('Voici ce que disent les fiches PediCare :\n');
    for (var i = 0; i < passages.length && i < 3; i++) {
      final p = passages[i].passage;
      b.writeln();
      b.writeln('${p.emoji} ${p.titreComplet}');
      b.writeln('${p.texte} [${i + 1}]');
    }
    final perso = _personnalisation(question, dossier);
    if (perso.isNotEmpty) {
      b.writeln();
      b.writeln('Pour ${dossier.prenom} : $perso');
    }
    b.writeln();
    b.write('En cas de doute, demandez l\'avis du pédiatre.');
    return b.toString();
  }

  /// Rappels tirés du dossier, selon le thème de la question.
  static String _personnalisation(String question, DossierEnfant d) {
    final q = NutritionService.normaliser(question);
    final rappels = <String>[];
    final parleAliment = ['mange', 'manger', 'repas', 'aliment', 'nourri', 'allergi']
        .any(q.contains);
    final parleMedicament = ['medicament', 'sirop', 'traitement', 'antibiotique', 'dose']
        .any(q.contains);
    if (parleAliment && d.allergies.isNotEmpty) {
      rappels.add('attention à ses allergies (${d.allergies.join(', ')}).');
    }
    if (parleMedicament && d.traitements.isNotEmpty) {
      rappels.add('traitements en cours : ${d.traitements.join(' ; ')}.');
    }
    if (parleAliment && d.consignes.isNotEmpty) {
      rappels.add('consigne du pédiatre : ${d.consignes.first}');
    }
    return rappels.join(' ');
  }
}
