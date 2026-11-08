import 'dart:developer' as dev;
import '../models/activite_model.dart';
import 'database_service.dart';

/// Un badge obtenu ou à obtenir
class BadgeInfo {
  final String code;
  final String titre;
  final String emoji;
  final String description;
  const BadgeInfo(this.code, this.titre, this.emoji, this.description);
}

class EveilService {
  // ── Badges disponibles ────────────────────────────────────────────────────
  static const List<BadgeInfo> badges = [
    BadgeInfo('premier_jeu', 'Premier pas', '🌱', 'Terminer un premier jeu'),
    BadgeInfo('assidu', 'Assidu', '🔥', 'Terminer 5 jeux'),
    BadgeInfo('explorateur', 'Explorateur', '🧭', 'Jouer dans 3 catégories différentes'),
    BadgeInfo('champion', 'Champion', '🏆', 'Obtenir un score de 100 %'),
  ];

  /// Âge en mois à partir de la date de naissance
  static int ageEnMois(DateTime dateNaissance) {
    final now = DateTime.now();
    int mois = (now.year - dateNaissance.year) * 12 + (now.month - dateNaissance.month);
    if (now.day < dateNaissance.day) mois--;
    return mois < 0 ? 0 : mois;
  }

  // ── Activités ─────────────────────────────────────────────────────────────
  /// Activités adaptées à l'âge (option : filtrer par catégorie)
  static Future<List<ActiviteModel>> getActivitesPourAge(int ageMois, {String? categorie}) async {
    try {
      final db = await DatabaseService.database;
      final where = StringBuffer('age_min_mois <= ? AND age_max_mois >= ?');
      final args = <Object>[ageMois, ageMois];
      if (categorie != null) {
        where.write(' AND categorie = ?');
        args.add(categorie);
      }
      final rows = await db.query('activites',
          where: where.toString(), whereArgs: args, orderBy: 'categorie, titre');
      return rows.map((e) => ActiviteModel.fromMap(e)).toList();
    } catch (e) {
      dev.log('getActivitesPourAge error: $e');
      return [];
    }
  }

  // ── Séances ───────────────────────────────────────────────────────────────
  /// Enregistre une séance et renvoie la liste des NOUVEAUX badges obtenus
  static Future<List<BadgeInfo>> enregistrerSeance({
    required String enfantId,
    required int activiteId,
    required int score,
    required int dureeSec,
  }) async {
    try {
      final db = await DatabaseService.database;
      await db.insert('seances_jeu', {
        'enfant_id': int.parse(enfantId),
        'activite_id': activiteId,
        'score': score,
        'duree_sec': dureeSec,
      });
      return await _verifierBadges(enfantId);
    } catch (e) {
      dev.log('enregistrerSeance error: $e');
      return [];
    }
  }

  /// Historique des séances d'un enfant (avec titre et catégorie de l'activité)
  static Future<List<Map<String, dynamic>>> getHistorique(String enfantId) async {
    final db = await DatabaseService.database;
    return db.rawQuery('''
      SELECT s.*, a.titre, a.categorie
      FROM seances_jeu s
      JOIN activites a ON a.id = s.activite_id
      WHERE s.enfant_id = ?
      ORDER BY s.created_at DESC
    ''', [int.parse(enfantId)]);
  }

  /// Statistiques par catégorie : nb de séances, score moyen, temps total
  static Future<Map<String, Map<String, num>>> getStatsParCategorie(String enfantId) async {
    final db = await DatabaseService.database;
    final rows = await db.rawQuery('''
      SELECT a.categorie,
             COUNT(*)         AS nb,
             AVG(s.score)     AS score_moyen,
             SUM(s.duree_sec) AS duree_totale
      FROM seances_jeu s
      JOIN activites a ON a.id = s.activite_id
      WHERE s.enfant_id = ?
      GROUP BY a.categorie
    ''', [int.parse(enfantId)]);
    return {
      for (final r in rows)
        r['categorie'] as String: {
          'nb': r['nb'] as int,
          'score_moyen': (r['score_moyen'] as num?) ?? 0,
          'duree_totale': (r['duree_totale'] as num?) ?? 0,
        }
    };
  }

  // ── Favoris ───────────────────────────────────────────────────────────────
  static Future<Set<int>> getFavoris(String enfantId) async {
    final db = await DatabaseService.database;
    final rows = await db.query('favoris',
        where: 'enfant_id = ?', whereArgs: [int.parse(enfantId)]);
    return rows.map((r) => r['activite_id'] as int).toSet();
  }

  /// Ajoute ou retire des favoris. Renvoie true si l'activité est maintenant favorite.
  static Future<bool> toggleFavori(String enfantId, int activiteId) async {
    final db = await DatabaseService.database;
    final eid = int.parse(enfantId);
    final deleted = await db.delete('favoris',
        where: 'enfant_id = ? AND activite_id = ?', whereArgs: [eid, activiteId]);
    if (deleted > 0) return false;
    await db.insert('favoris', {'enfant_id': eid, 'activite_id': activiteId});
    return true;
  }

  // ── Badges ────────────────────────────────────────────────────────────────
  static Future<Set<String>> getBadgesObtenus(String enfantId) async {
    final db = await DatabaseService.database;
    final rows = await db.query('badges_enfant',
        where: 'enfant_id = ?', whereArgs: [int.parse(enfantId)]);
    return rows.map((r) => r['code_badge'] as String).toSet();
  }

  static Future<List<BadgeInfo>> _verifierBadges(String enfantId) async {
    final db = await DatabaseService.database;
    final eid = int.parse(enfantId);
    final dejaObtenus = await getBadgesObtenus(enfantId);

    final nbSeances = (await db.rawQuery(
        'SELECT COUNT(*) AS n FROM seances_jeu WHERE enfant_id = ?', [eid])).first['n'] as int;
    final nbCategories = (await db.rawQuery('''
        SELECT COUNT(DISTINCT a.categorie) AS n
        FROM seances_jeu s JOIN activites a ON a.id = s.activite_id
        WHERE s.enfant_id = ?''', [eid])).first['n'] as int;
    final scoreMax = (await db.rawQuery(
        'SELECT MAX(score) AS m FROM seances_jeu WHERE enfant_id = ?', [eid])).first['m'] as int? ?? 0;

    final conditions = {
      'premier_jeu': nbSeances >= 1,
      'assidu': nbSeances >= 5,
      'explorateur': nbCategories >= 3,
      'champion': scoreMax >= 100,
    };

    final nouveaux = <BadgeInfo>[];
    for (final b in badges) {
      if (conditions[b.code] == true && !dejaObtenus.contains(b.code)) {
        await db.insert('badges_enfant', {'enfant_id': eid, 'code_badge': b.code});
        nouveaux.add(b);
      }
    }
    return nouveaux;
  }
}