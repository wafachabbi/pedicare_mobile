class VaccinModel {
  final String id;
  final String nom;
  final String maladie;
  final DateTime dateAdministre;
  final String medecin;
  final String lieu;
  final String lotNumero;
  final DateTime? prochaineDate;
  final String enfantId;
  final String notes;

  VaccinModel({
    required this.id,
    required this.nom,
    required this.maladie,
    required this.dateAdministre,
    required this.medecin,
    required this.lieu,
    this.lotNumero = '',
    this.prochaineDate,
    required this.enfantId,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'maladie': maladie,
      'dateAdministre': dateAdministre.toIso8601String(),
      'medecin': medecin,
      'lieu': lieu,
      'lotNumero': lotNumero,
      'prochaineDate': prochaineDate?.toIso8601String(),
      'enfantId': enfantId,
      'notes': notes,
    };
  }

  factory VaccinModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is String) return DateTime.parse(val);
      // Firestore Timestamp
      try { return (val as dynamic).toDate(); } catch (_) {}
      return DateTime.now();
    }

    DateTime? parseDateOpt(dynamic val) {
      if (val == null) return null;
      if (val is String) return DateTime.parse(val);
      try { return (val as dynamic).toDate(); } catch (_) {}
      return null;
    }

    return VaccinModel(
      id: map['id'] ?? '',
      nom: map['nom'] ?? '',
      maladie: map['maladie'] ?? '',
      dateAdministre: parseDate(map['dateAdministre']),
      medecin: map['medecin'] ?? '',
      lieu: map['lieu'] ?? '',
      lotNumero: map['lotNumero'] ?? '',
      prochaineDate: parseDateOpt(map['prochaineDate']),
      enfantId: map['enfantId'] ?? '',
      notes: map['notes'] ?? '',
    );
  }
}
