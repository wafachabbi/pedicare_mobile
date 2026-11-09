import 'package:flutter/foundation.dart';
import '../models/consultation_model.dart';
import 'database_service.dart';

class ConsultationService {
  static const _table = 'consultations';

  static Future<List<ConsultationModel>> getConsultations(
    String enfantId, {
    int? limit,
  }) async {
    try {
      final db = await DatabaseService.database;
      final rows = await db.query(
        _table,
        where: 'enfant_id = ?',
        whereArgs: [int.parse(enfantId)],
        orderBy: 'created_at DESC, id DESC',
        limit: limit,
      );
      return rows.map((e) => ConsultationModel.fromMap(_normalize(e))).toList();
    } catch (e) {
      debugPrint('[Consultation] getConsultations error: $e');
      return [];
    }
  }

  static Future<ConsultationModel?> getConsultation(String id) async {
    try {
      final db = await DatabaseService.database;
      final rows = await db.query(
        _table,
        where: 'id = ?',
        whereArgs: [int.parse(id)],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return ConsultationModel.fromMap(_normalize(rows.first));
    } catch (_) {
      return null;
    }
  }

  static Future<String?> addConsultation(ConsultationModel consultation) async {
    try {
      final db = await DatabaseService.database;
      final id = await db.insert(_table, consultation.toDbMap());
      return id.toString();
    } catch (e) {
      debugPrint('[Consultation] addConsultation error: $e');
      return null;
    }
  }

  static Future<bool> deleteConsultation(String id) async {
    try {
      final db = await DatabaseService.database;
      final count = await db.delete(
        _table,
        where: 'id = ?',
        whereArgs: [int.parse(id)],
      );
      return count > 0;
    } catch (e) {
      debugPrint('[Consultation] deleteConsultation error: $e');
      return false;
    }
  }

  /// Résumé IA déjà généré par le parent pour une consultation du pédiatre.
  static Future<ConsultationModel?> getParObservation(
      String observationId) async {
    try {
      final db = await DatabaseService.database;
      final rows = await db.query(
        _table,
        where: 'observation_id = ?',
        whereArgs: [int.parse(observationId)],
        orderBy: 'id DESC',
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return ConsultationModel.fromMap(_normalize(rows.first));
    } catch (_) {
      return null;
    }
  }

  static Future<ConsultationModel?> getDerniere(String enfantId) async {
    final list = await getConsultations(enfantId, limit: 1);
    return list.isEmpty ? null : list.first;
  }

  static Map<String, dynamic> _normalize(Map<String, dynamic> e) => {
        'id': e['id']?.toString() ?? '',
        'enfant_id': e['enfant_id']?.toString() ?? '',
        'titre': e['titre'] ?? '',
        'resume': e['resume'] ?? '',
        'points_cles': e['points_cles'] ?? '',
        'suggestions': e['suggestions'] ?? '',
        'periode_debut': e['periode_debut'],
        'periode_fin': e['periode_fin'],
        'nb_entrees': e['nb_entrees'] ?? 0,
        'generee_ia': e['generee_ia'] ?? 0,
        'observation_id': e['observation_id'],
        'created_at': e['created_at'],
      };
}
