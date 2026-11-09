import 'package:flutter/foundation.dart';
import '../data/nutrition_catalogue.dart';
import '../models/nutrition_models.dart';
import 'database_service.dart';

/// Module 9 — Nutrition : alertes aliments, recettes, allergies, allaitement.
class NutritionService {
  NutritionService._();

  // ══ Logique pure (sans base de données, testable) ═════════════════════════

  /// Âge en mois révolus à la date [le] (aujourd'hui par défaut).
  static int ageEnMois(DateTime naissance, {DateTime? le}) {
    final ref = le ?? DateTime.now();
    var mois = (ref.year - naissance.year) * 12 + ref.month - naissance.month;
    if (ref.day < naissance.day) mois--;
    return mois < 0 ? 0 : mois;
  }

  /// Minuscules, sans accents ni ponctuation, espaces simples.
  static String normaliser(String texte) {
    const accents = {
      'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ç': 'c', 'é': 'e', 'è': 'e',
      'ê': 'e', 'ë': 'e', 'î': 'i', 'ï': 'i', 'í': 'i', 'ô': 'o', 'ö': 'o',
      'ó': 'o', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u', 'œ': 'oe', 'æ': 'ae',
    };
    final buffer = StringBuffer();
    for (final ch in texte.toLowerCase().split('')) {
      buffer.write(accents[ch] ?? ch);
    }
    return buffer
        .toString()
        .replaceAll(RegExp(r"[^a-z0-9 ]"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Retire les négations simples (« sans sucre », « sans sel »).
  static String _sansNegations(String texteNormalise) =>
      texteNormalise.replaceAll(RegExp(r'\bsans [a-z]+'), ' ');

  static bool _contient(String texte, String motCle) =>
      RegExp('\\b${RegExp.escape(motCle)}s?\\b').hasMatch(texte);

  /// Allergènes du catalogue présents dans [texte].
  static List<Allergene> allergenesDetectes(String texte) {
    final base = _sansNegations(normaliser(texte));
    final trouves = <Allergene>[];
    for (final a in allergenesCatalogue) {
      var t = base;
      for (final ex in a.exclusions) {
        t = t.replaceAll(ex, ' ');
      }
      if (a.motsCles.any((m) => _contient(t, m))) trouves.add(a);
    }
    return trouves;
  }

  /// Ids d'allergènes du catalogue correspondant aux allergies connues de
  /// l'enfant : allergies enregistrées + champ libre « allergies » du profil.
  static Set<String> allergenesEnfant(
    List<AllergieAlimentaireModel> allergies, {
    String? allergiesProfil,
  }) {
    final ids = <String>{};
    for (final a in allergies) {
      if (allergeneParId(a.allergene) != null) {
        ids.add(a.allergene);
      } else {
        ids.addAll(allergenesDetectes(a.allergene).map((x) => x.id));
      }
    }
    if (allergiesProfil != null && allergiesProfil.trim().isNotEmpty) {
      ids.addAll(allergenesDetectes(allergiesProfil).map((x) => x.id));
    }
    return ids;
  }

  /// Vérifie un repas saisi : allergies de l'enfant et aliments déconseillés
  /// à son âge. [solide] = repas autre qu'un biberon/tétée.
  static List<AlerteAliment> verifierRepas({
    required String aliments,
    required int ageMois,
    Set<String> allergenesConnus = const {},
    bool solide = true,
  }) {
    final alertes = <AlerteAliment>[];
    final texte = _sansNegations(normaliser(aliments));
    if (texte.isEmpty) return alertes;

    for (final a in allergenesDetectes(aliments)) {
      if (allergenesConnus.contains(a.id)) {
        alertes.add(AlerteAliment(
          niveau: NiveauAlerteAliment.danger,
          titre: '${a.emoji} Allergie : ${a.label}',
          message: 'Ce repas semble contenir un aliment auquel l\'enfant '
              'est allergique.',
        ));
      }
    }

    if (solide && ageMois < ageDiversificationMinMois) {
      alertes.add(const AlerteAliment(
        niveau: NiveauAlerteAliment.attention,
        titre: '🍼 Diversification précoce',
        message: 'Avant 4 mois, l\'alimentation est en principe '
            'exclusivement lactée. Parlez-en à votre pédiatre.',
      ));
    }

    for (final r in reglesAge) {
      if (ageMois >= r.ageMinMois) continue;
      if (r.motsCles.any((m) => _contient(texte, m))) {
        alertes.add(AlerteAliment(
          niveau: r.danger
              ? NiveauAlerteAliment.danger
              : NiveauAlerteAliment.attention,
          titre: '${r.danger ? '⛔' : '⚠️'} ${r.aliment}',
          message: r.raison,
        ));
      }
    }
    return alertes;
  }

  /// Recettes adaptées à l'âge, sans les allergènes de l'enfant.
  /// Retourne (recettes adaptées, nombre de recettes masquées pour allergie).
  static (List<Recette>, int) recettesAdaptees({
    required int ageMois,
    required Set<String> allergenesConnus,
  }) {
    final pourAge =
        recettesCatalogue.where((r) => r.ageMinMois <= ageMois).toList();
    final ok = pourAge
        .where((r) => !r.allergenes.any(allergenesConnus.contains))
        .toList();
    return (ok, pourAge.length - ok.length);
  }

  // ══ Allergies alimentaires (SQLite) ═══════════════════════════════════════

  static Future<List<AllergieAlimentaireModel>> getAllergies(
      String enfantId) async {
    try {
      final db = await DatabaseService.database;
      final rows = await db.query('allergies_alimentaires',
          where: 'enfant_id = ?',
          whereArgs: [int.parse(enfantId)],
          orderBy: 'id DESC');
      return rows.map(AllergieAlimentaireModel.fromMap).toList();
    } catch (e) {
      debugPrint('[Nutrition] getAllergies error: $e');
      return [];
    }
  }

  static Future<bool> addAllergie(AllergieAlimentaireModel a) async {
    try {
      final db = await DatabaseService.database;
      await db.insert('allergies_alimentaires', a.toDbMap());
      return true;
    } catch (e) {
      debugPrint('[Nutrition] addAllergie error: $e');
      return false;
    }
  }

  static Future<bool> deleteAllergie(String id) async {
    try {
      final db = await DatabaseService.database;
      return await db.delete('allergies_alimentaires',
              where: 'id = ?', whereArgs: [int.parse(id)]) >
          0;
    } catch (e) {
      debugPrint('[Nutrition] deleteAllergie error: $e');
      return false;
    }
  }

  // ══ Consignes du pédiatre (SQLite) ═════════════════════════════════════════

  static Future<List<ConseilNutritionModel>> getConseils(String enfantId) async {
    try {
      final db = await DatabaseService.database;
      final rows = await db.query('conseils_nutrition',
          where: 'enfant_id = ?',
          whereArgs: [int.parse(enfantId)],
          orderBy: 'created_at DESC, id DESC');
      return rows.map(ConseilNutritionModel.fromMap).toList();
    } catch (e) {
      debugPrint('[Nutrition] getConseils error: $e');
      return [];
    }
  }

  static Future<bool> addConseil(ConseilNutritionModel c) async {
    try {
      final db = await DatabaseService.database;
      await db.insert('conseils_nutrition', c.toDbMap());
      return true;
    } catch (e) {
      debugPrint('[Nutrition] addConseil error: $e');
      return false;
    }
  }

  static Future<bool> deleteConseil(String id) async {
    try {
      final db = await DatabaseService.database;
      return await db.delete('conseils_nutrition',
              where: 'id = ?', whereArgs: [int.parse(id)]) >
          0;
    } catch (e) {
      debugPrint('[Nutrition] deleteConseil error: $e');
      return false;
    }
  }

  // ══ Allaitement (SQLite) ══════════════════════════════════════════════════

  static Future<List<AllaitementModel>> getAllaitements(String enfantId,
      {int jours = 7}) async {
    try {
      final db = await DatabaseService.database;
      final now = DateTime.now();
      final debut = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: jours - 1));
      final rows = await db.query('allaitements',
          where: 'enfant_id = ? AND date >= ?',
          whereArgs: [int.parse(enfantId), debut.toIso8601String()],
          orderBy: 'date DESC');
      return rows.map(AllaitementModel.fromMap).toList();
    } catch (e) {
      debugPrint('[Nutrition] getAllaitements error: $e');
      return [];
    }
  }

  static Future<bool> saveAllaitement(AllaitementModel a) async {
    try {
      final db = await DatabaseService.database;
      if (a.id.isEmpty) {
        await db.insert('allaitements', a.toDbMap());
      } else {
        await db.update('allaitements', a.toDbMap(),
            where: 'id = ?', whereArgs: [int.parse(a.id)]);
      }
      return true;
    } catch (e) {
      debugPrint('[Nutrition] saveAllaitement error: $e');
      return false;
    }
  }

  static Future<bool> deleteAllaitement(String id) async {
    try {
      final db = await DatabaseService.database;
      return await db.delete('allaitements',
              where: 'id = ?', whereArgs: [int.parse(id)]) >
          0;
    } catch (e) {
      debugPrint('[Nutrition] deleteAllaitement error: $e');
      return false;
    }
  }
}
