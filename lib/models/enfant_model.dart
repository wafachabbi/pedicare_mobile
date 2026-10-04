class EnfantModel {
  final String id;
  final String parentId;
  final String nom;
  final String prenom;
  final DateTime dateNaissance;
  final String sexe; // 'M' ou 'F'
  final String? groupeSanguin;
  final String? allergies;

  EnfantModel({
    required this.id,
    required this.parentId,
    required this.nom,
    required this.prenom,
    required this.dateNaissance,
    required this.sexe,
    this.groupeSanguin,
    this.allergies,
  });

  String get nomComplet => '$prenom $nom';

  int get age {
    final now = DateTime.now();
    int age = now.year - dateNaissance.year;
    if (now.month < dateNaissance.month ||
        (now.month == dateNaissance.month && now.day < dateNaissance.day)) {
      age--;
    }
    return age;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'parentId': parentId,
        'nom': nom,
        'prenom': prenom,
        'dateNaissance': dateNaissance.toIso8601String().split('T')[0],
        'sexe': sexe,
        'groupeSanguin': groupeSanguin,
        'allergies': allergies,
      };

  factory EnfantModel.fromMap(Map<String, dynamic> map) => EnfantModel(
        id: map['id'].toString(),
        parentId: map['parent_id']?.toString() ?? map['parentId']?.toString() ?? '',
        nom: map['nom'] ?? '',
        prenom: map['prenom'] ?? '',
        dateNaissance: DateTime.parse(map['date_naissance'] ?? map['dateNaissance'] ?? '2000-01-01'),
        sexe: map['sexe'] ?? 'M',
        groupeSanguin: map['groupe_sanguin'] ?? map['groupeSanguin'],
        allergies: map['allergies'],
      );
}
