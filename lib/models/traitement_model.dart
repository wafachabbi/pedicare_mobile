/// Traitement médicamenteux prescrit (Module 5 — PediPharma).
class TraitementModel {
  final String id;
  final String enfantId;
  final String nom;
  final String posologie;
  final String frequence;
  final DateTime dateDebut;
  final DateTime? dateFin;
  final String notes;

  /// Médecin prescripteur.
  final String medecin;

  /// Heures de prise quotidiennes au format "HH:mm", triées.
  final List<String> heures;

  /// Les rappels de prise sont-ils activés ?
  final bool rappels;

  TraitementModel({
    required this.id,
    required this.enfantId,
    required this.nom,
    this.posologie = '',
    this.frequence = '',
    required this.dateDebut,
    this.dateFin,
    this.notes = '',
    this.medecin = '',
    List<String> heures = const [],
    this.rappels = true,
  }) : heures = trierHeures(heures);

  /// Vrai si le traitement n'est pas terminé (fin non atteinte).
  bool get actif {
    if (dateFin == null) return true;
    final now = DateTime.now();
    final aujourdhui = DateTime(now.year, now.month, now.day);
    final fin = DateTime(dateFin!.year, dateFin!.month, dateFin!.day);
    return !fin.isBefore(aujourdhui);
  }

  /// Vrai si le traitement couvre le jour [jour] (début et fin inclus).
  bool couvreLeJour(DateTime jour) {
    final j = DateTime(jour.year, jour.month, jour.day);
    final debut = DateTime(dateDebut.year, dateDebut.month, dateDebut.day);
    if (j.isBefore(debut)) return false;
    if (dateFin == null) return true;
    final fin = DateTime(dateFin!.year, dateFin!.month, dateFin!.day);
    return !j.isAfter(fin);
  }

  Map<String, dynamic> toDbMap() => {
        'enfant_id': int.tryParse(enfantId) ?? enfantId,
        'nom': nom,
        'posologie': posologie,
        'frequence': frequence,
        'date_debut': dateDebut.toIso8601String(),
        'date_fin': dateFin?.toIso8601String(),
        'notes': notes,
        'medecin': medecin,
        'heures': heures.join(','),
        'rappels': rappels ? 1 : 0,
      };

  TraitementModel copyWith({String? id}) => TraitementModel(
        id: id ?? this.id,
        enfantId: enfantId,
        nom: nom,
        posologie: posologie,
        frequence: frequence,
        dateDebut: dateDebut,
        dateFin: dateFin,
        notes: notes,
        medecin: medecin,
        heures: heures,
        rappels: rappels,
      );

  factory TraitementModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final rappels = map['rappels'];
    return TraitementModel(
      id: map['id']?.toString() ?? '',
      enfantId:
          map['enfantId']?.toString() ?? map['enfant_id']?.toString() ?? '',
      nom: map['nom'] ?? '',
      posologie: map['posologie'] ?? '',
      frequence: map['frequence'] ?? '',
      dateDebut:
          parseDate(map['dateDebut'] ?? map['date_debut']) ?? DateTime.now(),
      dateFin: parseDate(map['dateFin'] ?? map['date_fin']),
      notes: map['notes'] ?? '',
      medecin: map['medecin'] ?? '',
      heures: parseHeures(map['heures']),
      rappels: rappels == null || rappels == 1 || rappels == true,
    );
  }

  /// "08:00,20:00" -> ["08:00", "20:00"] (valeurs invalides ignorées).
  static List<String> parseHeures(dynamic value) {
    if (value == null) return const [];
    final brut = value is List ? value.map((e) => e.toString()) : value.toString().split(',');
    return brut.map((h) => h.trim()).where(heureValide).toList();
  }

  static bool heureValide(String h) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(h);
    if (m == null) return false;
    final hh = int.parse(m.group(1)!);
    final mm = int.parse(m.group(2)!);
    return hh < 24 && mm < 60;
  }

  static List<String> trierHeures(List<String> heures) {
    final valides = heures.where(heureValide).map(_normaliser).toSet().toList();
    valides.sort();
    return List.unmodifiable(valides);
  }

  static String _normaliser(String h) {
    final p = h.split(':');
    return '${p[0].padLeft(2, '0')}:${p[1]}';
  }

  /// Heures proposées par défaut selon le nombre de prises par jour.
  static List<String> heuresParDefaut(int prisesParJour) {
    switch (prisesParJour) {
      case 1:
        return const ['08:00'];
      case 2:
        return const ['08:00', '20:00'];
      case 3:
        return const ['08:00', '14:00', '20:00'];
      case 4:
        return const ['08:00', '12:00', '16:00', '20:00'];
      default:
        return const [];
    }
  }
}
