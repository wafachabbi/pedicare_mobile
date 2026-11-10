import 'package:flutter_test/flutter_test.dart';
import 'package:projet_mobile/models/journal_alimentaire_model.dart';
import 'package:projet_mobile/models/nutrition_models.dart';
import 'package:projet_mobile/models/traitement_model.dart';
import 'package:projet_mobile/services/assistant_ia_service.dart';
import 'package:projet_mobile/services/ia_nutrition_service.dart';
import 'package:projet_mobile/services/ia_pharma_service.dart';
import 'package:projet_mobile/services/nutrition_service.dart';
import 'package:projet_mobile/services/open_food_facts_service.dart';

TraitementModel _t(String id, String nom) => TraitementModel(
    id: id, enfantId: '1', nom: nom, dateDebut: DateTime(2026, 1, 1));

void main() {
  // ══ PediPharma : base de médicaments et interactions ══════════════════════

  group('Identification des médicaments', () {
    test('nom commercial, molécule, casse et accents', () {
      expect(IaPharmaService.identifier('DOLIPRANE 2,4 % sirop')?.id, 'paracetamol');
      expect(IaPharmaService.identifier('ibuprofene 20 mg/ml')?.id, 'ibuprofene');
      expect(IaPharmaService.identifier('Célestène gouttes')?.id, 'prednisolone');
    });

    test('le nom le plus précis l\'emporte (Augmentin ≠ amoxicilline seule)', () {
      expect(IaPharmaService.identifier('Augmentin 100 mg')?.id, 'amox_clav');
      expect(
          IaPharmaService.identifier('amoxicilline acide clavulanique')?.id,
          'amox_clav');
      expect(IaPharmaService.identifier('Clamoxyl 250')?.id, 'amoxicilline');
    });

    test('médicament inconnu', () {
      expect(IaPharmaService.identifier('Produit XYZ'), isNull);
    });
  });

  group('Interactions', () {
    test('deux produits au paracétamol = doublon dangereux', () {
      final a = IaPharmaService.interactions('Efferalgan', [_t('1', 'Doliprane')]);
      expect(a.single.danger, isTrue);
      expect(a.single.titre, contains('Doublon'));
    });

    test('deux anti-inflammatoires', () {
      final a = IaPharmaService.interactions('Advil', [_t('1', 'Aspégic')]);
      expect(a.single.titre, contains('anti-inflammatoires'));
    });

    test('pansement digestif : espacer les prises', () {
      final a = IaPharmaService.interactions('Smecta', [_t('1', 'Clamoxyl')]);
      expect(a.single.danger, isFalse);
      expect(a.single.message, contains('Clamoxyl'));
    });

    test('aucune interaction connue', () {
      expect(IaPharmaService.interactions('Ventoline', [_t('1', 'Doliprane')]),
          isEmpty);
    });
  });

  group('Explication locale', () {
    test('contient l\'usage et aucune dose chiffrée inventée', () {
      final t = _t('1', 'Doliprane');
      final txt =
          IaPharmaService.explicationLocale(t, IaPharmaService.identifier(t.nom));
      expect(txt, contains('fièvre'));
      expect(txt, contains('pharmacien'));
      expect(RegExp(r'\d+\s*mg').hasMatch(txt), isFalse);
    });
  });

  // ══ OCR : analyse du texte lu par Tesseract ═══════════════════════════════

  group('Analyse d\'ordonnance', () {
    const texteOcr = '''
Dr. Sami Ben Salah
Pédiatre
Enfant : Adam

1) Clamoxyl 250 mg/5 ml suspension
5 ml 3 fois par jour pendant 8 jours
2) Doliprane sirop
1 dose poids toutes les 6 h si fièvre
''';

    test('médecin, médicaments, posologie, fréquence et durée', () {
      final r = IaPharmaService.analyserLocalement(texteOcr);
      expect(r.medecin, 'Dr. Sami Ben Salah');
      expect(r.lignes.length, 2);

      final a = r.lignes[0];
      expect(a.reference?.id, 'amoxicilline');
      expect(a.nom, startsWith('Clamoxyl'));
      expect(a.posologie, '250 mg');
      expect(a.prisesParJour, 3);
      expect(a.dureeJours, 8);

      final b = r.lignes[1];
      expect(b.reference?.id, 'paracetamol');
      expect(b.prisesParJour, 4);
    });

    test('fréquences écrites autrement', () {
      expect(IaPharmaService.extrairePrisesParJour('2x/j'), 2);
      expect(IaPharmaService.extrairePrisesParJour('matin et soir'), 2);
      expect(IaPharmaService.extrairePrisesParJour('matin, midi et soir'), 3);
      expect(IaPharmaService.extrairePrisesParJour('si besoin'), 0);
    });

    test('réponse JSON de Gemini (avec bloc ```json)', () {
      final r = IaPharmaService.parserReponseIA('''```json
{"medecin": "Dr. Ali", "medicaments": [
  {"nom": "Augmentin", "posologie": "5 ml", "prises_par_jour": 2, "duree_jours": 7},
  {"nom": "", "posologie": null}
]}
```''');
      expect(r, isNotNull);
      expect(r!.medecin, 'Dr. Ali');
      expect(r.lignes.single.reference?.id, 'amox_clav');
      expect(r.lignes.single.prisesParJour, 2);
      expect(r.lignes.single.dureeJours, 7);
    });

    test('réponse IA illisible : null (repli sur l\'analyse locale)', () {
      expect(IaPharmaService.parserReponseIA('désolé'), isNull);
    });
  });

  // ══ Assistant IA ══════════════════════════════════════════════════════════

  group('Assistant : signes d\'alerte', () {
    test('détectés quelle que soit la formulation', () {
      expect(AssistantIaService.estUrgent('Il a fait une CONVULSION'), isTrue);
      expect(AssistantIaService.estUrgent('elle a du mal à respirer'), isTrue);
      expect(AssistantIaService.estUrgent('il a avalé des médicaments'), isTrue);
    });

    test('fièvre avant 3 mois = urgence, pas à 2 ans', () {
      expect(AssistantIaService.estUrgent('il a de la fièvre', ageMois: 2), isTrue);
      expect(AssistantIaService.estUrgent('il a de la fièvre', ageMois: 24), isFalse);
    });
  });

  group('Assistant : conversations', () {
    test('titre de conversation tronqué', () {
      final t = AssistantIaService.titreDepuis('a' * 80);
      expect(t.length, 43);
      expect(t, endsWith('…'));
    });
  });

  // ══ Open Food Facts ═══════════════════════════════════════════════════════

  group('Open Food Facts', () {
    test('analyse de la réponse et correspondance des allergènes', () {
      final r = OpenFoodFactsService.parserRecherche({
        'products': [
          {
            'code': '3017620422003',
            'product_name': 'Nutella',
            'brands': 'Nutella, Ferrero',
            'allergens_tags': ['en:milk', 'en:nuts', 'en:soybeans'],
            'nutriscore_grade': 'E',
          },
          {'code': '1', 'product_name': ''}, // sans nom : ignoré
        ],
      });
      expect(r.length, 1);
      expect(r.single.allergenes, ['lait', 'fruits_coque', 'soja']);
      expect(r.single.nutriscore, 'e');
      expect(r.single.libelleJournal,
          'Nutella (Nutella) — contient : lait, fruits à coque, soja');
    });

    test('le libellé ajouté déclenche l\'alerte allergie, pas la règle « lait de vache »', () {
      final yaourt = OpenFoodFactsService.parserProduit({
        'product_name': 'Yaourt fraise',
        'allergens_tags': ['en:milk'],
      })!;
      final alertes = NutritionService.verifierRepas(
        aliments: yaourt.libelleJournal,
        ageMois: 8,
        allergenesConnus: {'lait'},
      );
      expect(alertes.single.titre, contains('Allergie'));
    });
  });

  // ══ Personnalisation nutritionnelle ═══════════════════════════════════════

  group('Conseils nutritionnels personnalisés (local)', () {
    JournalAlimentaireModel repas(int jour, String aliments) =>
        JournalAlimentaireModel(
            id: '', enfantId: '1', date: DateTime(2026, 6, jour), aliments: aliments);

    test('consignes du pédiatre en premier, allergies prises en compte', () {
      final c = IaNutritionService.conseilsLocaux(ProfilNutrition(
        prenom: 'Lina',
        ageMois: 30,
        allergenes: {'gluten'},
        consignesPediatre: ['Pas de produits laitiers pendant 15 jours'],
        repasRecents: [repas(1, 'riz, carotte')],
        dateMesure: DateTime.now(),
      ));
      expect(c.first, contains('Pas de produits laitiers'));
      expect(c.any((x) => x.contains('gluten')), isTrue);
    });

    test('repère le manque de fruits et légumes et l\'excès de sucre', () {
      final c = IaNutritionService.conseilsLocaux(ProfilNutrition(
        prenom: 'Lina',
        ageMois: 48,
        repasRecents: [
          repas(1, 'pâtes, chocolat'),
          repas(2, 'biscuit, soda'),
          repas(3, 'gâteau'),
        ],
        dateMesure: DateTime.now(),
      ));
      expect(c.any((x) => x.contains('fruits et légumes')), isTrue);
      expect(c.any((x) => x.contains('sucrés')), isTrue);
      expect(c.any((x) => x.contains('3 jour(s) sur 7')), isTrue);
    });

    test('rappelle de mesurer l\'enfant si aucune mesure', () {
      final c = IaNutritionService.conseilsLocaux(
          const ProfilNutrition(prenom: 'Lina', ageMois: 10));
      expect(c.any((x) => x.contains('croissance')), isTrue);
    });
  });

  test('les modèles de nutrition restent compatibles', () {
    expect(SeveriteAllergie.values.length, 3);
  });
}
