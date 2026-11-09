/// Données statiques du Module 9 — Nutrition & Alimentation.
///
/// Repères généraux inspirés des recommandations de santé publique
/// (Santé publique France / mangerbouger.fr). Ils ne remplacent pas l'avis
/// du pédiatre : l'application l'indique à chaque écran qui les affiche.
library;

const String avertissementNutrition =
    'Repères généraux à titre informatif : ils ne remplacent pas l\'avis '
    'de votre pédiatre, notamment en cas d\'allergie ou de prématurité.';

// ── Allergènes ──────────────────────────────────────────────────────────────

class Allergene {
  final String id;
  final String label;
  final String emoji;

  /// Mots-clés (sans accents, en minuscules) détectés dans les aliments saisis.
  final List<String> motsCles;

  /// Expressions qui contiennent un mot-clé sans contenir l'allergène
  /// (ex. « lait maternel » pour le lait de vache).
  final List<String> exclusions;

  const Allergene(this.id, this.label, this.emoji, this.motsCles,
      [this.exclusions = const []]);
}

const List<Allergene> allergenesCatalogue = [
  Allergene('lait', 'Lait de vache', '🥛', [
    'lait', 'yaourt', 'yogourt', 'fromage', 'beurre', 'creme', 'laitage',
    'petit suisse', 'kiri', 'lben', 'raib',
  ], [
    'lait maternel', 'lait de soja', 'lait d amande', 'lait vegetal',
    'lait de coco', 'lait d avoine', 'lait de riz', 'beurre de cacahuete',
    'creme de marron',
  ]),
  Allergene('oeuf', 'Œuf', '🥚', ['oeuf', 'omelette', 'mayonnaise', 'meringue']),
  Allergene('arachide', 'Arachide', '🥜', ['arachide', 'cacahuete', 'beurre de cacahuete']),
  Allergene('fruits_coque', 'Fruits à coque', '🌰', [
    'fruits a coque', 'noix', 'noisette', 'amande', 'pistache', 'cajou', 'pecan', 'pignon',
    'nutella', 'praline',
  ]),
  Allergene('gluten', 'Gluten (blé…)', '🌾', [
    'gluten', 'ble', 'pain', 'pates', 'semoule', 'couscous', 'farine', 'biscuit',
    'gateau', 'orge', 'seigle', 'cereales', 'brioche',
  ]),
  Allergene('poisson', 'Poisson', '🐟', [
    'poisson', 'saumon', 'thon', 'sardine', 'cabillaud', 'merlu', 'colin', 'dorade', 'loup',
  ]),
  Allergene('crustaces', 'Crustacés', '🦐', ['crevette', 'crabe', 'homard', 'langouste', 'crustace']),
  Allergene('soja', 'Soja', '🫘', ['soja', 'tofu']),
  Allergene('sesame', 'Sésame', '⚪', ['sesame', 'tahini', 'halwa', 'houmous']),
  Allergene('kiwi', 'Kiwi', '🥝', ['kiwi']),
];

Allergene? allergeneParId(String id) {
  for (final a in allergenesCatalogue) {
    if (a.id == id) return a;
  }
  return null;
}

/// Libellé affichable d'un allergène (catalogue ou texte libre).
String libelleAllergene(String idOuTexte) =>
    allergeneParId(idOuTexte)?.label ?? idOuTexte;

// ── Aliments à éviter selon l'âge ───────────────────────────────────────────

class RegleAge {
  final String aliment;

  /// Âge (en mois) à partir duquel l'aliment n'est plus signalé.
  final int ageMinMois;
  final List<String> motsCles;
  final String raison;

  /// Danger (rouge) ou simple attention (orange).
  final bool danger;

  const RegleAge({
    required this.aliment,
    required this.ageMinMois,
    required this.motsCles,
    required this.raison,
    this.danger = false,
  });
}

const List<RegleAge> reglesAge = [
  RegleAge(
    aliment: 'Miel',
    ageMinMois: 12,
    motsCles: ['miel'],
    raison: 'Risque de botulisme infantile avant 1 an.',
    danger: true,
  ),
  RegleAge(
    aliment: 'Lait de vache en boisson',
    ageMinMois: 12,
    motsCles: ['lait de vache', 'lait demi', 'lait entier', 'lait ecreme'],
    raison: 'Ne remplace pas le lait maternel ou infantile avant 1 an.',
  ),
  RegleAge(
    aliment: 'Sel et sucre ajoutés',
    ageMinMois: 12,
    motsCles: ['sel', 'sucre', 'bonbon', 'chocolat', 'soda', 'jus de fruit'],
    raison: 'À éviter avant 1 an, puis à limiter.',
  ),
  RegleAge(
    aliment: 'Fruits à coque entiers, cacahuètes entières',
    ageMinMois: 48,
    motsCles: ['noix', 'noisette', 'amande', 'pistache', 'cacahuete', 'cajou'],
    raison: 'Risque d\'étouffement s\'ils sont entiers : les donner en poudre ou en purée.',
    danger: true,
  ),
  RegleAge(
    aliment: 'Raisins, tomates cerises, olives entiers',
    ageMinMois: 48,
    motsCles: ['raisin', 'tomate cerise', 'olive'],
    raison: 'Risque d\'étouffement : les couper en quatre.',
  ),
  RegleAge(
    aliment: 'Pop-corn, bonbons durs',
    ageMinMois: 48,
    motsCles: ['pop corn', 'popcorn', 'bonbon dur', 'sucette'],
    raison: 'Risque d\'étouffement.',
    danger: true,
  ),
  RegleAge(
    aliment: 'Fromages au lait cru',
    ageMinMois: 60,
    motsCles: ['lait cru'],
    raison: 'Risque de listériose et d\'infections avant 5 ans.',
    danger: true,
  ),
  RegleAge(
    aliment: 'Viande, poisson, œuf crus ou peu cuits',
    ageMinMois: 60,
    motsCles: ['cru', 'crue', 'saignant', 'tartare', 'sushi', 'carpaccio', 'oeuf mollet', 'oeuf a la coque'],
    raison: 'À bien cuire avant 5 ans (risque infectieux).',
    danger: true,
  ),
  RegleAge(
    aliment: 'Thé, café, boissons énergisantes',
    ageMinMois: 216,
    motsCles: ['cafe', 'the', 'the vert', 'the noir', 'energisant', 'red bull', 'cola'],
    raison: 'La caféine est déconseillée chez l\'enfant.',
  ),
];

/// Avant 4 mois, l'alimentation est exclusivement lactée.
const int ageDiversificationMinMois = 4;

// ── Recommandations par tranche d'âge ───────────────────────────────────────

class TrancheAge {
  final String titre;
  final String emoji;
  final int minMois;

  /// Borne haute exclue (null = sans limite).
  final int? maxMois;
  final List<String> conseils;

  const TrancheAge({
    required this.titre,
    required this.emoji,
    required this.minMois,
    required this.maxMois,
    required this.conseils,
  });

  bool contient(int ageMois) =>
      ageMois >= minMois && (maxMois == null || ageMois < maxMois!);
}

const List<TrancheAge> tranchesAge = [
  TrancheAge(
    titre: '0 – 4 mois',
    emoji: '🍼',
    minMois: 0,
    maxMois: 4,
    conseils: [
      'Lait maternel ou lait infantile 1er âge uniquement, à la demande.',
      'Aucun autre aliment ni boisson (pas d\'eau sucrée, pas de tisane).',
      'Le lait de vache ne convient pas au nourrisson.',
    ],
  ),
  TrancheAge(
    titre: '4 – 6 mois',
    emoji: '🥕',
    minMois: 4,
    maxMois: 6,
    conseils: [
      'Début possible de la diversification, entre 4 et 6 mois révolus.',
      'Purées lisses de légumes puis de fruits, un nouvel aliment à la fois.',
      'Les aliments allergènes (œuf, arachide en poudre…) peuvent être '
          'introduits dès le début, en petite quantité.',
      'Le lait reste l\'aliment principal.',
    ],
  ),
  TrancheAge(
    titre: '6 – 12 mois',
    emoji: '🥣',
    minMois: 6,
    maxMois: 12,
    conseils: [
      'Textures de plus en plus épaisses, puis petits morceaux fondants.',
      'Viande, poisson ou œuf bien cuits, en petite quantité, une fois par jour.',
      'Féculents (pâtes, riz, semoule) et matières grasses ajoutées (huile, beurre).',
      'Pas de sel, pas de sucre, pas de miel.',
      'Lait 2e âge : il reste indispensable.',
    ],
  ),
  TrancheAge(
    titre: '1 – 3 ans',
    emoji: '🍽️',
    minMois: 12,
    maxMois: 36,
    conseils: [
      '4 repas par jour : petit-déjeuner, déjeuner, goûter, dîner.',
      'Lait de croissance ou produits laitiers à chaque repas.',
      'Fruits et légumes à chaque repas, de saison.',
      'L\'eau est la seule boisson indispensable.',
      'Couper les aliments ronds et durs (raisin, tomate cerise).',
    ],
  ),
  TrancheAge(
    titre: '3 – 6 ans',
    emoji: '🍎',
    minMois: 36,
    maxMois: 72,
    conseils: [
      'Garder 4 repas réguliers, sans grignotage.',
      'Au moins 5 fruits et légumes par jour.',
      'Limiter produits sucrés, boissons sucrées et aliments gras.',
      'Varier les sources de protéines (légumineuses, poisson, œuf, viande).',
    ],
  ),
  TrancheAge(
    titre: '6 ans et plus',
    emoji: '🏃',
    minMois: 72,
    maxMois: null,
    conseils: [
      'Un petit-déjeuner complet avant l\'école.',
      'Féculents complets, fruits et légumes, produits laitiers chaque jour.',
      'Limiter sodas, fast-food et écrans pendant les repas.',
      'Bouger au moins 1 heure par jour.',
    ],
  ),
];

TrancheAge trancheDeAge(int ageMois) =>
    tranchesAge.firstWhere((t) => t.contient(ageMois),
        orElse: () => tranchesAge.last);

// ── Recettes ────────────────────────────────────────────────────────────────

class Recette {
  final String titre;
  final String emoji;
  final int ageMinMois;
  final int dureeMinutes;

  /// Identifiants d'allergènes du catalogue présents dans la recette.
  final List<String> allergenes;
  final List<String> ingredients;
  final List<String> etapes;

  const Recette({
    required this.titre,
    required this.emoji,
    required this.ageMinMois,
    required this.dureeMinutes,
    required this.allergenes,
    required this.ingredients,
    required this.etapes,
  });
}

const List<Recette> recettesCatalogue = [
  Recette(
    titre: 'Purée de carottes',
    emoji: '🥕',
    ageMinMois: 4,
    dureeMinutes: 25,
    allergenes: [],
    ingredients: ['2 carottes', 'Eau de cuisson'],
    etapes: [
      'Éplucher et couper les carottes en rondelles.',
      'Cuire 20 min à la vapeur.',
      'Mixer finement avec un peu d\'eau de cuisson. Sans sel.',
    ],
  ),
  Recette(
    titre: 'Compote pomme-poire',
    emoji: '🍐',
    ageMinMois: 4,
    dureeMinutes: 20,
    allergenes: [],
    ingredients: ['1 pomme', '1 poire', '2 c. à soupe d\'eau'],
    etapes: [
      'Éplucher et couper les fruits en dés.',
      'Cuire à feu doux 15 min avec l\'eau.',
      'Mixer. Sans sucre ajouté.',
    ],
  ),
  Recette(
    titre: 'Purée courgette et pomme de terre',
    emoji: '🥔',
    ageMinMois: 5,
    dureeMinutes: 25,
    allergenes: [],
    ingredients: ['1 courgette', '1 pomme de terre', '1 c. à café d\'huile d\'olive'],
    etapes: [
      'Éplucher et couper les légumes.',
      'Cuire 20 min à la vapeur.',
      'Mixer et ajouter l\'huile d\'olive.',
    ],
  ),
  Recette(
    titre: 'Purée de patate douce au poulet',
    emoji: '🍗',
    ageMinMois: 6,
    dureeMinutes: 30,
    allergenes: [],
    ingredients: ['1 patate douce', '10 g de blanc de poulet', '1 c. à café d\'huile de colza'],
    etapes: [
      'Cuire la patate douce en dés 20 min à la vapeur.',
      'Cuire le poulet à cœur (sans rosé).',
      'Mixer le tout avec l\'huile.',
    ],
  ),
  Recette(
    titre: 'Petite semoule aux légumes',
    emoji: '🍲',
    ageMinMois: 8,
    dureeMinutes: 25,
    allergenes: ['gluten'],
    ingredients: ['20 g de semoule fine', '1 carotte', '1/2 courgette', 'Huile d\'olive'],
    etapes: [
      'Cuire les légumes coupés en petits dés.',
      'Verser la semoule dans le bouillon de cuisson et laisser gonfler.',
      'Écraser à la fourchette, ajouter l\'huile.',
    ],
  ),
  Recette(
    titre: 'Poisson blanc et purée d\'épinards',
    emoji: '🐟',
    ageMinMois: 8,
    dureeMinutes: 25,
    allergenes: ['poisson'],
    ingredients: ['15 g de cabillaud sans arêtes', '1 pomme de terre', 'Épinards', 'Noisette de beurre'],
    etapes: [
      'Cuire le poisson à la vapeur 8 min, vérifier l\'absence d\'arêtes.',
      'Cuire pomme de terre et épinards puis écraser.',
      'Émietter le poisson, mélanger, ajouter le beurre.',
    ],
  ),
  Recette(
    titre: 'Omelette aux courgettes',
    emoji: '🍳',
    ageMinMois: 10,
    dureeMinutes: 15,
    allergenes: ['oeuf'],
    ingredients: ['1 œuf', '1/2 courgette râpée', 'Huile d\'olive'],
    etapes: [
      'Faire revenir la courgette râpée.',
      'Battre l\'œuf, verser, cuire jusqu\'à ce qu\'il soit bien pris.',
      'Couper en petits morceaux.',
    ],
  ),
  Recette(
    titre: 'Yaourt banane et flocons d\'avoine',
    emoji: '🍌',
    ageMinMois: 12,
    dureeMinutes: 5,
    allergenes: ['lait', 'gluten'],
    ingredients: ['1 yaourt nature', '1/2 banane', '1 c. à soupe de flocons d\'avoine'],
    etapes: [
      'Écraser la banane.',
      'Mélanger avec le yaourt et les flocons.',
    ],
  ),
  Recette(
    titre: 'Pâtes à la sauce tomate et lentilles',
    emoji: '🍝',
    ageMinMois: 18,
    dureeMinutes: 30,
    allergenes: ['gluten'],
    ingredients: ['Petites pâtes', 'Lentilles corail', 'Coulis de tomate', 'Huile d\'olive'],
    etapes: [
      'Cuire les lentilles corail 15 min.',
      'Cuire les pâtes.',
      'Mélanger avec le coulis chaud et l\'huile.',
    ],
  ),
  Recette(
    titre: 'Couscous de légumes doux',
    emoji: '🥘',
    ageMinMois: 24,
    dureeMinutes: 40,
    allergenes: ['gluten'],
    ingredients: ['Semoule', 'Carotte', 'Courgette', 'Pois chiches', 'Huile d\'olive', 'Peu de sel'],
    etapes: [
      'Cuire les légumes et les pois chiches dans un bouillon peu salé.',
      'Préparer la semoule avec le bouillon.',
      'Servir en coupant les légumes en morceaux adaptés.',
    ],
  ),
  Recette(
    titre: 'Pancakes à la banane (sans œuf ni lait)',
    emoji: '🥞',
    ageMinMois: 12,
    dureeMinutes: 20,
    allergenes: ['gluten'],
    ingredients: ['1 banane mûre', '60 g de farine', '80 ml de boisson végétale (avoine)', 'Huile'],
    etapes: [
      'Écraser la banane, ajouter farine et boisson végétale.',
      'Cuire de petites crêpes épaisses dans une poêle huilée.',
    ],
  ),
  Recette(
    titre: 'Salade de riz au thon',
    emoji: '🥗',
    ageMinMois: 36,
    dureeMinutes: 20,
    allergenes: ['poisson'],
    ingredients: ['Riz', 'Thon au naturel', 'Tomate', 'Maïs', 'Huile d\'olive'],
    etapes: [
      'Cuire le riz et le laisser refroidir.',
      'Ajouter thon émietté, tomate en dés et maïs.',
      'Assaisonner avec l\'huile.',
    ],
  ),
];
