import 'dart:developer' as dev;
import '../models/enfant_model.dart';
import 'database_service.dart';
import 'notification_service.dart';
import 'traitement_service.dart';

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
    // Les rappels de médicaments sont programmés hors base : les annuler
    // avant que la suppression en cascade n'efface les traitements.
    for (final t in await TraitementService.getTraitements(id)) {
      try {
        await NotificationService.annulerRappelsTraitement(t.id);
      } catch (e) {
        dev.log('annulerRappelsTraitement error: $e');
      }
    }
    final db = await DatabaseService.database;
    await db.delete('enfants', where: 'id = ?', whereArgs: [int.parse(id)]);
  }

  /// Active ou désactive le partage du journal avec le pédiatre.
  /// Si [pediatreId] est fourni, ce pédiatre est enregistré comme destinataire.
  /// Si [pediatreId] est null, on ne garde que le boolean partage_journal.
  static Future<bool> setPartageJournal(String id, bool partage, {String? pediatreId}) async {
    try {
      final db = await DatabaseService.database;
      // Vérifier si la colonne pediatre_id existe, sinon l'ajouter
      try {
        // Essaie d'accéder à la colonne pour vérifier qu'elle existe
        final List<Map<String, dynamic>> result = await db.rawQuery('PRAGMA table_info(enfants)');
        bool colonneExiste = false;
        for (var row in result) {
          if (row['name'] == 'pediatre_id') {
            colonneExiste = true;
            break;
          }
        }
        // Si la colonne n'existe pas, on l'ajoute
        if (!colonneExiste) {
          await db.execute('ALTER TABLE enfants ADD COLUMN pediatre_id TEXT');
        }
      } catch (_) {
        // Si erreur (base vierge), on ajoute quand même
        try {
          await db.execute('ALTER TABLE enfants ADD COLUMN pediatre_id TEXT');
        } catch (_) {
          // Colonne déjà présente : rien à faire.
        }
      }
      final Map<String, dynamic> updateData = {'partage_journal': partage ? 1 : 0};
      if (pediatreId != null) {
        updateData['pediatre_id'] = pediatreId;
      }
      final count = await db.update(
        'enfants',
        updateData,
        where: 'id = ?',
        whereArgs: [int.parse(id)],
      );
      return count > 0;
    } catch (e) {
      dev.log('setPartageJournal error: $e');
      return false;
    }
  }

  /// Enfants dont le journal est partagé avec CE pédiatre uniquement
  /// ([pediatreId] = users.id du pédiatre connecté). Le nom du parent est
  /// ajouté pour l'affichage côté pédiatre.
  static Future<List<EnfantModel>> getEnfantsPartages(String pediatreId) async {
    if (pediatreId.isEmpty) return [];
    try {
      final db = await DatabaseService.database;
      final rows = await db.rawQuery('''
        SELECT e.*, u.name AS parent_nom
        FROM enfants e
        LEFT JOIN users u ON u.id = e.parent_id
        WHERE e.partage_journal = 1 AND e.pediatre_id = ?
        ORDER BY e.prenom ASC
      ''', [pediatreId]);
      return rows.map((e) => EnfantModel.fromMap(e)).toList();
    } catch (e) {
      dev.log('getEnfantsPartages error: $e');
      return [];
    }
  }
}
