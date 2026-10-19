import 'dart:developer' as dev;
import '../models/pediatre_model.dart';
import 'database_service.dart';

class PediatreService {
  static Future<List<PediatreModel>> getPediatres() async {
    try {
      final db = await DatabaseService.database;
      final rows = await db.query(
        'users',
        columns: ['id', 'name', 'email'],
        where: 'role = ?',
        whereArgs: ['pediatre'],
        orderBy: 'name ASC',
      );
      dev.log('PediatreService: ${rows.length} pédiatres trouvés');
      return rows.map((e) => PediatreModel.fromMap(e)).toList();
    } catch (e) {
      dev.log('PediatreService ERROR: $e');
      return [];
    }
  }
}
