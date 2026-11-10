class JournalAlimentaireModel {
  final String id;
  final String enfantId;
  final DateTime date;
  final String? repas;
  final String? quantite;
  final String? heure;
  final String? notes;
  final int? ageMois;

  /// Aliments consommés (texte libre, ex. « purée carotte, yaourt »).
  final String? aliments;

  JournalAlimentaireModel({
    required this.id,
    required this.enfantId,
    required this.date,
    this.repas,
    this.quantite,
    this.heure,
    this.notes,
    this.ageMois,
    this.aliments,
  });

  Map<String, dynamic> toDbMap() => {
        'enfant_id': int.tryParse(enfantId) ?? int.parse(enfantId),
        'date': date.toIso8601String(),
        'repas': repas,
        'quantite': quantite,
        'heure': heure,
        'notes': notes,
        'age_mois': ageMois,
        'aliments': aliments,
      };

  factory JournalAlimentaireModel.fromMap(Map<String, dynamic> map) => JournalAlimentaireModel(
        id: map['id']?.toString() ?? '',
        enfantId: map['enfantId']?.toString() ?? map['enfant_id']?.toString() ?? '',
        date: _parseDate(map['date']) ?? DateTime.now(),
        repas: map['repas'],
        quantite: map['quantite'],
        heure: map['heure'],
        notes: map['notes'],
        ageMois: map['age_mois'] is num ? (map['age_mois'] as num).toInt() : null,
        aliments: map['aliments']?.toString(),
      );

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return null;
    }
  }
}