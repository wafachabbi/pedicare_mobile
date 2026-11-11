import 'package:flutter/foundation.dart';
import '../models/rendezvous_model.dart';
import 'database_service.dart';

class RendezVousService {
  static Future<List<RendezVousModel>> getRendezVous(String enfantId) async {
    try {
      final db = await DatabaseService.database;
      final rows = await db.query(
        'rendezvous',
        where: 'enfant_id = ?',
        whereArgs: [int.parse(enfantId)],
        orderBy: 'date_heure ASC',
      );
      return rows.map((e) => RendezVousModel.fromMap(_normalize(e))).toList();
    } catch (e) {
      debugPrint('[RDV] getRendezVous error: $e');
      return [];
    }
  }

  static Future<List<RendezVousModel>> getRendezVousPediatre(String pediatreId) async {
    try {
      final db = await DatabaseService.database;
      // JOIN enfants et users pour obtenir les noms
      final rows = await db.rawQuery('''
        SELECT r.*,
               e.prenom AS enfant_prenom, e.nom AS enfant_nom,
               u.name   AS parent_nom
        FROM rendezvous r
        LEFT JOIN enfants e ON e.id = r.enfant_id
        LEFT JOIN users   u ON u.id = e.parent_id
        WHERE r.pediatre_id = ?
        ORDER BY r.date_heure ASC
      ''', [int.parse(pediatreId)]);
      return rows.map((e) => RendezVousModel.fromMap(_normalizePediatre(e))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> addRendezVous(RendezVousModel rdv) async {
    try {
      final db = await DatabaseService.database;
      await db.insert('rendezvous', {
        'enfant_id':   int.parse(rdv.enfantId),
        'pediatre_id': rdv.pediatreId != null ? int.tryParse(rdv.pediatreId!) : null,
        'titre':       rdv.titre,
        'medecin':     rdv.medecin,
        'specialite':  rdv.specialite,
        'lieu':        rdv.lieu,
        'date_heure':  _fmtDatetime(rdv.dateHeure),
        'statut':      rdv.statut.name,
        'type':        rdv.type,
        'notes':       rdv.notes,
      });
      return true;
    } catch (e) {
      debugPrint('[RDV] addRendezVous error: $e');
      return false;
    }
  }

  static Future<void> updateRendezVous(RendezVousModel rdv) async {
    final db = await DatabaseService.database;
    await db.update(
      'rendezvous',
      {
        'pediatre_id': rdv.pediatreId != null ? int.tryParse(rdv.pediatreId!) : null,
        'titre':       rdv.titre,
        'medecin':     rdv.medecin,
        'specialite':  rdv.specialite,
        'lieu':        rdv.lieu,
        'date_heure':  _fmtDatetime(rdv.dateHeure),
        'statut':      rdv.statut.name,
        'type':        rdv.type,
        'notes':       rdv.notes,
      },
      where: 'id = ?',
      whereArgs: [int.parse(rdv.id)],
    );
  }

  static Future<void> deleteRendezVous(String enfantId, String id) async {
    final db = await DatabaseService.database;
    await db.delete('rendezvous', where: 'id = ?', whereArgs: [int.parse(id)]);
  }

  static Future<List<RendezVousModel>> getProchains(String enfantId) async {
    final rdvs = await getRendezVous(enfantId);
    final now = DateTime.now();
    return rdvs
        .where((r) => r.dateHeure.isAfter(now) && r.statut != StatutRDV.annule)
        .toList();
  }

  static String _fmtDatetime(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')} '
      '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}:${d.second.toString().padLeft(2,'0')}';

  static Map<String, dynamic> _normalize(Map<String, dynamic> e) => {
    'id':         e['id']?.toString() ?? '',
    'titre':      e['titre'] ?? '',
    'medecin':    e['medecin'] ?? '',
    'specialite': e['specialite'] ?? '',
    'lieu':       e['lieu'] ?? '',
    'dateHeure':  e['date_heure'] ?? '',
    'statut':     e['statut'] ?? 'enAttente',
    'enfantId':   e['enfant_id']?.toString() ?? '',
    'notes':      e['notes'] ?? '',
    'type':       e['type'] ?? 'presentiel',
    'pediatreId': e['pediatre_id']?.toString(),
  };

  static Map<String, dynamic> _normalizePediatre(Map<String, dynamic> e) => {
    ..._normalize(e),
    'enfant_prenom': e['enfant_prenom'],
    'enfant_nom':    e['enfant_nom'],
    'parent_nom':    e['parent_nom'],
  };
}
