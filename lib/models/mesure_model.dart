class MesureModel {
  final String id;
  final double poids; // kg
  final double taille; // cm
  final double? perimetre; // cm (périmètre crânien, optionnel)
  final DateTime date;
  final String enfantId;
  final String notes;

  MesureModel({
    required this.id,
    required this.poids,
    required this.taille,
    this.perimetre,
    required this.date,
    required this.enfantId,
    this.notes = '',
  });

  // IMC calculé automatiquement
  double get imc {
    final tailleM = taille / 100;
    return poids / (tailleM * tailleM);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'poids': poids,
      'taille': taille,
      'perimetre': perimetre,
      'date': date.toIso8601String(),
      'enfantId': enfantId,
      'notes': notes,
    };
  }

  factory MesureModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is String) return DateTime.parse(val);
      try { return (val as dynamic).toDate(); } catch (_) {}
      return DateTime.now();
    }

    return MesureModel(
      id: map['id'] ?? '',
      poids: (map['poids'] ?? 0).toDouble(),
      taille: (map['taille'] ?? 0).toDouble(),
      perimetre: map['perimetre'] != null
          ? (map['perimetre'] as num).toDouble()
          : null,
      date: parseDate(map['date']),
      enfantId: map['enfantId'] ?? '',
      notes: map['notes'] ?? '',
    );
  }
}
