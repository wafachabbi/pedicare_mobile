import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vaccin_model.dart';

class VaccinService {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference _col(String enfantId) => _db
      .collection('enfants')
      .doc(enfantId)
      .collection('vaccins');

  static Future<List<VaccinModel>> getVaccins(String enfantId) async {
    try {
      final snap = await _col(enfantId)
          .orderBy('dateAdministre', descending: true)
          .get();
      return snap.docs
          .map((d) => VaccinModel.fromMap({'id': d.id, ...d.data() as Map<String, dynamic>}))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addVaccin(VaccinModel vaccin) async {
    final data = vaccin.toMap();
    data.remove('id');
    await _col(vaccin.enfantId).doc(vaccin.id).set(data);
  }

  static Future<void> updateVaccin(VaccinModel vaccin) async {
    final data = vaccin.toMap();
    data.remove('id');
    await _col(vaccin.enfantId).doc(vaccin.id).update(data);
  }

  static Future<void> deleteVaccin(String enfantId, String id) async {
    await _col(enfantId).doc(id).delete();
  }

  static Future<List<VaccinModel>> getProchainesEcheances(String enfantId) async {
    final vaccins = await getVaccins(enfantId);
    final now = DateTime.now();
    return vaccins
        .where((v) => v.prochaineDate != null && v.prochaineDate!.isAfter(now))
        .toList()
      ..sort((a, b) => a.prochaineDate!.compareTo(b.prochaineDate!));
  }
}
