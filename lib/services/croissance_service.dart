import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/croissance_model.dart';
import 'api_config.dart';

class CroissanceService {
  static Future<List<CroissanceModel>> getMesures(String enfantId) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.croissance}?enfant_id=$enfantId'),
      );
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body);
      final list = data['mesures'] as List;
      return list.map((e) => CroissanceModel.fromMap(_normalize(e))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addMesure(CroissanceModel mesure) async {
    await http.post(
      Uri.parse(ApiConfig.croissance),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(mesure.toMap()),
    );
  }

  static Future<void> updateMesure(CroissanceModel mesure) async {
    await http.put(
      Uri.parse('${ApiConfig.croissance}?id=${mesure.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(mesure.toMap()),
    );
  }

  static Future<void> deleteMesure(String enfantId, String id) async {
    await http.delete(Uri.parse('${ApiConfig.croissance}?id=$id'));
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
