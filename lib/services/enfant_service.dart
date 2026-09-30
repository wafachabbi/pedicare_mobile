import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import '../models/enfant_model.dart';
import 'api_config.dart';

class EnfantService {
  static Future<List<EnfantModel>> getEnfants(String parentId) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.enfants}?parent_id=$parentId'),
      );
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body);
      final list = data['enfants'] as List;
      return list.map((e) => EnfantModel.fromMap(e)).toList();
    } catch (e) {
      dev.log('getEnfants error: $e');
      return [];
    }
  }

  static Future<String?> addEnfant(EnfantModel enfant) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.enfants),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(enfant.toMap()),
      );
      dev.log('addEnfant status: ${res.statusCode}, body: ${res.body}');
      if (res.statusCode == 201) {
        return jsonDecode(res.body)['id'].toString();
      }
      return null;
    } catch (e) {
      dev.log('addEnfant error: $e');
      return null;
    }
  }

  static Future<void> updateEnfant(EnfantModel enfant) async {
    await http.put(
      Uri.parse('${ApiConfig.enfants}?id=${enfant.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(enfant.toMap()),
    );
  }

  static Future<void> deleteEnfant(String id) async {
    await http.delete(Uri.parse('${ApiConfig.enfants}?id=$id'));
  }
}
