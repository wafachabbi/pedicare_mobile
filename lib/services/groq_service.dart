import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Appel à l'API Groq (compatible OpenAI) — réponses très rapides
class GroqService {
  // Clé passée au lancement : --dart-define=GROQ_API_KEY=gsk_xxxx
  static const String _apiKey = String.fromEnvironment('GROQ_API_KEY');

  // Modèle modifiable au lancement : --dart-define=GROQ_MODEL=...
  static const String _model =
  String.fromEnvironment('GROQ_MODEL', defaultValue: 'llama-3.3-70b-versatile');

  static const String _url = 'https://api.groq.com/openai/v1/chat/completions';

  static bool get disponible => _apiKey.isNotEmpty;

  /// Retourne le texte généré, ou null en cas d'erreur (→ fallback local)
  static Future<String?> generer(
      String prompt, {
        double temperature = 0.6,
        int maxTokens = 600,
      }) async {
    debugPrint('🔑 GROQ : clé présente = $disponible, modèle = $_model');
    if (!disponible) return null;

    try {
      final res = await http
          .post(
        Uri.parse(_url),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'temperature': temperature,
          'max_tokens': maxTokens,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        }),
      )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) {
        debugPrint('❌ GROQ ERREUR ${res.statusCode} : ${res.body}');
        return null;
      }

      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final texte = (data['choices'][0]['message']['content'] as String?)?.trim();
      return (texte == null || texte.isEmpty) ? null : texte;
    } catch (e) {
      debugPrint('❌ GROQ ERREUR : $e');
      return null;
    }
  }
}