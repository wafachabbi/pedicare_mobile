import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pediatre_model.dart';
import 'api_config.dart';

class PediatreService {
  static Future<List<PediatreModel>> getPediatres() async {
    try {
      final res = await http.get(Uri.parse(ApiConfig.pediatres));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body);
      final list = data['pediatres'] as List;
      return list.map((e) => PediatreModel.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }
}
