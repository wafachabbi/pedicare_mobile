import 'dart:developer' as dev;
import '../models/enfant_model.dart';
import 'database_service.dart';

class EnfantService {
  static Future<List<EnfantModel>> getEnfants(String parentId) async {
    try {
      final db = await DatabaseService.database;
      final rows = await db.query(
        'enfants',
        where: 'parent_id = ?',
        whereArgs: [int.parse(parentId)],
        orderBy: 'prenom ASC',
      );
      return rows.map((e) => EnfantModel.fromMap(e)).toList();
    } catch (e) {
      dev.log('getEnfants error: $e');
      return [];
    }
  }

  static Future<String?> addEnfant(EnfantModel enfant) async {
    try {
      final db = await DatabaseService.database;
      final id = await db.insert('enfants', {
        'parent_id':      int.parse(enfant.parentId),
        'nom':            enfant.nom,
        'prenom':         enfant.prenom,
        'date_naissance': enfant.dateNaissance.toIso8601String().split('T')[0],
        'sexe':           enfant.sexe,
        'groupe_sanguin': enfant.groupeSanguin,
        'allergies':      enfant.allergies,
      });
      dev.log('addEnfant id: $id');
      return id.toString();
    } catch (e) {
      dev.log('addEnfant error: $e');
      return null;
    }
  }

  static Future<void> updateEnfant(EnfantModel enfant) async {
    final db = await DatabaseService.database;
    await db.update(
      'enfants',
      {
        'nom':            enfant.nom,
        'prenom':         enfant.prenom,
        'date_naissance': enfant.dateNaissance.toIso8601String().split('T')[0],
        'sexe':           enfant.sexe,
        'groupe_sanguin': enfant.groupeSanguin,
        'allergies':      enfant.allergies,
      },
      where: 'id = ?',
      whereArgs: [int.parse(enfant.id)],
    );
  }

  static Future<void> deleteEnfant(String id) async {
    final db = await DatabaseService.database;
    await db.delete('enfants', where: 'id = ?', whereArgs: [int.parse(id)]);
  }
}
