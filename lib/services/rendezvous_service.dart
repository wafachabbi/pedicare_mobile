import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rendezvous_model.dart';

class RendezVousService {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference _col(String enfantId) => _db
      .collection('enfants')
      .doc(enfantId)
      .collection('rendezvous');

  static Future<List<RendezVousModel>> getRendezVous(String enfantId) async {
    try {
      final snap = await _col(enfantId)
          .orderBy('dateHeure')
          .get();
      return snap.docs
          .map((d) => RendezVousModel.fromMap({'id': d.id, ...d.data() as Map<String, dynamic>}))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addRendezVous(RendezVousModel rdv) async {
    final data = rdv.toMap();
    data.remove('id');
    await _col(rdv.enfantId).doc(rdv.id).set(data);
  }

  static Future<void> updateRendezVous(RendezVousModel rdv) async {
    final data = rdv.toMap();
    data.remove('id');
    await _col(rdv.enfantId).doc(rdv.id).update(data);
  }

  static Future<void> deleteRendezVous(String enfantId, String id) async {
    await _col(enfantId).doc(id).delete();
  }

  static Future<List<RendezVousModel>> getProchains(String enfantId) async {
    final rdvs = await getRendezVous(enfantId);
    final now = DateTime.now();
    return rdvs
        .where((r) => r.dateHeure.isAfter(now) && r.statut != StatutRDV.annule)
        .toList();
  }
}
