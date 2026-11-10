import 'package:flutter/foundation.dart';
import '../models/observation_consultation_model.dart';
import 'database_service.dart';

/// Module 3 — CRUD des consultations saisies par le pédiatre.
class ObservationConsultationService {
  static const _table = 'observations_consultation';

  static Future<List<ObservationConsultationModel>> getObservations(
      String enfantId) async {
    try {
      final db = await DatabaseService.database;
      final rows = await db.query(
        _table,
        where: 'enfant_id = ?',
        whereArgs: [int.parse(enfantId)],
        orderBy: 'date_consultation DESC, id DESC',
      );
      return rows.map(ObservationConsultationModel.fromDbMap).toList();
    } catch (e) {
      debugPrint('[Observation] getObservations error: $e');
      return [];
    }
  }

  static Future<String?> addObservation(ObservationConsultationModel o) async {
    try {
      final db = await DatabaseService.database;
      final id = await db.insert(_table, o.toDbMap());
      return id.toString();
    } catch (e) {
      debugPrint('[Observation] addObservation error: $e');
      return null;
    }
  }

  static Future<bool> updateObservation(ObservationConsultationModel o) async {
    try {
      final db = await DatabaseService.database;
      final count = await db.update(_table, o.toDbMap(),
          where: 'id = ?', whereArgs: [int.parse(o.id)]);
      return count > 0;
    } catch (e) {
      debugPrint('[Observation] updateObservation error: $e');
      return false;
    }
  }

  /// Supprime la consultation et le résumé IA qui en a été tiré.
  static Future<bool> deleteObservation(String id) async {
    try {
      final db = await DatabaseService.database;
      await db.delete('consultations',
          where: 'observation_id = ?', whereArgs: [int.parse(id)]);
      final count = await db
          .delete(_table, where: 'id = ?', whereArgs: [int.parse(id)]);
      return count > 0;
    } catch (e) {
      debugPrint('[Observation] deleteObservation error: $e');
      return false;
    }
  }
}
