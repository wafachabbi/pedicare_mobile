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
  final String? pediatreId;
  final String? enfantNomComplet; // enrichi par JOIN côté pédiatre
  final String? parentNom;

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
    this.pediatreId,
    this.enfantNomComplet,
    this.parentNom,
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
      'pediatreId': pediatreId,
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
      id: map['id'].toString(),
      titre: map['titre'] ?? '',
      medecin: map['medecin'] ?? '',
      specialite: map['specialite'] ?? '',
      lieu: map['lieu'] ?? '',
      dateHeure: parseDate(map['dateHeure'] ?? map['date_heure']),
      statut: StatutRDV.values.firstWhere(
        (e) => e.name == map['statut'],
        orElse: () => StatutRDV.enAttente,
      ),
      enfantId: map['enfantId']?.toString() ?? map['enfant_id']?.toString() ?? '',
      notes: map['notes'] ?? '',
      type: map['type'] ?? 'presentiel',
      pediatreId: map['pediatreId']?.toString() ?? map['pediatre_id']?.toString(),
      enfantNomComplet: map['enfant_prenom'] != null
          ? '${map['enfant_prenom']} ${map['enfant_nom']}'
          : null,
      parentNom: map['parent_nom'],
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
      pediatreId: pediatreId,
      enfantNomComplet: enfantNomComplet,
      parentNom: parentNom,
    );
  }
}
