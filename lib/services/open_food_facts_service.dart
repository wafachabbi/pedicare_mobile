import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/nutrition_catalogue.dart';

/// Produit alimentaire issu d'Open Food Facts.
class ProduitAlimentaire {
  final String code;
  final String nom;
  final String marque;

  /// a, b, c, d, e ou vide si inconnu.
  final String nutriscore;

  /// Ids d'allergènes du catalogue PediCare (ex. « lait », « gluten »).
  final List<String> allergenes;

  const ProduitAlimentaire({
    required this.code,
    required this.nom,
    this.marque = '',
    this.nutriscore = '',
    this.allergenes = const [],
  });

  /// Texte ajouté au journal : « Nutella (Ferrero) — contient : lait, … ».
  String get libelleJournal {
    final base = marque.isEmpty ? nom : '$nom (${marque.split(',').first.trim()})';
    if (allergenes.isEmpty) return base;
    return '$base — contient : ${allergenes.map((a) => _nomsCourts[a] ?? a).join(', ')}';
  }

  /// Noms courts reconnus par la détection d'allergènes du journal. On évite
  /// « lait de vache », qui déclencherait à tort la règle « lait de vache en
  /// boisson avant 1 an » pour un simple yaourt.
  static const _nomsCourts = {
    'lait': 'lait',
    'oeuf': 'œuf',
    'arachide': 'arachide',
    'fruits_coque': 'fruits à coque',
    'gluten': 'gluten',
    'poisson': 'poisson',
    'crustaces': 'crustacés',
    'soja': 'soja',
    'sesame': 'sésame',
    'kiwi': 'kiwi',
  };

  /// Libellés lisibles des allergènes (pour l'affichage).
  List<String> get allergenesLibelles =>
      allergenes.map(libelleAllergene).toList();
}

/// Module 9 — Open Food Facts : informations et allergènes des produits.
///
/// API publique et gratuite (https://world.openfoodfacts.org). Nécessite
/// Internet ; en cas d'échec, une exception explicite est levée.
class OpenFoodFactsService {
  OpenFoodFactsService._();

  static const _base = 'https://world.openfoodfacts.org';
  static const _champs =
      'code,product_name,product_name_fr,brands,allergens_tags,nutriscore_grade';

  /// Open Food Facts demande un User-Agent identifiant l'application.
  static const _headers = {'User-Agent': 'PediCare/1.0 (application mobile, projet ESPRIT)'};

  /// Correspondance tags Open Food Facts → allergènes du catalogue PediCare.
  static const Map<String, String> correspondanceAllergenes = {
    'en:milk': 'lait',
    'en:eggs': 'oeuf',
    'en:peanuts': 'arachide',
    'en:nuts': 'fruits_coque',
    'en:gluten': 'gluten',
    'en:fish': 'poisson',
    'en:crustaceans': 'crustaces',
    'en:soybeans': 'soja',
    'en:sesame-seeds': 'sesame',
    'en:kiwi': 'kiwi',
  };

  /// Recherche par nom, ou par code-barres si [terme] est numérique.
  static Future<List<ProduitAlimentaire>> rechercher(String terme) async {
    final t = terme.trim();
    if (t.isEmpty) return const [];
    if (RegExp(r'^\d{8,14}$').hasMatch(t)) {
      final p = await parCodeBarres(t);
      return p == null ? const [] : [p];
    }
    final uri = Uri.parse('$_base/cgi/search.pl').replace(queryParameters: {
      'search_terms': t,
      'search_simple': '1',
      'action': 'process',
      'json': '1',
      'page_size': '20',
      'fields': _champs,
    });
    final res = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('Open Food Facts indisponible (${res.statusCode})');
    }
    return parserRecherche(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  static Future<ProduitAlimentaire?> parCodeBarres(String code) async {
    final uri = Uri.parse('$_base/api/v2/product/$code.json?fields=$_champs');
    final res = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) {
      throw Exception('Open Food Facts indisponible (${res.statusCode})');
    }
    final json = jsonDecode(utf8.decode(res.bodyBytes));
    if (json is! Map || json['status'] != 1 || json['product'] is! Map) {
      return null;
    }
    return parserProduit(json['product'] as Map);
  }

  // ── Analyse des réponses (logique pure, testable) ──

  static List<ProduitAlimentaire> parserRecherche(dynamic json) {
    if (json is! Map || json['products'] is! List) return const [];
    return (json['products'] as List)
        .whereType<Map>()
        .map(parserProduit)
        .whereType<ProduitAlimentaire>()
        .toList();
  }

  static ProduitAlimentaire? parserProduit(Map p) {
    final nom = ((p['product_name_fr'] ?? '').toString().trim().isNotEmpty
            ? p['product_name_fr']
            : p['product_name'])
        ?.toString()
        .trim();
    if (nom == null || nom.isEmpty) return null;
    final tags = (p['allergens_tags'] as List?)?.map((e) => e.toString()) ?? [];
    final allergenes = tags
        .map((t) => correspondanceAllergenes[t])
        .whereType<String>()
        .toSet()
        .toList();
    final score = (p['nutriscore_grade'] ?? '').toString().toLowerCase();
    return ProduitAlimentaire(
      code: (p['code'] ?? '').toString(),
      nom: nom,
      marque: (p['brands'] ?? '').toString().trim(),
      nutriscore: RegExp(r'^[a-e]$').hasMatch(score) ? score : '',
      allergenes: allergenes,
    );
  }
}
