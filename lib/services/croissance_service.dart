import '../models/croissance_model.dart';
import 'database_service.dart';

class CroissanceService {
  static Future<List<CroissanceModel>> getMesures(String enfantId) async {
    try {
      final db = await DatabaseService.database;
      final rows = await db.query(
        'croissance',
        where: 'enfant_id = ?',
        whereArgs: [int.parse(enfantId)],
        orderBy: 'date_mesure DESC',
      );
      return rows.map((e) => CroissanceModel.fromMap(_normalize(e))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addMesure(CroissanceModel mesure) async {
    final db = await DatabaseService.database;
    await db.insert('croissance', {
      'enfant_id':         int.parse(mesure.enfantId),
      'date_mesure':       mesure.date.toIso8601String().split('T')[0],
      'poids':             mesure.poids,
      'taille':            mesure.taille,
      'perimetre_cranien': mesure.perimeterCranien,
      'notes':             mesure.notes,
    });
  }

  static Future<void> updateMesure(CroissanceModel mesure) async {
    final db = await DatabaseService.database;
    await db.update(
      'croissance',
      {
        'date_mesure':       mesure.date.toIso8601String().split('T')[0],
        'poids':             mesure.poids,
        'taille':            mesure.taille,
        'perimetre_cranien': mesure.perimeterCranien,
        'notes':             mesure.notes,
      },
      where: 'id = ?',
      whereArgs: [int.parse(mesure.id)],
    );
  }

  static Future<void> deleteMesure(String enfantId, String id) async {
    final db = await DatabaseService.database;
    await db.delete('croissance', where: 'id = ?', whereArgs: [int.parse(id)]);
  }

  static Future<CroissanceModel?> getDerniereMesure(String enfantId) async {
    final mesures = await getMesures(enfantId);
    if (mesures.isEmpty) return null;
    return mesures.first;
  }

  static Map<String, dynamic> _normalize(Map<String, dynamic> e) => {
    'id':               e['id'].toString(),
    'enfantId':         e['enfant_id'].toString(),
    'date':             e['date_mesure'] ?? '',
    'poids':            e['poids'],
    'taille':           e['taille'],
    'perimeterCranien': e['perimetre_cranien'],
    'notes':            e['notes'] ?? '',
  };
}
