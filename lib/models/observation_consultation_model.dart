/// Module 3 — données saisies par le pédiatre pendant la consultation.
///
/// Le pédiatre enregistre les mesures, ses observations, son diagnostic et
/// ses recommandations. Le parent génère ensuite, à partir de ces données,
/// un résumé IA ([ConsultationModel] lié par `observation_id`).
class ObservationConsultationModel {
  final String id;
  final String enfantId;
  final String pediatreId;
  final String pediatreNom;
  final DateTime dateConsultation;
  final String motif;
  final double? poids;
  final double? taille;
  final double? temperature;
  final String observations;
  final String diagnostic;
  final String traitement;
  final String recommandations;
  final DateTime createdAt;

  ObservationConsultationModel({
    this.id = '',
    required this.enfantId,
    this.pediatreId = '',
    this.pediatreNom = '',
    required this.dateConsultation,
    required this.motif,
    this.poids,
    this.taille,
    this.temperature,
    this.observations = '',
    this.diagnostic = '',
    this.traitement = '',
    this.recommandations = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Signature affichée (« Dr. Rahma »).
  String get signature {
    final n = pediatreNom.trim();
    if (n.isEmpty) return 'Pédiatre';
    return n.toLowerCase().startsWith('dr') ? n : 'Dr. $n';
  }

  Map<String, dynamic> toDbMap() => {
        'enfant_id': int.tryParse(enfantId) ?? enfantId,
        'pediatre_id': pediatreId,
        'pediatre_nom': pediatreNom,
        'date_consultation': dateConsultation.toIso8601String(),
        'motif': motif,
        'poids': poids,
        'taille': taille,
        'temperature': temperature,
        'observations': observations,
        'diagnostic': diagnostic,
        'traitement': traitement,
        'recommandations': recommandations,
        'created_at': createdAt.toIso8601String(),
      };

  factory ObservationConsultationModel.fromDbMap(Map<String, dynamic> m) {
    double? d(dynamic v) => v == null ? null : (v as num).toDouble();
    return ObservationConsultationModel(
      id: m['id']?.toString() ?? '',
      enfantId: m['enfant_id']?.toString() ?? '',
      pediatreId: m['pediatre_id']?.toString() ?? '',
      pediatreNom: m['pediatre_nom']?.toString() ?? '',
      dateConsultation:
          DateTime.tryParse(m['date_consultation']?.toString() ?? '') ??
              DateTime.now(),
      motif: m['motif']?.toString() ?? '',
      poids: d(m['poids']),
      taille: d(m['taille']),
      temperature: d(m['temperature']),
      observations: m['observations']?.toString() ?? '',
      diagnostic: m['diagnostic']?.toString() ?? '',
      traitement: m['traitement']?.toString() ?? '',
      recommandations: m['recommandations']?.toString() ?? '',
      createdAt: DateTime.tryParse(m['created_at']?.toString() ?? ''),
    );
  }

  ObservationConsultationModel copyWith({String? id}) =>
      ObservationConsultationModel(
        id: id ?? this.id,
        enfantId: enfantId,
        pediatreId: pediatreId,
        pediatreNom: pediatreNom,
        dateConsultation: dateConsultation,
        motif: motif,
        poids: poids,
        taille: taille,
        temperature: temperature,
        observations: observations,
        diagnostic: diagnostic,
        traitement: traitement,
        recommandations: recommandations,
        createdAt: createdAt,
      );
}
