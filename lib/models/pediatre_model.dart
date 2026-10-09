class PediatreModel {
  final String id;
  final String name;
  final String email;
  final String specialite;
  final String telephone;
  final String adresse;

  PediatreModel({
    required this.id,
    required this.name,
    required this.email,
    this.specialite = '',
    this.telephone = '',
    this.adresse = '',
  });

  factory PediatreModel.fromMap(Map<String, dynamic> m) => PediatreModel(
        id: m['id'].toString(),
        name: m['name'] ?? '',
        email: m['email'] ?? '',
        specialite: m['specialite'] ?? '',
        telephone: m['telephone'] ?? '',
        adresse: m['adresse'] ?? '',
      );
}
