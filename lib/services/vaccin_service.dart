import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vaccin_model.dart';
import 'api_config.dart';

class VaccinService {
  static Future<List<VaccinModel>> getVaccins(String enfantId) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.vaccins}?enfant_id=$enfantId'),
      );
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body);
      final list = data['vaccins'] as List;
      return list.map((e) => VaccinModel.fromMap(_normalize(e))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addVaccin(VaccinModel vaccin) async {
    await http.post(
      Uri.parse(ApiConfig.vaccins),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(vaccin.toMap()),
    );
  }

  static Future<void> updateVaccin(VaccinModel vaccin) async {
    await http.put(
      Uri.parse('${ApiConfig.vaccins}?id=${vaccin.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(vaccin.toMap()),
    );
  }

  static Future<void> deleteVaccin(String enfantId, String id) async {
    await http.delete(Uri.parse('${ApiConfig.vaccins}?id=$id'));
  }

  static Future<List<VaccinModel>> getProchainesEcheances(String enfantId) async {
    final vaccins = await getVaccins(enfantId);
    final now = DateTime.now();
    return vaccins
        .where((v) => v.prochaineDate != null && v.prochaineDate!.isAfter(now))
        .toList()
      ..sort((a, b) => a.prochaineDate!.compareTo(b.prochaineDate!));
  }

  // MySQL retourne des noms snake_case — mapper vers camelCase attendu par le model
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
