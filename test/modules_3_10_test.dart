import 'package:flutter_test/flutter_test.dart';

import 'package:projet_mobile/models/analyse_symptomes_model.dart';
import 'package:projet_mobile/models/consultation_model.dart';
import 'package:projet_mobile/models/enfant_model.dart';
import 'package:projet_mobile/models/journal_symptome_model.dart';
import 'package:projet_mobile/models/observation_consultation_model.dart';
import 'package:projet_mobile/models/traitement_model.dart';
import 'package:projet_mobile/services/gemini_service.dart';
import 'package:projet_mobile/services/ia_consultation_service.dart';

EnfantModel _enfant({DateTime? naissance}) => EnfantModel(
      id: '1',
      parentId: '1',
      nom: 'Balloumi',
      prenom: 'Rahma',
      dateNaissance: naissance ?? DateTime(2023, 1, 1),
      sexe: 'F',
    );

JournalSymptomeModel _entree({
  required DateTime date,
  double? temperature,
  List<String> symptomes = const [],
  EtatComportement comportement = EtatComportement.normal,
  NiveauToux toux = NiveauToux.aucune,
}) =>
    JournalSymptomeModel(
      id: '${date.millisecondsSinceEpoch}',
      enfantId: '1',
      date: date,
      temperature: temperature,
      symptomes: symptomes,
      comportement: comportement,
      toux: toux,
    );

void main() {
  // Les tests doivent rester hors ligne et déterministes.
  setUpAll(GeminiService.desactiverPourTests);

  group('IAConsultationService — analyse contextuelle', () {
    test('journal vide : message de saisie, aucune alerte', () async {
      final analyse = await IAConsultationService.analyserContexte(
        enfant: _enfant(),
        journal: [],
      );

      expect(analyse.suggestions, isNotEmpty);
      expect(analyse.aUrgence, isFalse);
      expect(analyse.iaDisponible, isFalse);
    });

    test('convulsions : niveau urgent', () async {
      final analyse = await IAConsultationService.analyserContexte(
        enfant: _enfant(),
        journal: [
          _entree(date: DateTime.now(), symptomes: const ['convulsion']),
        ],
      );

      expect(analyse.aUrgence, isTrue);
      expect(
        analyse.suggestions
            .where((s) => s.niveau == NiveauSuggestion.urgent),
        isNotEmpty,
      );
    });

    test('température >= 39,5 °C : niveau urgent', () async {
      final analyse = await IAConsultationService.analyserContexte(
        enfant: _enfant(),
        journal: [
          _entree(date: DateTime.now(), temperature: 39.8),
        ],
      );

      expect(analyse.aUrgence, isTrue);
    });

    test('fièvre depuis 3 jours : suggère de consulter', () async {
      final now = DateTime.now();
      final analyse = await IAConsultationService.analyserContexte(
        enfant: _enfant(),
        journal: [
          _entree(date: now, temperature: 38.2),
          _entree(
              date: now.subtract(const Duration(days: 1)), temperature: 38.4),
          _entree(
              date: now.subtract(const Duration(days: 2)), temperature: 38.1),
        ],
      );

      expect(analyse.aAttention, isTrue);
      expect(
        analyse.suggestions.any((s) => s.texte.contains('3 jours')),
        isTrue,
      );
    });

    test("nourrisson de moins de 3 mois avec fièvre : avis rapide", () async {
      final bebe = _enfant(
        naissance: DateTime.now().subtract(const Duration(days: 40)),
      );
      final analyse = await IAConsultationService.analyserContexte(
        enfant: bebe,
        journal: [_entree(date: DateTime.now(), temperature: 38.1)],
      );

      expect(analyse.aUrgence, isTrue);
    });
  });

  group('GeminiService', () {
    test('la liste de modèles de repli est ordonnée et non vide', () {
      expect(GeminiService.modeles, isNotEmpty);
      expect(GeminiService.modeles.first, 'gemini-3.5-flash-lite');
      expect(GeminiService.modeles.toSet().length, GeminiService.modeles.length);
    });

    test('aucun modèle retiré (gemini-1.5) dans la chaîne de repli', () {
      expect(
        GeminiService.modeles.any((m) => m.contains('1.5')),
        isFalse,
        reason: 'gemini-1.5-flash a été supprimé par Google',
      );
    });

    test('une clé est configurée ou l\'IA est désactivée', () {
      // En test, desactiverPourTests() est appelé : configuree doit être faux.
      expect(GeminiService.configuree, isFalse);
    });
  });

  group('ConsultationModel', () {
    test('lit une ligne SQLite (snake_case)', () {
      final c = ConsultationModel.fromMap({
        'id': 4,
        'enfant_id': 2,
        'titre': 'Résumé',
        'resume': 'Texte du résumé',
        'points_cles': '- Point A\n- Point B',
        'suggestions': '• Boire\n• Surveiller',
        'periode_debut': '2026-01-01T00:00:00.000',
        'periode_fin': '2026-01-07T00:00:00.000',
        'nb_entrees': 5,
        'generee_ia': 1,
        'created_at': '2026-01-07T10:00:00.000',
      });

      expect(c.id, '4');
      expect(c.enfantId, '2');
      expect(c.nbEntrees, 5);
      expect(c.genereeIA, isTrue);
      expect(c.pointsClesListe, ['Point A', 'Point B']);
      expect(c.suggestionsListe, ['Boire', 'Surveiller']);
    });
  });

  group('TraitementModel', () {
    test('un traitement sans date de fin est actif', () {
      final t = TraitementModel(
        id: '1',
        enfantId: '1',
        nom: 'Paracétamol',
        dateDebut: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(t.actif, isTrue);
    });

    test('un traitement terminé est inactif', () {
      final t = TraitementModel(
        id: '1',
        enfantId: '1',
        nom: 'Paracétamol',
        dateDebut: DateTime.now().subtract(const Duration(days: 5)),
        dateFin: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(t.actif, isFalse);
    });
  });

  group('EnfantModel — partage du journal', () {
    test('lit le partage et le nom du parent depuis SQLite', () {
      final e = EnfantModel.fromMap({
        'id': 7,
        'parent_id': 3,
        'nom': 'Balloumi',
        'prenom': 'Rahma',
        'date_naissance': '2022-05-01',
        'sexe': 'F',
        'partage_journal': 1,
        'parent_nom': 'Rahma Balloumi',
      });

      expect(e.partageJournal, isTrue);
      expect(e.parentNom, 'Rahma Balloumi');
    });

    test('le partage est désactivé par défaut', () {
      final e = EnfantModel.fromMap({
        'id': 8,
        'parent_id': 3,
        'nom': 'Test',
        'prenom': 'Enfant',
        'date_naissance': '2022-05-01',
        'sexe': 'M',
      });

      expect(e.partageJournal, isFalse);
    });
  });
  group('Consultation saisie par le pédiatre → résumé IA du parent', () {
    final obs = ObservationConsultationModel(
      id: '7',
      enfantId: '1',
      pediatreNom: 'Rahma',
      dateConsultation: DateTime(2026, 11, 5),
      motif: 'Fièvre et toux',
      poids: 12.4,
      temperature: 38.6,
      observations: 'Gorge rouge, auscultation normale',
      diagnostic: 'Rhinopharyngite',
      traitement: 'Paracétamol 3 fois par jour',
      recommandations: 'Bien hydrater\nSurveiller la température',
    );

    test('le résumé reprend les données du pédiatre et ses recommandations',
        () async {
      final r = await IAConsultationService.genererResumeDepuisObservation(
        enfant: _enfant(),
        observation: obs,
        journal: [
          _entree(date: DateTime(2026, 11, 3), temperature: 38.9),
          _entree(date: DateTime(2026, 10, 1), temperature: 39.5),
        ],
      );
      expect(r.genereeIA, isFalse); // Gemini désactivé : moteur local
      expect(r.titre, contains('Fièvre et toux'));
      expect(r.resume, contains('Dr. Rahma'));
      expect(r.resume, contains('Rhinopharyngite'));
      expect(r.pointsCles, contains('Diagnostic du pédiatre : Rhinopharyngite'));
      expect(r.suggestions, containsAll(['Bien hydrater', 'Surveiller la température']));
      expect(r.nbEntrees, 1); // seule l'entrée des 7 jours précédents compte
    });

    test('ConsultationModel conserve le lien vers la consultation', () {
      final c = ConsultationModel.fromMap({
        'id': '3', 'enfant_id': '1', 'titre': 't', 'resume': 'r',
        'observation_id': 7,
      });
      expect(c.observationId, '7');
      expect(c.toDbMap()['observation_id'], 7);
    });
  });
}
