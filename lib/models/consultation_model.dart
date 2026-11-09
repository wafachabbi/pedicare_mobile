class ConsultationModel {
  final String id;
  final String enfantId;
  final String titre;
  final String resume;
  final String pointsCles;
  final String suggestions;
  final DateTime? periodeDebut;
  final DateTime? periodeFin;
  final int nbEntrees;
  final bool genereeIA;
  final DateTime createdAt;

  ConsultationModel({
    required this.id,
    required this.enfantId,
    required this.titre,
    required this.resume,
    this.pointsCles = '',
    this.suggestions = '',
    this.periodeDebut,
    this.periodeFin,
    this.nbEntrees = 0,
    this.genereeIA = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  List<String> get pointsClesListe => pointsCles
      .split('\n')
      .map((e) => e.replaceFirst(RegExp(r'^[-•]\s*'), '').trim())
      .where((e) => e.isNotEmpty)
      .toList();

  List<String> get suggestionsListe => suggestions
      .split('\n')
      .map((e) => e.replaceFirst(RegExp(r'^[-•]\s*'), '').trim())
      .where((e) => e.isNotEmpty)
      .toList();

  Map<String, dynamic> toDbMap() => {
        'enfant_id': int.tryParse(enfantId) ?? enfantId,
        'titre': titre,
        'resume': resume,
        'points_cles': pointsCles,
        'suggestions': suggestions,
        'periode_debut': periodeDebut?.toIso8601String(),
        'periode_fin': periodeFin?.toIso8601String(),
        'nb_entrees': nbEntrees,
        'generee_ia': genereeIA ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  Map<String, dynamic> toMap() => {
        'id': id,
        'enfantId': enfantId,
        'titre': titre,
        'resume': resume,
        'pointsCles': pointsCles,
        'suggestions': suggestions,
        'periodeDebut': periodeDebut?.toIso8601String(),
        'periodeFin': periodeFin?.toIso8601String(),
        'nbEntrees': nbEntrees,
        'genereeIA': genereeIA,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ConsultationModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      try {
        return (value as dynamic).toDate() as DateTime;
      } catch (_) {
        return null;
      }
    }

    return ConsultationModel(
      id: map['id']?.toString() ?? '',
      enfantId:
          map['enfantId']?.toString() ?? map['enfant_id']?.toString() ?? '',
      titre: map['titre'] ?? '',
      resume: map['resume'] ?? '',
      pointsCles: map['pointsCles'] ?? map['points_cles'] ?? '',
      suggestions: map['suggestions'] ?? '',
      periodeDebut:
          parseDate(map['periodeDebut'] ?? map['periode_debut']),
      periodeFin: parseDate(map['periodeFin'] ?? map['periode_fin']),
      nbEntrees:
          (map['nbEntrees'] ?? map['nb_entrees'] ?? 0) is num
              ? (map['nbEntrees'] ?? map['nb_entrees'] ?? 0).toInt()
              : int.tryParse(
                      (map['nbEntrees'] ?? map['nb_entrees'] ?? '0').toString()) ??
                  0,
      genereeIA: (map['genereeIA'] ?? map['generee_ia']) == true ||
          (map['genereeIA'] ?? map['generee_ia']) == 1 ||
          (map['genereeIA'] ?? map['generee_ia']) == '1',
      createdAt: parseDate(map['createdAt'] ?? map['created_at']) ??
          DateTime.now(),
    );
  }
}
