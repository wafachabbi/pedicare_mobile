import '../data/symptomes_catalogue.dart';

enum NiveauToux { aucune, legere, moderee, forte }

enum EtatComportement { normal, calme, fatigue, irritable, lethargique }

enum QualiteSommeil { bon, moyen, agite, mauvais }

enum NiveauAppetit { normal, diminue, faible, excessif }

class JournalSymptomeModel {
  final String id;
  final String enfantId;
  final DateTime date;
  final double? temperature;
  final NiveauToux toux;
  final EtatComportement comportement;
  final QualiteSommeil sommeil;
  final NiveauAppetit appetit;
  final List<String> symptomes;
  final String notes;
  final DateTime createdAt;

  JournalSymptomeModel({
    required this.id,
    required this.enfantId,
    required this.date,
    this.temperature,
    this.toux = NiveauToux.aucune,
    this.comportement = EtatComportement.normal,
    this.sommeil = QualiteSommeil.bon,
    this.appetit = NiveauAppetit.normal,
    this.symptomes = const [],
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get fievre => temperature != null && temperature! >= 38.0;

  bool get fievreElevee => temperature != null && temperature! >= 39.0;

  bool get aSymptomeAlerte =>
      symptomes.any((id) => SymptomesCatalogue.parId(id)?.alerte == true);

  String get resumeCourt {
    if (symptomes.isEmpty) {
      if (fievre) return 'Fièvre';
      return 'Journée sans symptôme';
    }
    return SymptomesCatalogue.libelleListe(symptomes);
  }

  /// Score synthétique utilisé pour les graphiques de suivi.
  int get scoreSeverite {
    int score = 0;
    if (temperature != null) {
      if (temperature! >= 39.5) {
        score += 4;
      } else if (temperature! >= 39) {
        score += 3;
      } else if (temperature! >= 38) {
        score += 2;
      } else if (temperature! >= 37.5) {
        score += 1;
      }
    }
    score += symptomes.length;
    score += toux.index;
    if (comportement == EtatComportement.fatigue) score += 1;
    if (comportement == EtatComportement.irritable) score += 1;
    if (comportement == EtatComportement.lethargique) score += 3;
    if (sommeil == QualiteSommeil.moyen) score += 1;
    if (sommeil == QualiteSommeil.agite) score += 2;
    if (sommeil == QualiteSommeil.mauvais) score += 2;
    if (appetit == NiveauAppetit.diminue) score += 1;
    if (appetit == NiveauAppetit.faible) score += 2;
    return score;
  }

  Map<String, dynamic> toDbMap() => {
        'enfant_id': int.tryParse(enfantId) ?? enfantId,
        'date': date.toIso8601String(),
        'temperature': temperature,
        'toux': toux.name,
        'comportement': comportement.name,
        'sommeil': sommeil.name,
        'appetit': appetit.name,
        'symptomes': symptomes.join(','),
        'notes': notes,
      };

  Map<String, dynamic> toMap() => {
        'id': id,
        'enfantId': enfantId,
        'date': date.toIso8601String(),
        'temperature': temperature,
        'toux': toux.name,
        'comportement': comportement.name,
        'sommeil': sommeil.name,
        'appetit': appetit.name,
        'symptomes': symptomes,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory JournalSymptomeModel.fromMap(Map<String, dynamic> map) {
    final rawSymptomes = map['symptomes'] ?? map['symptoms'];
    List<String> parseSymptomes(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      }
      return value
          .toString()
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    T parseEnum<T extends Enum>(dynamic value, List<T> values, T fallback) {
      if (value == null) return fallback;
      final raw = value.toString();
      for (final v in values) {
        if (v.name == raw) return v;
      }
      return fallback;
    }

    return JournalSymptomeModel(
      id: map['id']?.toString() ?? '',
      enfantId:
          map['enfantId']?.toString() ?? map['enfant_id']?.toString() ?? '',
      date: _parseDate(map['date']) ?? DateTime.now(),
      temperature: map['temperature'] == null
          ? null
          : (map['temperature'] as num).toDouble(),
      toux: parseEnum(map['toux'], NiveauToux.values, NiveauToux.aucune),
      comportement: parseEnum(
          map['comportement'], EtatComportement.values, EtatComportement.normal),
      sommeil:
          parseEnum(map['sommeil'], QualiteSommeil.values, QualiteSommeil.bon),
      appetit: parseEnum(
          map['appetit'], NiveauAppetit.values, NiveauAppetit.normal),
      symptomes: parseSymptomes(rawSymptomes),
      notes: map['notes'] ?? '',
      createdAt: _parseDate(map['createdAt'] ?? map['created_at']) ??
          DateTime.now(),
    );
  }

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

  JournalSymptomeModel copyWith({
    String? id,
    String? enfantId,
    DateTime? date,
    double? temperature,
    NiveauToux? toux,
    EtatComportement? comportement,
    QualiteSommeil? sommeil,
    NiveauAppetit? appetit,
    List<String>? symptomes,
    String? notes,
    DateTime? createdAt,
  }) {
    return JournalSymptomeModel(
      id: id ?? this.id,
      enfantId: enfantId ?? this.enfantId,
      date: date ?? this.date,
      temperature: temperature ?? this.temperature,
      toux: toux ?? this.toux,
      comportement: comportement ?? this.comportement,
      sommeil: sommeil ?? this.sommeil,
      appetit: appetit ?? this.appetit,
      symptomes: symptomes ?? this.symptomes,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
