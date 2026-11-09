import '../../data/medicaments_catalogue.dart';
import '../../data/nutrition_catalogue.dart';
import '../../data/rag/fiches_sante.dart';
import 'bm25.dart';

/// Passage indexé de la base de connaissances (une section de fiche).
class Passage {
  final String id;
  final String ficheId;
  final String ficheTitre;
  final String section;
  final String texte;
  final String source;
  final String categorie;
  final String emoji;
  final int? ageMinMois;
  final int? ageMaxMois;

  /// Mots-clés de la fiche (indexés avec le texte).
  final List<String> motsCles;

  const Passage({
    required this.id,
    required this.ficheId,
    required this.ficheTitre,
    required this.section,
    required this.texte,
    required this.source,
    required this.categorie,
    required this.emoji,
    this.ageMinMois,
    this.ageMaxMois,
    this.motsCles = const [],
  });

  String get titreComplet => '$ficheTitre — $section';

  /// Texte utilisé pour l'indexation et les embeddings.
  String get texteIndexe =>
      '$ficheTitre. $section. $texte ${motsCles.join(' ')}';

  /// L'âge de l'enfant est-il dans la tranche du passage ?
  bool concerneAge(int ageMois) =>
      (ageMinMois == null || ageMois >= ageMinMois!) &&
      (ageMaxMois == null || ageMois <= ageMaxMois!);
}

/// Base de connaissances du RAG : fiches santé + catalogues de l'application
/// (médicaments, repères nutritionnels), découpés en passages et indexés.
class BaseConnaissances {
  BaseConnaissances._(this.passages, this._index);

  final List<Passage> passages;
  final Bm25Index _index;

  static BaseConnaissances? _instance;

  /// Base construite une seule fois (en mémoire, quelques millisecondes).
  static BaseConnaissances get instance => _instance ??= construire();

  static BaseConnaissances construire() {
    final passages = <Passage>[
      ..._depuisFiches(),
      ..._depuisMedicaments(),
      ..._depuisNutrition(),
    ];
    final index = Bm25Index();
    for (final p in passages) {
      // Le titre et les mots-clés comptent double : ils décrivent le sujet.
      index.ajouter([
        ...TokeniseurFr.tokens(p.texte),
        ...TokeniseurFr.tokens('${p.ficheTitre} ${p.section} ${p.motsCles.join(' ')}'),
        ...TokeniseurFr.tokens('${p.ficheTitre} ${p.motsCles.join(' ')}'),
      ]);
    }
    return BaseConnaissances._(passages, index);
  }

  /// Scores BM25 de la question pour chaque passage (même ordre que [passages]).
  List<double> scoresBm25(String question) =>
      _index.scores(TokeniseurFr.tokens(question, avecSynonymes: true));

  /// Nombre de fiches distinctes.
  int get nombreFiches => passages.map((p) => p.ficheId).toSet().length;

  // ── Construction des passages ──

  static Iterable<Passage> _depuisFiches() sync* {
    for (final f in fichesSante) {
      for (var i = 0; i < f.sections.length; i++) {
        final s = f.sections[i];
        yield Passage(
          id: '${f.id}#$i',
          ficheId: f.id,
          ficheTitre: f.titre,
          section: s.titre,
          texte: s.texte,
          source: f.source,
          categorie: f.categorie,
          emoji: f.emoji,
          ageMinMois: f.ageMinMois,
          ageMaxMois: f.ageMaxMois,
          motsCles: f.motsCles,
        );
      }
    }
  }

  static Iterable<Passage> _depuisMedicaments() sync* {
    for (final m in medicamentsCatalogue) {
      final noms = m.nomsCommerciaux.join(', ');
      final texte = StringBuffer('${m.dci} ($noms) : ${m.classe}. ${m.usage}');
      if (m.conseils.isNotEmpty) texte.write(' ${m.conseils.join(' ')}');
      if (m.precautions.isNotEmpty) texte.write(' ${m.precautions.join(' ')}');
      yield Passage(
        id: 'med_${m.id}#0',
        ficheId: 'med_${m.id}',
        ficheTitre: m.dci,
        section: 'Informations générales',
        texte: texte.toString(),
        source: 'Base médicaments PediCare',
        categorie: 'Médicaments',
        emoji: '💊',
        motsCles: ['medicament', ...m.nomsCommerciaux],
      );
    }
  }

  static Iterable<Passage> _depuisNutrition() sync* {
    for (final t in tranchesAge) {
      yield Passage(
        id: 'nutri_${t.minMois}#0',
        ficheId: 'nutri_${t.minMois}',
        ficheTitre: 'Alimentation ${t.titre}',
        section: 'Repères',
        texte: t.conseils.join(' '),
        source: 'Santé publique France (mangerbouger.fr)',
        categorie: 'Nutrition',
        emoji: t.emoji,
        ageMinMois: t.minMois,
        ageMaxMois: t.maxMois == null ? null : t.maxMois! - 1,
        motsCles: const ['alimentation', 'repas', 'manger', 'diversification', 'nutrition'],
      );
    }
    yield Passage(
      id: 'nutri_eviter#0',
      ficheId: 'nutri_eviter',
      ficheTitre: 'Aliments à éviter selon l\'âge',
      section: 'Repères',
      texte: reglesAge
          .map((r) => '${r.aliment} : à éviter jusqu\'à ${r.ageMinMois} mois. ${r.raison}')
          .join(' '),
      source: 'Santé publique France (mangerbouger.fr)',
      categorie: 'Nutrition',
      emoji: '⛔',
      motsCles: const ['interdit', 'eviter', 'miel', 'aliment', 'danger', 'manger'],
    );
  }
}
