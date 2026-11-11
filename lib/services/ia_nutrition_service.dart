import '../data/nutrition_catalogue.dart';
import '../models/enfant_model.dart';
import '../models/journal_alimentaire_model.dart';
import 'croissance_service.dart';
import 'gemini_service.dart';
import 'journal_alimentaire_service.dart';
import 'nutrition_service.dart';

/// Données utilisées pour personnaliser les conseils.
class ProfilNutrition {
  final String prenom;
  final int ageMois;
  final double? poidsKg;
  final double? tailleCm;
  final DateTime? dateMesure;
  final Set<String> allergenes;
  final List<String> consignesPediatre;
  final List<JournalAlimentaireModel> repasRecents;

  const ProfilNutrition({
    required this.prenom,
    required this.ageMois,
    this.poidsKg,
    this.tailleCm,
    this.dateMesure,
    this.allergenes = const {},
    this.consignesPediatre = const [],
    this.repasRecents = const [],
  });
}

class ConseilsNutritionIA {
  final List<String> points;
  final bool parIA;
  const ConseilsNutritionIA({required this.points, required this.parIA});
}

/// Personnalisation nutritionnelle (partie IA du Module 9).
///
/// Lit (sans les modifier) : profil de l'enfant, dernière mesure de
/// croissance, allergies, consignes du pédiatre et repas des 7 derniers jours.
class IaNutritionService {
  IaNutritionService._();

  static Future<ProfilNutrition> profil(EnfantModel enfant) async {
    final allergies = await NutritionService.getAllergies(enfant.id);
    final consignes = await NutritionService.getConseils(enfant.id);
    final mesure = await CroissanceService.getDerniereMesure(enfant.id);
    final repas = await JournalAlimentaireService.getEntreesPeriode(
      enfant.id,
      DateTime.now().subtract(const Duration(days: 6)),
      DateTime.now(),
    );
    return ProfilNutrition(
      prenom: enfant.prenom,
      ageMois: NutritionService.ageEnMois(enfant.dateNaissance),
      poidsKg: mesure?.poids,
      tailleCm: mesure?.taille,
      dateMesure: mesure?.date,
      allergenes: NutritionService.allergenesEnfant(allergies,
          allergiesProfil: enfant.allergies),
      consignesPediatre: consignes.map((c) => c.texte).toList(),
      repasRecents: repas,
    );
  }

  static Future<ConseilsNutritionIA> conseils(EnfantModel enfant) async {
    final p = await profil(enfant);
    final ia = await GeminiService.generer(
      prompt: _prompt(p),
      temperature: 0.4,
      maxOutputTokens: 900,
    );
    if (ia != null) {
      final points = ia
          .split('\n')
          .map((l) => l.replaceFirst(RegExp(r'^\s*[-•*\d.)]+\s*'), '').trim())
          .where((l) => l.isNotEmpty)
          .toList();
      if (points.isNotEmpty) {
        return ConseilsNutritionIA(points: points, parIA: true);
      }
    }
    return ConseilsNutritionIA(points: conseilsLocaux(p), parIA: false);
  }

  static String _prompt(ProfilNutrition p) {
    final aliments = p.repasRecents
        .map((r) => [r.repas, r.aliments].whereType<String>().join(' : '))
        .where((s) => s.isNotEmpty)
        .take(25)
        .join(' | ');
    return '''
Tu es le module nutrition de l'application pédiatrique PediCare.
Donne 5 à 7 conseils alimentaires concrets et personnalisés, en français simple,
un par ligne commençant par « - ».

Enfant : ${p.prenom}, ${p.ageMois} mois.
${p.poidsKg == null ? 'Poids : non mesuré.' : 'Dernière mesure : ${p.poidsKg} kg, ${p.tailleCm} cm.'}
Allergies : ${p.allergenes.isEmpty ? 'aucune connue' : p.allergenes.map(libelleAllergene).join(', ')}.
Consignes du pédiatre (prioritaires) : ${p.consignesPediatre.isEmpty ? 'aucune' : p.consignesPediatre.join(' ; ')}.
Repas des 7 derniers jours : ${aliments.isEmpty ? 'non renseignés' : aliments}.

Règles strictes :
- ne propose JAMAIS un aliment contenant un allergène de l'enfant ;
- respecte les aliments interdits à cet âge (miel avant 1 an, aliments ronds et durs entiers, etc.) ;
- ne contredis jamais les consignes du pédiatre ;
- pas de diagnostic, pas de régime restrictif, pas de complément alimentaire ;
- texte brut, sans markdown ni titre.
''';
  }

  static const _sucres = [
    'bonbon', 'gateau', 'soda', 'chocolat', 'biscuit', 'nutella', 'jus de fruit',
    'sucre', 'glace', 'viennoiserie', 'croissant', 'chips',
  ];
  static const _fruitsLegumes = [
    'carotte', 'courgette', 'epinard', 'haricot', 'tomate', 'legume', 'salade',
    'pomme', 'poire', 'banane', 'orange', 'fraise', 'fruit', 'compote', 'brocoli',
    'potiron', 'citrouille', 'petit pois', 'concombre', 'abricot', 'peche', 'kiwi',
  ];

  /// Conseils construits par règles (sans réseau).
  static List<String> conseilsLocaux(ProfilNutrition p) {
    final points = <String>[];

    if (p.consignesPediatre.isNotEmpty) {
      points.add('Suivez en priorité les consignes de votre pédiatre : '
          '${p.consignesPediatre.first}');
    }

    final tranche = trancheDeAge(p.ageMois);
    points.addAll(tranche.conseils.take(2));

    for (final id in p.allergenes) {
      final conseil = _conseilAllergie[id];
      if (conseil != null) points.add(conseil);
    }

    // Analyse des repas récents.
    if (p.ageMois >= ageDiversificationMinMois) {
      if (p.repasRecents.isEmpty) {
        points.add('Aucun repas noté cette semaine : le journal alimentaire '
            'permet des conseils plus précis.');
      } else {
        final texte = NutritionService.normaliser(p.repasRecents
            .map((r) => '${r.aliments ?? ''} ${r.notes ?? ''}')
            .join(' '));
        final nbSucres = _sucres.where(texte.contains).length;
        final aFruitsLegumes = _fruitsLegumes.any(texte.contains);
        if (!aFruitsLegumes) {
          points.add('Peu de fruits et légumes notés cette semaine : '
              'essayez d\'en proposer à chaque repas, sous une forme adaptée à l\'âge.');
        }
        if (nbSucres >= 3) {
          points.add('Plusieurs produits sucrés notés cette semaine : '
              'réservez-les aux occasions et privilégiez l\'eau comme boisson.');
        }
        final jours = p.repasRecents
            .map((r) => DateTime(r.date.year, r.date.month, r.date.day))
            .toSet()
            .length;
        if (jours < 4) {
          points.add('Le journal n\'est rempli que $jours jour(s) sur 7 : '
              'un suivi régulier aide à repérer les déséquilibres.');
        }
      }
    }

    if (p.dateMesure == null) {
      points.add('Aucune mesure de croissance : le poids et la taille aident '
          'le pédiatre à vérifier que l\'alimentation est adaptée.');
    } else if (DateTime.now().difference(p.dateMesure!).inDays > 90) {
      points.add('La dernière mesure de poids date de plus de 3 mois : '
          'pensez à en ajouter une dans le suivi de croissance.');
    }
    return points;
  }

  static const Map<String, String> _conseilAllergie = {
    'lait': 'Allergie au lait de vache : demandez au pédiatre quel lait ou '
        'produit de remplacement utiliser, et lisez les étiquettes (beurre, crème, fromage).',
    'oeuf': 'Allergie à l\'œuf : attention aux pâtisseries, crêpes, sauces '
        '(mayonnaise) et pâtes fraîches.',
    'arachide': 'Allergie à l\'arachide : vérifiez les étiquettes des biscuits, '
        'barres et sauces, y compris la mention « traces ».',
    'fruits_coque': 'Allergie aux fruits à coque : attention aux pâtes à tartiner, '
        'pâtisseries et biscuits.',
    'gluten': 'Éviction du gluten : riz, maïs, pomme de terre, quinoa et '
        'sarrasin sont des féculents adaptés.',
    'poisson': 'Allergie au poisson : la viande, l\'œuf (si toléré) et les '
        'légumineuses apportent des protéines ; l\'huile de colza apporte des oméga-3.',
    'crustaces': 'Allergie aux crustacés : attention aux plats préparés et '
        'aux soupes de la mer.',
    'soja': 'Allergie au soja : il est souvent présent dans les plats '
        'préparés (lécithine, protéines de soja).',
    'sesame': 'Allergie au sésame : attention au pain, aux biscuits, au '
        'houmous et à la halwa.',
    'kiwi': 'Allergie au kiwi : d\'autres fruits riches en vitamine C '
        '(orange, fraise si tolérée) peuvent le remplacer.',
  };
}
