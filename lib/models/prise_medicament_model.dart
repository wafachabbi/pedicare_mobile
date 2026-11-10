import 'traitement_model.dart';

/// Statut d'une prise de médicament confirmée par le parent.
enum StatutPrise { pris, oublie, reporte }

extension StatutPriseX on StatutPrise {
  String get label => switch (this) {
        StatutPrise.pris => 'Pris',
        StatutPrise.oublie => 'Oublié',
        StatutPrise.reporte => 'Reporté',
      };

  String get emoji => switch (this) {
        StatutPrise.pris => '✅',
        StatutPrise.oublie => '❌',
        StatutPrise.reporte => '⏰',
      };

  static StatutPrise fromName(String? name) => StatutPrise.values.firstWhere(
        (s) => s.name == name,
        orElse: () => StatutPrise.oublie,
      );
}

/// Prise enregistrée (table prises_medicament).
class PriseMedicamentModel {
  final String id;
  final String traitementId;
  final String enfantId;

  /// Date et heure prévues de la prise (créneau du traitement).
  final DateTime datePrevue;
  final StatutPrise statut;

  /// Moment où le parent a confirmé le statut.
  final DateTime dateAction;

  /// Nom du médicament (rempli par jointure pour l'historique).
  final String? traitementNom;

  PriseMedicamentModel({
    required this.id,
    required this.traitementId,
    required this.enfantId,
    required this.datePrevue,
    required this.statut,
    required this.dateAction,
    this.traitementNom,
  });

  Map<String, dynamic> toDbMap() => {
        'traitement_id': int.tryParse(traitementId) ?? traitementId,
        'enfant_id': int.tryParse(enfantId) ?? enfantId,
        'date_prevue': datePrevue.toIso8601String(),
        'statut': statut.name,
        'date_action': dateAction.toIso8601String(),
      };

  factory PriseMedicamentModel.fromMap(Map<String, dynamic> map) =>
      PriseMedicamentModel(
        id: map['id']?.toString() ?? '',
        traitementId: map['traitement_id']?.toString() ?? '',
        enfantId: map['enfant_id']?.toString() ?? '',
        datePrevue: DateTime.parse(map['date_prevue'] as String),
        statut: StatutPriseX.fromName(map['statut'] as String?),
        dateAction: DateTime.tryParse(map['date_action']?.toString() ?? '') ??
            DateTime.now(),
        traitementNom: map['traitement_nom'] as String?,
      );
}

/// Une dose à donner aujourd'hui : créneau du traitement + éventuelle prise
/// déjà enregistrée.
class DoseDuJour {
  final TraitementModel traitement;
  final DateTime heure;
  final PriseMedicamentModel? prise;

  DoseDuJour({required this.traitement, required this.heure, this.prise});

  /// À faire : pas encore confirmée, ou reportée.
  bool get enAttente => prise == null || prise!.statut == StatutPrise.reporte;

  /// En retard : en attente et heure dépassée de plus de 30 minutes.
  bool enRetard(DateTime maintenant) =>
      enAttente && maintenant.isAfter(heure.add(const Duration(minutes: 30)));
}

/// Statistiques d'observance d'un traitement.
class ObservanceStats {
  final int pris;
  final int oublies;
  final int reportes;

  const ObservanceStats({
    required this.pris,
    required this.oublies,
    required this.reportes,
  });

  int get total => pris + oublies + reportes;

  /// Part des prises confirmées « pris » parmi les prises tranchées
  /// (pris + oublié). Null s'il n'y a encore rien à mesurer.
  double? get taux {
    final base = pris + oublies;
    if (base == 0) return null;
    return pris / base;
  }

  static ObservanceStats depuis(Iterable<PriseMedicamentModel> prises) {
    var p = 0, o = 0, r = 0;
    for (final x in prises) {
      switch (x.statut) {
        case StatutPrise.pris:
          p++;
        case StatutPrise.oublie:
          o++;
        case StatutPrise.reporte:
          r++;
      }
    }
    return ObservanceStats(pris: p, oublies: o, reportes: r);
  }
}
