import 'dart:convert';
import '../data/medicaments_catalogue.dart';
import '../models/enfant_model.dart';
import '../models/traitement_model.dart';
import 'gemini_service.dart';
import 'nutrition_service.dart';

/// Alerte d'interaction entre deux traitements.
class AlerteInteraction {
  final bool danger;
  final String titre;
  final String message;
  const AlerteInteraction(
      {required this.danger, required this.titre, required this.message});
}

/// Explication d'un médicament en langage simple.
class ExplicationMedicament {
  final String texte;

  /// Vrai si le texte vient de Gemini, faux s'il vient de la base locale.
  final bool parIA;
  final Medicament? reference;

  const ExplicationMedicament(
      {required this.texte, required this.parIA, this.reference});
}

/// Ligne de médicament extraite d'une ordonnance.
class LigneOrdonnance {
  final String nom;
  final String posologie;

  /// Nombre de prises par jour (0 = inconnu / si besoin).
  final int prisesParJour;
  final int? dureeJours;
  final Medicament? reference;

  const LigneOrdonnance({
    required this.nom,
    this.posologie = '',
    this.prisesParJour = 0,
    this.dureeJours,
    this.reference,
  });
}

/// Résultat de l'analyse d'une ordonnance.
class OrdonnanceAnalysee {
  final List<LigneOrdonnance> lignes;
  final String medecin;
  final bool parIA;

  const OrdonnanceAnalysee(
      {required this.lignes, this.medecin = '', this.parIA = false});
}

/// Module 5 — partie IA de PediPharma : identification des médicaments,
/// interactions, explication en langage simple et analyse d'ordonnance (OCR).
///
/// Gemini est utilisé s'il est configuré ; sinon, tout fonctionne avec la
/// base locale [medicamentsCatalogue] et des règles d'analyse.
class IaPharmaService {
  IaPharmaService._();

  // ══ Identification ════════════════════════════════════════════════════════

  /// Retrouve un médicament du catalogue à partir d'un nom saisi ou lu
  /// (molécule ou nom commercial, accents et casse ignorés).
  static Medicament? identifier(String nom) {
    final texte = ' ${NutritionService.normaliser(nom)} ';
    if (texte.trim().isEmpty) return null;
    // Les noms les plus longs d'abord (« amoxicilline acide clavulanique »
    // avant « amoxicilline »).
    final candidats = <(String, Medicament)>[];
    for (final m in medicamentsCatalogue) {
      for (final n in [m.dci, ...m.nomsCommerciaux]) {
        final cle = NutritionService.normaliser(n);
        if (cle.isNotEmpty) candidats.add((cle, m));
        // Pour « Prednisolone / bétaméthasone », chaque molécule compte.
        for (final partie in n.split(RegExp(r'[/+]'))) {
          final p = NutritionService.normaliser(partie);
          if (p.length >= 5 && p != cle) candidats.add((p, m));
        }
      }
    }
    candidats.sort((a, b) => b.$1.length.compareTo(a.$1.length));
    for (final (cle, m) in candidats) {
      if (texte.contains(' $cle ')) return m;
    }
    return null;
  }

  // ══ Interactions ══════════════════════════════════════════════════════════

  /// Interactions entre le traitement [nouveau] et les traitements actifs.
  static List<AlerteInteraction> interactions(
      String nouveau, List<TraitementModel> actifs) {
    final m = identifier(nouveau);
    if (m == null) return const [];
    final alertes = <AlerteInteraction>[];
    for (final t in actifs) {
      final autre = identifier(t.nom);
      if (autre == null) continue;
      if (autre.id == m.id) {
        alertes.add(AlerteInteraction(
          danger: true,
          titre: 'Doublon : ${m.dci}',
          message: '« ${t.nom} » contient déjà la même molécule. '
              'Risque de surdosage.',
        ));
      } else if (m.famille == FamilleMedicament.ains &&
          autre.famille == FamilleMedicament.ains) {
        alertes.add(AlerteInteraction(
          danger: true,
          titre: 'Deux anti-inflammatoires',
          message: '${m.dci} et « ${t.nom} » sont deux AINS : leur '
              'association est déconseillée.',
        ));
      } else if ({m.famille, autre.famille}
          .containsAll({FamilleMedicament.ains, FamilleMedicament.corticoide})) {
        alertes.add(AlerteInteraction(
          danger: false,
          titre: 'Anti-inflammatoire + corticoïde',
          message: 'Association à surveiller (risque digestif accru).',
        ));
      } else if (m.famille == FamilleMedicament.pansementDigestif ||
          autre.famille == FamilleMedicament.pansementDigestif) {
        alertes.add(AlerteInteraction(
          danger: false,
          titre: 'Espacer les prises',
          message: 'Le pansement digestif peut gêner l\'absorption de '
              '« ${m.famille == FamilleMedicament.pansementDigestif ? t.nom : nouveau} » : '
              'espacer d\'environ 2 heures.',
        ));
      }
    }
    return alertes;
  }

  // ══ Explication en langage simple ═════════════════════════════════════════

  static Future<ExplicationMedicament> expliquer(
      TraitementModel t, EnfantModel enfant) async {
    final ref = identifier(t.nom);
    final ia = await GeminiService.generer(
      prompt: _promptExplication(t, enfant, ref),
      temperature: 0.3,
      maxOutputTokens: 700,
    );
    if (ia != null) {
      return ExplicationMedicament(texte: ia, parIA: true, reference: ref);
    }
    return ExplicationMedicament(
        texte: explicationLocale(t, ref), parIA: false, reference: ref);
  }

  static String _promptExplication(
      TraitementModel t, EnfantModel enfant, Medicament? ref) {
    final age = NutritionService.ageEnMois(enfant.dateNaissance);
    return '''
Tu es l'assistant PediPharma d'une application de suivi pédiatrique.
Explique à un parent, en français simple (6 à 10 phrases courtes, sans jargon),
le médicament suivant prescrit à son enfant de $age mois.

Médicament : ${t.nom}
Posologie prescrite : ${t.posologie.isEmpty ? 'non précisée' : t.posologie}
Fréquence : ${t.heures.isEmpty ? 'si besoin' : '${t.heures.length} fois par jour (${t.heures.join(', ')})'}
${ref == null ? '' : 'Référence : ${ref.dci} — ${ref.classe}.'}

Règles strictes :
- explique à quoi il sert, comment le donner et les points de vigilance courants ;
- ne donne AUCUNE dose et ne propose jamais de modifier la posologie prescrite ;
- ne pose aucun diagnostic ;
- termine par : « En cas de doute, demandez à votre médecin ou à votre pharmacien. »
- texte brut, sans markdown.
''';
  }

  /// Explication construite à partir de la base locale.
  static String explicationLocale(TraitementModel t, Medicament? ref) {
    final b = StringBuffer();
    if (ref == null) {
      b.writeln('« ${t.nom} » ne figure pas dans la base locale de PediCare.');
      b.writeln();
      b.writeln('Donnez-le exactement comme prescrit'
          '${t.posologie.isEmpty ? '' : ' (${t.posologie})'}'
          '${t.heures.isEmpty ? '' : ', ${t.heures.length} fois par jour'}.');
      b.writeln('Lisez la notice et demandez conseil à votre pharmacien.');
      return b.toString().trim();
    }
    b.writeln('${ref.dci} — ${ref.classe}.');
    b.writeln();
    b.writeln('À quoi il sert : ${ref.usage}');
    if (ref.conseils.isNotEmpty) {
      b.writeln();
      b.writeln('Comment le donner :');
      for (final c in ref.conseils) {
        b.writeln('• $c');
      }
    }
    if (ref.precautions.isNotEmpty) {
      b.writeln();
      b.writeln('Points de vigilance :');
      for (final p in ref.precautions) {
        b.writeln('• $p');
      }
    }
    b.writeln();
    b.write('En cas de doute, demandez à votre médecin ou à votre pharmacien.');
    return b.toString();
  }

  // ══ Analyse d'ordonnance (texte issu de l'OCR Tesseract) ══════════════════

  /// Structure le texte OCR. Essaie Gemini, puis l'analyse locale.
  static Future<OrdonnanceAnalysee> analyserOrdonnance(String texteOcr) async {
    final ia = await GeminiService.generer(
      prompt: _promptOrdonnance(texteOcr),
      temperature: 0.1,
      maxOutputTokens: 900,
    );
    final viaIa = ia == null ? null : parserReponseIA(ia);
    if (viaIa != null && viaIa.lignes.isNotEmpty) return viaIa;
    return analyserLocalement(texteOcr);
  }

  static String _promptOrdonnance(String texte) => '''
Voici le texte brut (OCR, avec des erreurs possibles) d'une ordonnance pédiatrique.
Extrais les médicaments. Réponds UNIQUEMENT avec un JSON de cette forme :
{"medecin": "nom du médecin ou vide",
 "medicaments": [{"nom": "...", "posologie": "...", "prises_par_jour": 2, "duree_jours": 7}]}
Utilise null si une valeur est absente. N'invente rien qui ne soit pas dans le texte.

Texte :
"""
$texte
"""
''';

  /// Lit la réponse JSON de Gemini (éventuellement entourée de ```json).
  static OrdonnanceAnalysee? parserReponseIA(String reponse) {
    final debut = reponse.indexOf('{');
    final fin = reponse.lastIndexOf('}');
    if (debut < 0 || fin <= debut) return null;
    try {
      final json = jsonDecode(reponse.substring(debut, fin + 1));
      if (json is! Map) return null;
      final lignes = <LigneOrdonnance>[];
      for (final m in (json['medicaments'] as List? ?? const [])) {
        if (m is! Map) continue;
        final nom = (m['nom'] ?? '').toString().trim();
        if (nom.isEmpty) continue;
        lignes.add(LigneOrdonnance(
          nom: nom,
          posologie: (m['posologie'] ?? '').toString().trim(),
          prisesParJour: (m['prises_par_jour'] as num?)?.toInt() ?? 0,
          dureeJours: (m['duree_jours'] as num?)?.toInt(),
          reference: identifier(nom),
        ));
      }
      return OrdonnanceAnalysee(
        lignes: lignes,
        medecin: (json['medecin'] ?? '').toString().trim(),
        parIA: true,
      );
    } catch (_) {
      return null;
    }
  }

  /// Analyse locale par règles : une ligne contenant un médicament connu
  /// (ou une forme galénique) devient une ligne d'ordonnance.
  static OrdonnanceAnalysee analyserLocalement(String texteOcr) {
    final lignesBrutes = texteOcr
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    var medecin = '';
    final resultat = <LigneOrdonnance>[];
    for (var i = 0; i < lignesBrutes.length; i++) {
      final ligne = lignesBrutes[i];
      final n = NutritionService.normaliser(ligne);
      if (medecin.isEmpty) {
        final dr = RegExp(r'\b(?:dr|docteur)\.?\s+([A-Za-zÀ-ÿ\- ]{2,40})',
                caseSensitive: false)
            .firstMatch(ligne);
        if (dr != null) {
          medecin = 'Dr. ${dr.group(1)!.trim()}';
          continue;
        }
      }
      final ref = identifier(ligne);
      final formeGalenique = RegExp(
              r'\b(sirop|suspension|comprime|gelule|sachet|suppositoire|gouttes|solution|pommade|creme|ampoule|flacon)s?\b')
          .hasMatch(n);
      if (ref == null && !formeGalenique) continue;

      // La posologie est souvent sur la même ligne ou la suivante.
      final suite = i + 1 < lignesBrutes.length ? lignesBrutes[i + 1] : '';
      final contexte = '$ligne $suite';
      resultat.add(LigneOrdonnance(
        nom: _nomPropre(ligne, ref),
        posologie: extrairePosologie(contexte),
        prisesParJour: extrairePrisesParJour(contexte),
        dureeJours: extraireDuree(contexte),
        reference: ref,
      ));
    }
    return OrdonnanceAnalysee(lignes: resultat, medecin: medecin);
  }

  static String _nomPropre(String ligne, Medicament? ref) {
    // Retire les numéros de ligne (« 1) », « - ») en début de ligne.
    final propre = ligne.replaceFirst(RegExp(r'^[\s\-•*\d.)]+'), '').trim();
    if (propre.isNotEmpty && propre.length <= 60) return propre;
    return ref?.nomsCommerciaux.first ?? ligne;
  }

  /// « 5 ml », « 1 sachet », « 2 bouffées », « 250 mg »…
  static String extrairePosologie(String texte) {
    final m = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(ml|mg|g|gouttes?|sachets?|comprimes?|comprimés?|bouffees?|bouffées?|doses?|cuilleres?|cuillères?|pipettes?|suppositoires?|kg)\b',
      caseSensitive: false,
    ).firstMatch(texte);
    return m == null ? '' : '${m.group(1)} ${m.group(2)!.toLowerCase()}';
  }

  /// « 3 fois par jour », « 2x/j », « matin et soir », « toutes les 8 h ».
  static int extrairePrisesParJour(String texte) {
    final n = NutritionService.normaliser(texte);
    final fois = RegExp(r'(\d)\s*(?:fois|x)\s*(?:par|p|\/)?\s*(?:jour|j)\b')
        .firstMatch(n.replaceAll('/', ' / '));
    if (fois != null) return int.parse(fois.group(1)!);
    final toutes = RegExp(r'toutes les\s*(\d{1,2})\s*h').firstMatch(n);
    if (toutes != null) {
      final h = int.parse(toutes.group(1)!);
      if (h > 0 && h <= 24) return (24 / h).floor();
    }
    if (n.contains('matin midi et soir') || n.contains('matin midi soir')) {
      return 3;
    }
    if (n.contains('matin et soir')) return 2;
    return 0;
  }

  /// « pendant 7 jours », « 10 j », « 5 jours ».
  static int? extraireDuree(String texte) {
    final n = NutritionService.normaliser(texte);
    final m = RegExp(r'(?:pendant|durant)?\s*(\d{1,2})\s*(?:jours|jour|j)\b')
        .allMatches(n)
        .where((x) => !RegExp(r'(fois|x)\s*(par|p)?\s*$')
            .hasMatch(n.substring(0, x.start)))
        .toList();
    if (m.isEmpty) return null;
    return int.parse(m.last.group(1)!);
  }
}
