import 'package:flutter_test/flutter_test.dart';
import 'package:projet_mobile/models/acteur.dart';
import 'package:projet_mobile/models/nutrition_models.dart';
import 'package:projet_mobile/models/prise_medicament_model.dart';
import 'package:projet_mobile/models/traitement_model.dart';
import 'package:projet_mobile/services/nutrition_service.dart';
import 'package:projet_mobile/services/traitement_service.dart';

void main() {
  group('Acteur (répartition des rôles)', () {
    test('signature du pédiatre préfixée par « Dr. » une seule fois', () {
      expect(const Acteur.pediatre(id: '2', nom: 'rahma').signature, 'Dr. rahma');
      expect(const Acteur.pediatre(id: '2', nom: 'Dr Ben Ali').signature,
          'Dr Ben Ali');
      expect(const Acteur.pediatre(id: '2', nom: '').signature, 'Pédiatre');
    });

    test('le parent est le rôle par défaut', () {
      expect(const Acteur.parent().estPediatre, isFalse);
    });
  });

  // ══ Module 5 — PediPharma ═════════════════════════════════════════════════

  group('TraitementModel', () {
    test('heures triées, normalisées, invalides ignorées, sans doublon', () {
      final t = TraitementModel(
        id: '1',
        enfantId: '1',
        nom: 'Amoxicilline',
        dateDebut: DateTime(2026, 1, 1),
        heures: ['20:00', '8:00', '25:00', 'abc', '08:00'],
      );
      expect(t.heures, ['08:00', '20:00']);
    });

    test('aller-retour SQLite : médecin, heures et rappels conservés', () {
      final t = TraitementModel(
        id: '3',
        enfantId: '7',
        nom: 'Doliprane',
        posologie: '5 ml',
        dateDebut: DateTime(2026, 3, 1),
        medecin: 'Dr Ben Ali',
        heures: ['08:00', '14:00', '20:00'],
        rappels: false,
      );
      final relu = TraitementModel.fromMap({...t.toDbMap(), 'id': 3});
      expect(relu.medecin, 'Dr Ben Ali');
      expect(relu.heures, ['08:00', '14:00', '20:00']);
      expect(relu.rappels, isFalse);
      expect(relu.enfantId, '7');
    });

    test('ancienne ligne sans colonnes v6 : rappels activés, aucune heure', () {
      final relu = TraitementModel.fromMap({
        'id': 1,
        'enfant_id': 1,
        'nom': 'Sirop',
        'date_debut': '2026-01-01T00:00:00.000',
      });
      expect(relu.rappels, isTrue);
      expect(relu.heures, isEmpty);
      expect(relu.medecin, '');
    });

    test('couvreLeJour inclut les dates de début et de fin', () {
      final t = TraitementModel(
        id: '1',
        enfantId: '1',
        nom: 'X',
        dateDebut: DateTime(2026, 5, 10, 15),
        dateFin: DateTime(2026, 5, 12),
      );
      expect(t.couvreLeJour(DateTime(2026, 5, 9, 23)), isFalse);
      expect(t.couvreLeJour(DateTime(2026, 5, 10, 8)), isTrue);
      expect(t.couvreLeJour(DateTime(2026, 5, 12, 22)), isTrue);
      expect(t.couvreLeJour(DateTime(2026, 5, 13)), isFalse);
    });
  });

  group('Doses du jour', () {
    final jour = DateTime(2026, 6, 1, 10);
    final t1 = TraitementModel(
      id: '1',
      enfantId: '1',
      nom: 'A',
      dateDebut: DateTime(2026, 5, 30),
      dateFin: DateTime(2026, 6, 5),
      heures: ['20:00', '08:00'],
    );
    final termine = TraitementModel(
      id: '2',
      enfantId: '1',
      nom: 'B',
      dateDebut: DateTime(2026, 5, 1),
      dateFin: DateTime(2026, 5, 20),
      heures: ['09:00'],
    );
    final siBesoin = TraitementModel(
      id: '3',
      enfantId: '1',
      nom: 'C',
      dateDebut: DateTime(2026, 5, 1),
    );

    test('ne garde que les traitements du jour, triés par heure', () {
      final doses =
          TraitementService.dosesDuJour([t1, termine, siBesoin], [], jour);
      expect(doses.map((d) => d.heure.hour), [8, 20]);
      expect(doses.every((d) => d.traitement.id == '1'), isTrue);
    });

    test('associe la prise enregistrée au bon créneau', () {
      final prise = PriseMedicamentModel(
        id: '9',
        traitementId: '1',
        enfantId: '1',
        datePrevue: DateTime(2026, 6, 1, 8),
        statut: StatutPrise.pris,
        dateAction: DateTime(2026, 6, 1, 8, 5),
      );
      final doses = TraitementService.dosesDuJour([t1], [prise], jour);
      expect(doses[0].prise?.statut, StatutPrise.pris);
      expect(doses[0].enAttente, isFalse);
      expect(doses[1].prise, isNull);
      expect(doses[1].enAttente, isTrue);
    });

    test('une dose reportée reste à faire ; retard après 30 min', () {
      final dose = DoseDuJour(
        traitement: t1,
        heure: DateTime(2026, 6, 1, 8),
        prise: PriseMedicamentModel(
          id: '1',
          traitementId: '1',
          enfantId: '1',
          datePrevue: DateTime(2026, 6, 1, 8),
          statut: StatutPrise.reporte,
          dateAction: DateTime(2026, 6, 1, 8),
        ),
      );
      expect(dose.enAttente, isTrue);
      expect(dose.enRetard(DateTime(2026, 6, 1, 8, 20)), isFalse);
      expect(dose.enRetard(DateTime(2026, 6, 1, 8, 31)), isTrue);
    });
  });

  group('Observance', () {
    PriseMedicamentModel p(StatutPrise s) => PriseMedicamentModel(
          id: '',
          traitementId: '1',
          enfantId: '1',
          datePrevue: DateTime(2026),
          statut: s,
          dateAction: DateTime(2026),
        );

    test('taux = pris / (pris + oubliés), reportés exclus', () {
      final s = ObservanceStats.depuis([
        p(StatutPrise.pris),
        p(StatutPrise.pris),
        p(StatutPrise.pris),
        p(StatutPrise.oublie),
        p(StatutPrise.reporte),
      ]);
      expect(s.taux, 0.75);
      expect(s.reportes, 1);
      expect(s.total, 5);
    });

    test('aucune prise tranchée : pas de taux', () {
      expect(ObservanceStats.depuis([p(StatutPrise.reporte)]).taux, isNull);
    });
  });

  // ══ Module 9 — Nutrition ══════════════════════════════════════════════════

  group('Âge en mois', () {
    test('mois révolus', () {
      final n = DateTime(2025, 3, 15);
      expect(NutritionService.ageEnMois(n, le: DateTime(2025, 9, 14)), 5);
      expect(NutritionService.ageEnMois(n, le: DateTime(2025, 9, 15)), 6);
      expect(NutritionService.ageEnMois(n, le: DateTime(2025, 1, 1)), 0);
    });
  });

  group('Alertes repas', () {
    test('miel signalé avant 1 an, plus après', () {
      final avant = NutritionService.verifierRepas(
          aliments: 'Yaourt au miel', ageMois: 8);
      expect(avant.any((a) => a.titre.contains('Miel')), isTrue);
      expect(avant.first.niveau, NiveauAlerteAliment.danger);

      final apres = NutritionService.verifierRepas(
          aliments: 'Yaourt au miel', ageMois: 18);
      expect(apres.any((a) => a.titre.contains('Miel')), isFalse);
    });

    test('allergie connue détectée, accents et majuscules ignorés', () {
      final a = NutritionService.verifierRepas(
        aliments: 'Omelette et purée',
        ageMois: 24,
        allergenesConnus: {'oeuf'},
      );
      expect(a.single.titre, contains('Allergie'));
      expect(a.single.niveau, NiveauAlerteAliment.danger);
    });

    test('« lait maternel » ne déclenche pas l\'allergie au lait de vache', () {
      final a = NutritionService.verifierRepas(
        aliments: 'Lait maternel',
        ageMois: 10,
        allergenesConnus: {'lait'},
        solide: false,
      );
      expect(a, isEmpty);
    });

    test('« sans sucre » n\'est pas compté comme du sucre', () {
      final a = NutritionService.verifierRepas(
          aliments: 'Compote sans sucre ajouté', ageMois: 8);
      expect(a, isEmpty);
    });

    test('mot-clé dans un autre mot ignoré (« persil » ≠ « sel »)', () {
      final a = NutritionService.verifierRepas(
          aliments: 'Purée de courgette au persil', ageMois: 8);
      expect(a, isEmpty);
    });

    test('repas solide avant 4 mois signalé ; biberon non', () {
      expect(
          NutritionService.verifierRepas(aliments: 'Purée de carotte', ageMois: 2)
              .any((a) => a.titre.contains('Diversification')),
          isTrue);
      expect(
          NutritionService.verifierRepas(
              aliments: 'Lait infantile', ageMois: 2, solide: false),
          isEmpty);
    });
  });

  group('Allergies de l\'enfant', () {
    test('catalogue + texte libre + champ profil', () {
      final ids = NutritionService.allergenesEnfant([
        AllergieAlimentaireModel(id: '1', enfantId: '1', allergene: 'arachide'),
        AllergieAlimentaireModel(id: '2', enfantId: '1', allergene: 'crevettes'),
      ], allergiesProfil: 'Allergique aux œufs');
      expect(ids, containsAll(['arachide', 'crustaces', 'oeuf']));
    });
  });

  group('Recettes', () {
    test('filtrées par âge et par allergie', () {
      final (bebe, _) = NutritionService.recettesAdaptees(
          ageMois: 5, allergenesConnus: {});
      expect(bebe.every((r) => r.ageMinMois <= 5), isTrue);
      expect(bebe, isNotEmpty);

      final (tout, masqueesSans) = NutritionService.recettesAdaptees(
          ageMois: 60, allergenesConnus: {});
      final (sansGluten, masquees) = NutritionService.recettesAdaptees(
          ageMois: 60, allergenesConnus: {'gluten'});
      expect(masqueesSans, 0);
      expect(masquees, greaterThan(0));
      expect(sansGluten.length, tout.length - masquees);
      expect(sansGluten.any((r) => r.allergenes.contains('gluten')), isFalse);
    });

    test('aucune recette avant 4 mois', () {
      final (r, _) =
          NutritionService.recettesAdaptees(ageMois: 2, allergenesConnus: {});
      expect(r, isEmpty);
    });
  });

  group('Allaitement', () {
    test('statistiques du jour', () {
      AllaitementModel e(int h, {int? duree, int? ml}) => AllaitementModel(
            id: '',
            enfantId: '1',
            date: DateTime(2026, 6, 1, h),
            type: ml != null ? TypeAllaitement.biberon : TypeAllaitement.seinGauche,
            dureeMinutes: duree,
            quantiteMl: ml,
          );
      final s = AllaitementStats.depuis([e(9, ml: 120), e(3, duree: 15), e(6, duree: 10)]);
      expect(s.nombre, 3);
      expect(s.dureeTotaleMinutes, 25);
      expect(s.quantiteTotaleMl, 120);
      expect(s.intervalleMoyen, const Duration(hours: 3));
      expect(s.derniere, DateTime(2026, 6, 1, 9));
    });
  });
}
