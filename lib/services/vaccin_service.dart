import '../models/vaccin_model.dart';
import 'database_service.dart';

class VaccinService {
  static Future<List<VaccinModel>> getVaccins(String enfantId) async {
    try {
      final db = await DatabaseService.database;
      final rows = await db.query(
        'vaccins',
        where: 'enfant_id = ?',
        whereArgs: [int.parse(enfantId)],
        orderBy: 'date_administre DESC',
      );
      return rows.map((e) => VaccinModel.fromMap(_normalize(e))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addVaccin(VaccinModel vaccin) async {
    final db = await DatabaseService.database;
    await db.insert('vaccins', {
      'enfant_id':       int.parse(vaccin.enfantId),
      'nom':             vaccin.nom,
      'maladie':         vaccin.maladie,
      'date_administre': vaccin.dateAdministre.toIso8601String().split('T')[0],
      'medecin':         vaccin.medecin,
      'lieu':            vaccin.lieu,
      'lot_numero':      vaccin.lotNumero,
      'prochaine_date':  vaccin.prochaineDate?.toIso8601String().split('T')[0],
      'notes':           vaccin.notes,
    });
  }

  static Future<void> updateVaccin(VaccinModel vaccin) async {
    final db = await DatabaseService.database;
    await db.update(
      'vaccins',
      {
        'nom':             vaccin.nom,
        'maladie':         vaccin.maladie,
        'date_administre': vaccin.dateAdministre.toIso8601String().split('T')[0],
        'medecin':         vaccin.medecin,
        'lieu':            vaccin.lieu,
        'lot_numero':      vaccin.lotNumero,
        'prochaine_date':  vaccin.prochaineDate?.toIso8601String().split('T')[0],
        'notes':           vaccin.notes,
      },
      where: 'id = ?',
      whereArgs: [int.parse(vaccin.id)],
    );
  }

  static Future<void> deleteVaccin(String enfantId, String id) async {
    final db = await DatabaseService.database;
    await db.delete('vaccins', where: 'id = ?', whereArgs: [int.parse(id)]);
  }

  static Future<List<VaccinModel>> getProchainesEcheances(String enfantId) async {
    final vaccins = await getVaccins(enfantId);
    final now = DateTime.now();
    return vaccins
        .where((v) => v.prochaineDate != null && v.prochaineDate!.isAfter(now))
        .toList()
      ..sort((a, b) => a.prochaineDate!.compareTo(b.prochaineDate!));
  }

  static Map<String, dynamic> _normalize(Map<String, dynamic> e) => {
    'id':             e['id'].toString(),
    'nom':            e['nom'] ?? '',
    'maladie':        e['maladie'] ?? '',
    'dateAdministre': e['date_administre'] ?? '',
    'medecin':        e['medecin'] ?? '',
    'lieu':           e['lieu'] ?? '',
    'lotNumero':      e['lot_numero'] ?? '',
    'prochaineDate':  e['prochaine_date'],
    'enfantId':       e['enfant_id'].toString(),
    'notes':          e['notes'] ?? '',
  };
}
