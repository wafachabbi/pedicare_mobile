class CroissanceModel {
  final String id;
  final String enfantId;
  final DateTime date;
  final double poids; // kg
  final double taille; // cm
  final double? perimeterCranien; // cm (optionnel)
  final String notes;

  CroissanceModel({
    required this.id,
    required this.enfantId,
    required this.date,
    required this.poids,
    required this.taille,
    this.perimeterCranien,
    this.notes = '',
  });

  double get imc => poids / ((taille / 100) * (taille / 100));

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enfantId': enfantId,
      'date': date.toIso8601String(),
      'poids': poids,
      'taille': taille,
      'perimeterCranien': perimeterCranien,
      'notes': notes,
    };
  }

  factory CroissanceModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is String) return DateTime.parse(val);
      try { return (val as dynamic).toDate(); } catch (_) {}
      return DateTime.now();
    }

    return CroissanceModel(
      id: map['id'] ?? '',
      enfantId: map['enfantId'] ?? '',
      date: parseDate(map['date']),
      poids: (map['poids'] as num).toDouble(),
      taille: (map['taille'] as num).toDouble(),
      perimeterCranien: map['perimeterCranien'] != null
          ? (map['perimeterCranien'] as num).toDouble()
          : null,
      notes: map['notes'] ?? '',
    );
  }

  CroissanceModel copyWith({
    double? poids,
    double? taille,
    double? perimeterCranien,
    String? notes,
    DateTime? date,
  }) {
    return CroissanceModel(
      id: id,
      enfantId: enfantId,
      date: date ?? this.date,
      poids: poids ?? this.poids,
      taille: taille ?? this.taille,
      perimeterCranien: perimeterCranien ?? this.perimeterCranien,
      notes: notes ?? this.notes,
    );
  }
}
