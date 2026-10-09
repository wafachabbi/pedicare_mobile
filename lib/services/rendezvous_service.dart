import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/rendezvous_model.dart';
import 'api_config.dart';

class RendezVousService {
  static Future<List<RendezVousModel>> getRendezVous(String enfantId) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.rendezvous}?enfant_id=$enfantId'),
      );
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body);
      final list = data['rendezvous'] as List;
      return list.map((e) => RendezVousModel.fromMap(_normalize(e))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<RendezVousModel>> getRendezVousPediatre(String pediatreId) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.rendezvous}?pediatre_id=$pediatreId'),
      );
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body);
      final list = data['rendezvous'] as List;
      return list.map((e) => RendezVousModel.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addRendezVous(RendezVousModel rdv) async {
    await http.post(
      Uri.parse(ApiConfig.rendezvous),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(rdv.toMap()),
    );
  }

  static Future<void> updateRendezVous(RendezVousModel rdv) async {
    await http.put(
      Uri.parse('${ApiConfig.rendezvous}?id=${rdv.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(rdv.toMap()),
    );
  }

  static Future<void> deleteRendezVous(String enfantId, String id) async {
    await http.delete(Uri.parse('${ApiConfig.rendezvous}?id=$id'));
  }

  static Future<List<RendezVousModel>> getProchains(String enfantId) async {
    final rdvs = await getRendezVous(enfantId);
    final now = DateTime.now();
    return rdvs
        .where((r) => r.dateHeure.isAfter(now) && r.statut != StatutRDV.annule)
        .toList();
  }

  static Map<String, dynamic> _normalize(Map<String, dynamic> e) => {
    'id':         e['id'].toString(),
    'titre':      e['titre'] ?? '',
    'medecin':    e['medecin'] ?? '',
    'specialite': e['specialite'] ?? '',
    'lieu':       e['lieu'] ?? '',
    'dateHeure':  e['date_heure'] ?? '',
    'statut':     e['statut'] ?? 'enAttente',
    'enfantId':   e['enfant_id'].toString(),
    'notes':      e['notes'] ?? '',
    'type':       e['type'] ?? 'presentiel',
  };
}
