enum StatutRDV { confirme, enAttente, annule, termine }

class RendezVousModel {
  final String id;
  final String titre;
  final String medecin;
  final String specialite;
  final String lieu;
  final DateTime dateHeure;
  final StatutRDV statut;
  final String enfantId;
  final String notes;
  final String type;

  RendezVousModel({
    required this.id,
    required this.titre,
    required this.medecin,
    required this.specialite,
    required this.lieu,
    required this.dateHeure,
    this.statut = StatutRDV.enAttente,
    required this.enfantId,
    this.notes = '',
    this.type = 'presentiel',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titre': titre,
      'medecin': medecin,
      'specialite': specialite,
      'lieu': lieu,
      'dateHeure': dateHeure.toIso8601String(),
      'statut': statut.name,
      'enfantId': enfantId,
      'notes': notes,
      'type': type,
    };
  }

  factory RendezVousModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is String) return DateTime.parse(val);
      try { return (val as dynamic).toDate(); } catch (_) {}
      return DateTime.now();
    }

    return RendezVousModel(
      id: map['id'] ?? '',
      titre: map['titre'] ?? '',
      medecin: map['medecin'] ?? '',
      specialite: map['specialite'] ?? '',
      lieu: map['lieu'] ?? '',
      dateHeure: parseDate(map['dateHeure']),
      statut: StatutRDV.values.firstWhere(
        (e) => e.name == map['statut'],
        orElse: () => StatutRDV.enAttente,
      ),
      enfantId: map['enfantId'] ?? '',
      notes: map['notes'] ?? '',
      type: map['type'] ?? 'presentiel',
    );
  }

  RendezVousModel copyWith({StatutRDV? statut, String? notes}) {
    return RendezVousModel(
      id: id,
      titre: titre,
      medecin: medecin,
      specialite: specialite,
      lieu: lieu,
      dateHeure: dateHeure,
      statut: statut ?? this.statut,
      enfantId: enfantId,
      notes: notes ?? this.notes,
      type: type,
    );
  }
}
