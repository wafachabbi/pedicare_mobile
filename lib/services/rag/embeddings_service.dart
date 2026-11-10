import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import '../database_service.dart';
import '../gemini_service.dart';
import 'base_connaissances.dart';

/// Recherche sémantique optionnelle (embeddings Gemini) pour le RAG.
///
/// Utilisée seulement si une clé Gemini est configurée. Les vecteurs des
/// passages sont calculés une fois puis mis en cache dans SQLite
/// (table rag_embeddings). Sans clé ou sans réseau, le RAG reste en BM25 seul.
class EmbeddingsService {
  EmbeddingsService._();

  /// Modèles essayés dans l'ordre (Google retire régulièrement des modèles).
  static const modeles = ['gemini-embedding-001', 'text-embedding-004'];

  static String? _modeleActif;
  static Map<String, List<double>>? _cache;
  static bool _indisponible = false;

  static bool get disponible => GeminiService.configuree && !_indisponible;

  /// Similarité cosinus entre deux vecteurs.
  static double cosinus(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0;
    var p = 0.0, na = 0.0, nb = 0.0;
    for (var i = 0; i < a.length; i++) {
      p += a[i] * b[i];
      na += a[i] * a[i];
      nb += b[i] * b[i];
    }
    if (na == 0 || nb == 0) return 0;
    return p / (math.sqrt(na) * math.sqrt(nb));
  }

  /// Similarité de la question avec chaque passage, ou null si indisponible.
  static Future<List<double>?> similarites(
      String question, List<Passage> passages) async {
    if (!disponible) return null;
    try {
      final vecteurs = await _vecteursPassages(passages);
      if (vecteurs == null) return null;
      final q = await _embedder([question], TaskType.retrievalQuery);
      if (q == null || q.isEmpty) return null;
      return [
        for (final p in passages)
          vecteurs[p.id] == null ? 0.0 : cosinus(q.first, vecteurs[p.id]!),
      ];
    } catch (e) {
      debugPrint('[RAG] embeddings indisponibles : $e');
      return null;
    }
  }

  /// Empreinte d'un passage : si son texte change, le vecteur est recalculé.
  static String empreinte(Passage p) =>
      p.texteIndexe.hashCode.toUnsigned(32).toRadixString(16);

  static Future<Map<String, List<double>>?> _vecteursPassages(
      List<Passage> passages) async {
    final db = await DatabaseService.database;
    if (_cache == null) {
      final rows = await db.query('rag_embeddings');
      _cache = {};
      final attendu = {for (final p in passages) p.id: empreinte(p)};
      for (final r in rows) {
        final id = r['passage_id'] as String;
        if (attendu[id] != r['empreinte']) continue; // passage modifié
        _cache![id] = (jsonDecode(r['vecteur'] as String) as List)
            .map((e) => (e as num).toDouble())
            .toList();
      }
    }
    final manquants = passages.where((p) => !_cache!.containsKey(p.id)).toList();
    for (var i = 0; i < manquants.length; i += 100) {
      final lot = manquants.sublist(i, math.min(i + 100, manquants.length));
      final v = await _embedder(
          lot.map((p) => p.texteIndexe).toList(), TaskType.retrievalDocument);
      if (v == null || v.length != lot.length) return null;
      final batch = db.batch();
      for (var j = 0; j < lot.length; j++) {
        _cache![lot[j].id] = v[j];
        batch.insert(
          'rag_embeddings',
          {
            'passage_id': lot[j].id,
            'modele': _modeleActif,
            'empreinte': empreinte(lot[j]),
            'vecteur': jsonEncode(v[j]),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true, continueOnError: true);
    }
    return _cache;
  }

  static Future<List<List<double>>?> _embedder(
      List<String> textes, TaskType type) async {
    final candidats = [?_modeleActif, ...modeles.where((m) => m != _modeleActif)];
    for (final nom in candidats) {
      try {
        final model = GenerativeModel(model: nom, apiKey: GeminiService.apiKey);
        final res = await model
            .batchEmbedContents([
              for (final t in textes)
                EmbedContentRequest(Content.text(t), taskType: type),
            ])
            .timeout(const Duration(seconds: 30));
        final vecteurs = res.embeddings.map((e) => e.values).toList();
        if (vecteurs.length == textes.length) {
          _modeleActif = nom;
          return vecteurs;
        }
      } catch (_) {
        // Modèle indisponible : on essaie le suivant.
      }
    }
    _indisponible = true; // évite de réessayer à chaque question
    return null;
  }
}
