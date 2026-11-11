import 'package:flutter_test/flutter_test.dart';
import 'package:projet_mobile/data/rag/fiches_sante.dart';
import 'package:projet_mobile/models/assistant_models.dart';
import 'package:projet_mobile/models/enfant_model.dart';
import 'package:projet_mobile/models/journal_symptome_model.dart';
import 'package:projet_mobile/models/nutrition_models.dart';
import 'package:projet_mobile/models/prise_medicament_model.dart';
import 'package:projet_mobile/models/traitement_model.dart';
import 'package:projet_mobile/services/assistant_ia_service.dart';
import 'package:projet_mobile/services/gemini_service.dart';
import 'package:projet_mobile/services/rag/base_connaissances.dart';
import 'package:projet_mobile/services/rag/bm25.dart';
import 'package:projet_mobile/services/rag/embeddings_service.dart';
import 'package:projet_mobile/services/rag/rag_service.dart';

/// Fiche du meilleur passage trouvé.
String? top(String question, {int? age}) {
  final r = RagService.rechercherBm25(question, ageMois: age);
  return r.isEmpty ? null : r.first.passage.ficheId;
}

const _dossier = DossierEnfant(
  prenom: 'Adam',
  ageMois: 18,
  sexe: 'M',
  allergies: ['Œuf'],
  traitements: ['Clamoxyl, 5 ml, 3×/jour'],
);

void main() {
  // Aucun appel réseau dans les tests : LLM et embeddings désactivés.
  setUpAll(GeminiService.desactiverPourTests);

  group('Base de connaissances', () {
    final base = BaseConnaissances.instance;

    test('fiches rédigées + catalogues de l\'application', () {
      expect(fichesSante.length, greaterThanOrEqualTo(30));
      expect(base.nombreFiches, greaterThanOrEqualTo(50));
    });

    test('identifiants uniques et chaque passage a une source', () {
      final ids = base.passages.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final p in base.passages) {
        expect(p.source, isNotEmpty, reason: p.id);
        expect(p.texte.length, greaterThan(30), reason: p.id);
      }
    });

    test('aucune fiche ne donne de posologie chiffrée', () {
      final dose = RegExp(r'\d+\s*(mg|ml|mg/kg)\b', caseSensitive: false);
      for (final f in fichesSante) {
        for (final s in f.sections) {
          expect(dose.hasMatch(s.texte), isFalse, reason: '${f.id} / ${s.titre}');
        }
      }
    });
  });

  group('Tokenisation française', () {
    test('accents, pluriels et suffixes rapprochés', () {
      expect(TokeniseurFr.tokens('Vomissements'), TokeniseurFr.tokens('vomissement'));
      expect(TokeniseurFr.tokens('FIÈVRE'), TokeniseurFr.tokens('fievre'));
    });

    test('mots vides retirés, synonymes ajoutés', () {
      final t = TokeniseurFr.tokens('mon bébé fait mal ses dodo', avecSynonymes: true);
      expect(t, isNot(contains('mon')));
      expect(t, contains(TokeniseurFr.raciner('sommeil')));
    });
  });

  group('Recherche BM25', () {
    test('questions de parents → bonne fiche', () {
      expect(top('mon fils a 39 de fièvre depuis hier'), 'fievre');
      expect(top('il vomit et a la diarrhée depuis ce matin'), 'gastro');
      expect(top('elle a avalé de la javel'), 'intoxication');
      expect(top('comment faire un lavage de nez'), 'lavage_nez');
      expect(top('il a pris une casserole d\'eau chaude, brûlure'), 'brulure');
      expect(top('que donner pour les dents qui poussent', age: 8), 'dents');
      expect(top('combien de temps d\'écran par jour'), 'ecrans');
    });

    test('nom commercial de médicament → fiche médicament', () {
      expect(top('à quoi sert le Doliprane'), 'med_paracetamol');
    });

    test('l\'âge de l\'enfant oriente la recherche', () {
      final bebe = RagService.rechercherBm25('comment le coucher pour dormir', ageMois: 3);
      expect(bebe.first.passage.ficheId, 'sommeil_sur');
      final grand = RagService.rechercherBm25('comment le coucher pour dormir', ageMois: 72);
      expect(grand.first.passage.ficheId, 'sommeil');
    });

    test('repères nutritionnels de la bonne tranche d\'âge', () {
      final r = RagService.rechercherBm25('que peut-il manger', ageMois: 8);
      expect(r.map((p) => p.passage.ficheId), contains('nutri_6'));
      expect(r.map((p) => p.passage.ficheId), isNot(contains('nutri_72')));
    });

    test('question hors sujet : aucun passage', () {
      expect(RagService.rechercherBm25('quel est le prix du pétrole'), isEmpty);
    });

    test('au plus 2 passages par fiche, au plus 4 au total', () {
      final r = RagService.rechercherBm25('fièvre température thermomètre consulter');
      expect(r.length, lessThanOrEqualTo(RagService.nbPassages));
      final parFiche = <String, int>{};
      for (final p in r) {
        parFiche[p.passage.ficheId] = (parFiche[p.passage.ficheId] ?? 0) + 1;
      }
      expect(parFiche.values.every((n) => n <= 2), isTrue);
    });
  });

  group('Embeddings', () {
    test('similarité cosinus', () {
      expect(EmbeddingsService.cosinus([1, 0], [1, 0]), closeTo(1, 1e-9));
      expect(EmbeddingsService.cosinus([1, 0], [0, 1]), closeTo(0, 1e-9));
      expect(EmbeddingsService.cosinus([1, 2], [1]), 0);
    });

    test('sans clé : indisponibles, la recherche reste en BM25', () async {
      expect(EmbeddingsService.disponible, isFalse);
      final r = await RagService.rechercher('fièvre');
      expect(r.first.passage.ficheId, 'fievre');
    });
  });

  group('Dossier de l\'enfant', () {
    test('traitements avec observance, symptômes récents, allergies', () {
      final enfant = EnfantModel(
        id: '1',
        parentId: '1',
        nom: 'B',
        prenom: 'Adam',
        dateNaissance: DateTime(2025, 1, 10),
        sexe: 'M',
        allergies: 'allergie aux œufs',
      );
      final t = TraitementModel(
          id: '7', enfantId: '1', nom: 'Clamoxyl', posologie: '5 ml',
          dateDebut: DateTime(2026, 6, 1), heures: ['08:00', '20:00']);
      PriseMedicamentModel p(StatutPrise s, int h) => PriseMedicamentModel(
          id: '', traitementId: '7', enfantId: '1',
          datePrevue: DateTime(2026, 6, 2, h), statut: s,
          dateAction: DateTime(2026, 6, 2, h));
      final d = RagService.construireDossier(
        enfant: enfant,
        allergies: [AllergieAlimentaireModel(id: '1', enfantId: '1', allergene: 'arachide')],
        traitements: [t],
        prises: [p(StatutPrise.pris, 8), p(StatutPrise.pris, 20),
                 p(StatutPrise.pris, 9), p(StatutPrise.oublie, 21)],
        symptomes: [JournalSymptomeModel(
            id: '1', enfantId: '1', date: DateTime(2026, 6, 2),
            temperature: 38.6, symptomes: ['fievre', 'toux'])],
        maintenant: DateTime(2026, 6, 3),
      );
      expect(d.ageMois, 16);
      expect(d.allergies, containsAll(['Arachide', 'Œuf']));
      expect(d.traitements.single, 'Clamoxyl, 5 ml, 2×/jour, observance 75 % sur 7 jours');
      expect(d.symptomesRecents.single, contains('38.6 °C'));
      expect(d.faits.join('\n'), contains('Journal de santé'));
    });
  });

  group('Génération ancrée', () {
    final passages = RagService.rechercherBm25('fièvre', ageMois: 18);

    test('le prompt contient les sources numérotées, le dossier et les règles', () {
      final prompt = RagService.construirePrompt(
          question: 'Il a de la fièvre', dossier: _dossier, passages: passages);
      expect(prompt, contains('[1] Fièvre de l\'enfant'));
      expect(prompt, contains('Allergies : Œuf'));
      expect(prompt, contains('UNIQUEMENT à partir des SOURCES'));
      expect(prompt, isNot(contains('SAMU (190 en Tunisie')));
    });

    test('règle d\'urgence ajoutée si signes d\'alerte', () {
      final prompt = RagService.construirePrompt(
          question: 'il convulse', dossier: _dossier, passages: passages, urgent: true);
      expect(prompt, contains('SAMU (190 en Tunisie'));
    });

    test('seules les sources citées [n] sont gardées', () {
      final toutes = RagService.sourcesDe(passages);
      final gardees = RagService.sourcesCitees('Faites-le boire [2]. Consultez [2].', toutes);
      expect(gardees.map((s) => s.numero), [2]);
      expect(RagService.sourcesCitees('Sans citation.', toutes), toutes);
    });

    test('réponse extractive hors ligne : passages cités + rappel du dossier', () {
      final r = RagService.reponseExtractive(
        question: 'que peut-il manger ?',
        dossier: _dossier,
        passages: RagService.rechercherBm25('que peut-il manger', ageMois: 18),
      );
      expect(r, contains('[1]'));
      expect(r, contains('Pour Adam'));
      expect(r, contains('Œuf'));
    });

    test('sans passage : le dit clairement et oriente vers le pédiatre', () {
      final r = RagService.reponseExtractive(
          question: 'prix du pétrole', dossier: _dossier, passages: const []);
      expect(r, contains('pas trouvé d\'information fiable'));
      expect(r, contains('pédiatre'));
    });
  });

  group('Assistant (pipeline complet, hors ligne)', () {
    test('réponse sourcée', () async {
      final r = await AssistantIaService.repondre(
          question: 'mon fils a de la fièvre', dossier: _dossier);
      expect(r.parIA, isFalse);
      expect(r.urgent, isFalse);
      expect(r.sources, isNotEmpty);
      expect(r.sources.first.titre, contains('Fièvre'));
      expect(r.texte, contains('[1]'));
    });

    test('urgence : message SAMU en tête, sources quand même', () async {
      final r = await AssistantIaService.repondre(
          question: 'elle a du mal à respirer et devient bleue', dossier: _dossier);
      expect(r.urgent, isTrue);
      expect(r.texte, startsWith('⚠️'));
    });

    test('relance : la question précédente sert de contexte', () async {
      final r = await AssistantIaService.repondre(
        question: 'et quand faut-il s\'inquiéter ?',
        dossier: _dossier,
        historique: [
          MessageIA(id: '1', conversationId: '1', duParent: true,
              texte: 'il vomit beaucoup', date: DateTime(2026)),
        ],
      );
      expect(r.sources.map((s) => s.passageId).join(' '), contains('gastro'));
    });
  });

  group('Sources enregistrées avec le message', () {
    test('aller-retour SQLite', () {
      final m = MessageIA(
        id: '', conversationId: '3', duParent: false, texte: 'ok',
        sources: const [SourceCitee(numero: 1, passageId: 'fievre#2',
            titre: 'Fièvre — Quand consulter', source: 'Assurance Maladie')],
        date: DateTime(2026),
      );
      final relu = MessageIA.fromMap({...m.toDbMap(), 'id': 9});
      expect(relu.sources.single.passageId, 'fievre#2');
      expect(MessageIA.fromMap({'auteur': 'assistant', 'texte': 'x'}).sources, isEmpty);
    });
  });
}
