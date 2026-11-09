/// Qui utilise l'écran : le parent de l'enfant ou son pédiatre.
///
/// Répartition des rôles (Modules 5 et 9) :
///   - pédiatre : prescrit les traitements, enregistre les allergies, rédige
///     les consignes alimentaires et tient le journal alimentaire ;
///   - parent   : confirme les prises de médicaments, suit l'allaitement et
///     consulte le reste en lecture seule.
class Acteur {
  final bool estPediatre;

  /// users.id de la personne connectée (vide pour le parent si inconnu).
  final String id;
  final String nom;

  const Acteur.parent({this.id = '', this.nom = ''}) : estPediatre = false;

  const Acteur.pediatre({required this.id, required this.nom})
      : estPediatre = true;

  /// Nom affiché comme prescripteur / auteur (ex. « Dr. Rahma »).
  String get signature {
    final n = nom.trim();
    if (!estPediatre) return n;
    if (n.isEmpty) return 'Pédiatre';
    return n.toLowerCase().startsWith('dr') ? n : 'Dr. $n';
  }
}
