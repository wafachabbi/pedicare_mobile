class EnfantModel {
  final String id;
  final String parentId;
  final String nom;
  final String prenom;
  final DateTime dateNaissance;
  final String sexe; // 'M' ou 'F'
  final String? groupeSanguin;
  final String? allergies;

  /// Nom du parent (renseigné uniquement côté pédiatre via une jointure).
  final String? parentNom;

  /// Le journal des symptômes est-il partagé avec le pédiatre ?
  final bool partageJournal;

  /// ID du pédiatre destinataire (null si aucun pédiatre n'est désigné).
  final String? pediatreId;

  EnfantModel({
    required this.id,
    required this.parentId,
    required this.nom,
    required this.prenom,
    required this.dateNaissance,
    required this.sexe,
    this.groupeSanguin,
    this.allergies,
    this.parentNom,
    this.partageJournal = false,
    this.pediatreId,
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
        'parentNom': parentNom,
        'partageJournal': partageJournal,
        'pediatreId': pediatreId,
      };

  factory EnfantModel.fromMap(Map<String, dynamic> map) => EnfantModel(
        id: map['id']?.toString() ?? '',
        parentId: map['parent_id']?.toString() ?? map['parentId']?.toString() ?? '',
        nom: map['nom'] ?? '',
        prenom: map['prenom'] ?? '',
        dateNaissance: DateTime.parse(map['date_naissance'] ?? map['dateNaissance'] ?? '2000-01-01'),
        sexe: map['sexe'] ?? 'M',
        groupeSanguin: map['groupe_sanguin'] ?? map['groupeSanguin'],
        allergies: map['allergies'],
        parentNom: map['parent_nom'] ?? map['parentNom'],
        partageJournal: _bool(map['partage_journal'] ?? map['partageJournal']),
        pediatreId: map['pediatreId'] ?? map['pediatre_id'],
      );

  static bool _bool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final s = value?.toString().toLowerCase();
    return s == '1' || s == 'true';
  }

  EnfantModel copyWith({
    bool? partageJournal,
    String? parentNom,
    String? pediatreId,
  }) => EnfantModel(
        id: id,
        parentId: parentId,
        nom: nom,
        prenom: prenom,
        dateNaissance: dateNaissance,
        sexe: sexe,
        groupeSanguin: groupeSanguin,
        allergies: allergies,
        parentNom: parentNom ?? this.parentNom,
        partageJournal: partageJournal ?? this.partageJournal,
        pediatreId: pediatreId ?? this.pediatreId,
      );
}
