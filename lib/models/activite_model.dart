class ActiviteModel {
  final int id;
  final String titre;
  final String categorie; // memoire | langage | motricite | logique
  final int ageMinMois;
  final int ageMaxMois;
  final String typeJeu;   // association | memory | activite
  final String description;
  final bool enFamille;

  ActiviteModel({
    required this.id,
    required this.titre,
    required this.categorie,
    required this.ageMinMois,
    required this.ageMaxMois,
    required this.typeJeu,
    this.description = '',
    this.enFamille = false,
  });

  /// true si c'est un jeu jouable dans l'app (pas une activité à faire hors écran)
  bool get estJeu => typeJeu != 'activite';

  String get categorieLabel {
    switch (categorie) {
      case 'memoire':   return 'Mémoire';
      case 'langage':   return 'Langage';
      case 'motricite': return 'Motricité';
      case 'logique':   return 'Logique';
      default:          return categorie;
    }
  }

  String get emoji {
    switch (categorie) {
      case 'memoire':   return '🧠';
      case 'langage':   return '🗣️';
      case 'motricite': return '✋';
      case 'logique':   return '🧩';
      default:          return '🎲';
    }
  }

  factory ActiviteModel.fromMap(Map<String, dynamic> m) => ActiviteModel(
    id: m['id'] as int,
    titre: m['titre'] ?? '',
    categorie: m['categorie'] ?? '',
    ageMinMois: m['age_min_mois'] as int,
    ageMaxMois: m['age_max_mois'] as int,
    typeJeu: m['type_jeu'] ?? 'activite',
    description: m['description'] ?? '',
    enFamille: (m['en_famille'] ?? 0) == 1,
  );
}