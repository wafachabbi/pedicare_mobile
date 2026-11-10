import 'package:flutter/foundation.dart';
import '../models/journal_alimentaire_model.dart';
import 'database_service.dart';

class JournalAlimentaireService {
  static const _table = 'journal_alimentaire';

  /// Read all food journal entries for a child
  static Future<List<JournalAlimentaireModel>> getEntrees(String enfantId) async {
    try {
      final db = await DatabaseService.database;
      final rows = await db.query(
        _table,
        where: 'enfant_id = ?',
        whereArgs: [int.parse(enfantId)],
        orderBy: 'date DESC',
      );
      return rows.map((e) => JournalAlimentaireModel.fromMap(_normalize(e))).toList();
    } catch (e) {
      debugPrint('[JournalAlimentaire] getEntrees error: $e');
      return [];
    }
  }

  /// Read entries for a specific period (days)
  static Future<List<JournalAlimentaireModel>> getEntreesPeriode(
    String enfantId,
    DateTime debut,
    DateTime fin,
  ) async {
    try {
      final db = await DatabaseService.database;
      final rows = await db.query(
        _table,
        where: 'enfant_id = ? AND date >= ? AND date <= ?',
        whereArgs: [
          int.parse(enfantId),
          _startOfDay(debut).toIso8601String(),
          _endOfDay(fin).toIso8601String(),
        ],
        orderBy: 'date DESC',
      );
      return rows.map((e) => JournalAlimentaireModel.fromMap(_normalize(e))).toList();
    } catch (e) {
      debugPrint('[JournalAlimentaire] getEntreesPeriode error: $e');
      return [];
    }
  }

  /// Create a new food journal entry
  static Future<String?> addEntree(JournalAlimentaireModel entree) async {
    try {
      final db = await DatabaseService.database;
      final id = await db.insert(_table, entree.toDbMap());
      return id.toString();
    } catch (e) {
      debugPrint('[JournalAlimentaire] addEntree error: $e');
      return null;
    }
  }

  /// Update an existing entry
  static Future<bool> updateEntree(JournalAlimentaireModel entree) async {
    try {
      final db = await DatabaseService.database;
      final count = await db.update(
        _table,
        entree.toDbMap(),
        where: 'id = ?',
        whereArgs: [int.parse(entree.id)],
      );
      return count > 0;
    } catch (e) {
      debugPrint('[JournalAlimentaire] updateEntree error: $e');
      return false;
    }
  }

  /// Delete an entry
  static Future<bool> deleteEntree(String id) async {
    try {
      final db = await DatabaseService.database;
      final count = await db.delete(
        _table,
        where: 'id = ?',
        whereArgs: [int.parse(id)],
      );
      return count > 0;
    } catch (e) {
      debugPrint('[JournalAlimentaire] deleteEntree error: $e');
      return false;
    }
  }

  /// Check if there's an entry today
  static Future<bool> aEntreeAujourdhui(String enfantId) async {
    try {
      final db = await DatabaseService.database;
      final debut = _startOfDay(DateTime.now()).toIso8601String();
      final fin = _endOfDay(DateTime.now()).toIso8601String();
      final rows = await db.query(
        _table,
        columns: ['id'],
        where: 'enfant_id = ? AND date >= ? AND date <= ?',
        whereArgs: [int.parse(enfantId), debut, fin],
        limit: 1,
      );
      return rows.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Helper: start of day
  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Normalize a database map to JournalAlimentaireModel
  static Map<String, dynamic> _normalize(Map<String, dynamic> map) {
    return {
      'id': map['id']?.toString() ?? '',
      'enfantId': map['enfantId']?.toString() ?? map['enfant_id']?.toString() ?? '',
      'date': map['date'] is DateTime ? map['date'] : DateTime.tryParse(map['date']) ?? DateTime.now(),
      'repas': map['repas'],
      'quantite': map['quantite'],
      'heure': map['heure'],
      'notes': map['notes'],
      'age_mois': map['age_mois'] is num ? (map['age_mois'] as num).toInt() : null,
      'aliments': map['aliments'],
    };
  }

  /// Helper: end of day (23:59:59.999)
  static DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);
}