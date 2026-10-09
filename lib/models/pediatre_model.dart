class PediatreModel {
  final String id;
  final String name;
  final String email;

  PediatreModel({
    required this.id,
    required this.name,
    required this.email,
  });

  factory PediatreModel.fromMap(Map<String, dynamic> m) => PediatreModel(
        id: m['id'].toString(),
        name: m['name'] ?? '',
        email: m['email'] ?? '',
      );
}
