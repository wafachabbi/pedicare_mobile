/// Modèles du Module 9 — Nutrition & Alimentation.
library;

DateTime? _parseDate(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString());

// ── Allergie alimentaire ────────────────────────────────────────────────────

enum SeveriteAllergie { legere, moderee, severe }

extension SeveriteAllergieX on SeveriteAllergie {
  String get label => switch (this) {
        SeveriteAllergie.legere => 'Légère',
        SeveriteAllergie.moderee => 'Modérée',
        SeveriteAllergie.severe => 'Sévère',
      };

  static SeveriteAllergie fromName(String? name) =>
      SeveriteAllergie.values.firstWhere(
        (s) => s.name == name,
        orElse: () => SeveriteAllergie.moderee,
      );
}

class AllergieAlimentaireModel {
  final String id;
  final String enfantId;

  /// Identifiant du catalogue (ex. "lait") ou texte libre.
  final String allergene;
  final SeveriteAllergie severite;
  final String reaction;

  AllergieAlimentaireModel({
    required this.id,
    required this.enfantId,
    required this.allergene,
    this.severite = SeveriteAllergie.moderee,
    this.reaction = '',
  });

  Map<String, dynamic> toDbMap() => {
        'enfant_id': int.tryParse(enfantId) ?? enfantId,
        'allergene': allergene,
        'severite': severite.name,
        'reaction': reaction,
      };

  factory AllergieAlimentaireModel.fromMap(Map<String, dynamic> map) =>
      AllergieAlimentaireModel(
        id: map['id']?.toString() ?? '',
        enfantId: map['enfant_id']?.toString() ?? '',
        allergene: map['allergene']?.toString() ?? '',
        severite: SeveriteAllergieX.fromName(map['severite'] as String?),
        reaction: map['reaction']?.toString() ?? '',
      );
}

// ── Allaitement ─────────────────────────────────────────────────────────────

enum TypeAllaitement { seinGauche, seinDroit, biberon }

extension TypeAllaitementX on TypeAllaitement {
  String get label => switch (this) {
        TypeAllaitement.seinGauche => 'Sein gauche',
        TypeAllaitement.seinDroit => 'Sein droit',
        TypeAllaitement.biberon => 'Biberon',
      };

  String get emoji => switch (this) {
        TypeAllaitement.seinGauche => '🤱',
        TypeAllaitement.seinDroit => '🤱',
        TypeAllaitement.biberon => '🍼',
      };

  static TypeAllaitement fromName(String? name) =>
      TypeAllaitement.values.firstWhere(
        (t) => t.name == name,
        orElse: () => TypeAllaitement.biberon,
      );
}

class AllaitementModel {
  final String id;
  final String enfantId;

  /// Début de la tétée / du biberon.
  final DateTime date;
  final TypeAllaitement type;
  final int? dureeMinutes;
  final int? quantiteMl;
  final String notes;

  AllaitementModel({
    required this.id,
    required this.enfantId,
    required this.date,
    required this.type,
    this.dureeMinutes,
    this.quantiteMl,
    this.notes = '',
  });

  Map<String, dynamic> toDbMap() => {
        'enfant_id': int.tryParse(enfantId) ?? enfantId,
        'date': date.toIso8601String(),
        'type': type.name,
        'duree_minutes': dureeMinutes,
        'quantite_ml': quantiteMl,
        'notes': notes,
      };

  factory AllaitementModel.fromMap(Map<String, dynamic> map) =>
      AllaitementModel(
        id: map['id']?.toString() ?? '',
        enfantId: map['enfant_id']?.toString() ?? '',
        date: _parseDate(map['date']) ?? DateTime.now(),
        type: TypeAllaitementX.fromName(map['type'] as String?),
        dureeMinutes: (map['duree_minutes'] as num?)?.toInt(),
        quantiteMl: (map['quantite_ml'] as num?)?.toInt(),
        notes: map['notes']?.toString() ?? '',
      );
}

/// Résumé de l'allaitement sur une journée.
class AllaitementStats {
  final int nombre;
  final int dureeTotaleMinutes;
  final int quantiteTotaleMl;

  /// Intervalle moyen entre deux tétées/biberons (null si < 2 entrées).
  final Duration? intervalleMoyen;
  final DateTime? derniere;

  const AllaitementStats({
    required this.nombre,
    required this.dureeTotaleMinutes,
    required this.quantiteTotaleMl,
    this.intervalleMoyen,
    this.derniere,
  });

  static AllaitementStats depuis(List<AllaitementModel> entrees) {
    if (entrees.isEmpty) {
      return const AllaitementStats(
          nombre: 0, dureeTotaleMinutes: 0, quantiteTotaleMl: 0);
    }
    final tri = [...entrees]..sort((a, b) => a.date.compareTo(b.date));
    Duration? intervalle;
    if (tri.length >= 2) {
      final total = tri.last.date.difference(tri.first.date);
      intervalle = Duration(minutes: total.inMinutes ~/ (tri.length - 1));
    }
    return AllaitementStats(
      nombre: tri.length,
      dureeTotaleMinutes:
          tri.fold(0, (s, e) => s + (e.dureeMinutes ?? 0)),
      quantiteTotaleMl: tri.fold(0, (s, e) => s + (e.quantiteMl ?? 0)),
      intervalleMoyen: intervalle,
      derniere: tri.last.date,
    );
  }
}

// ── Alertes aliments ────────────────────────────────────────────────────────

enum NiveauAlerteAliment { attention, danger }

/// Alerte levée lors de la saisie d'un repas.
class AlerteAliment {
  final NiveauAlerteAliment niveau;
  final String titre;
  final String message;

  const AlerteAliment({
    required this.niveau,
    required this.titre,
    required this.message,
  });
}

// ── Consigne alimentaire du pédiatre ────────────────────────────────────────

class ConseilNutritionModel {
  final String id;
  final String enfantId;
  final String? pediatreId;

  /// Nom affiché de l'auteur (ex. « Dr. Rahma »).
  final String auteur;
  final String texte;
  final DateTime date;

  ConseilNutritionModel({
    required this.id,
    required this.enfantId,
    this.pediatreId,
    this.auteur = '',
    required this.texte,
    required this.date,
  });

  Map<String, dynamic> toDbMap() => {
        'enfant_id': int.tryParse(enfantId) ?? enfantId,
        'pediatre_id': pediatreId == null ? null : int.tryParse(pediatreId!),
        'auteur': auteur,
        'texte': texte,
        'created_at': date.toIso8601String(),
      };

  factory ConseilNutritionModel.fromMap(Map<String, dynamic> map) =>
      ConseilNutritionModel(
        id: map['id']?.toString() ?? '',
        enfantId: map['enfant_id']?.toString() ?? '',
        pediatreId: map['pediatre_id']?.toString(),
        auteur: map['auteur']?.toString() ?? '',
        texte: map['texte']?.toString() ?? '',
        date: _parseDate(map['created_at']) ?? DateTime.now(),
      );
}
