import 'package:flutter/foundation.dart';
import '../data/symptomes_catalogue.dart';
import '../models/journal_symptome_model.dart';
import 'database_service.dart';

class JourJournal {
  final DateTime date;
  final int nbEntrees;
  final double? temperatureMoyenne;
  final double? temperatureMax;

  const JourJournal({
    required this.date,
    required this.nbEntrees,
    this.temperatureMoyenne,
    this.temperatureMax,
  });

  bool get fievre => temperatureMax != null && temperatureMax! >= 38.0;
}

class JournalStats {
  final int totalEntrees;
  final int entrees7Jours;
  final int joursRenseignes7Jours;
  final double? temperatureMoyenne7Jours;
  final double? temperatureMax7Jours;
  final int joursFievre7Jours;
  final String? symptomePrincipal;
  final int entrees30Jours;
  final int totalJoursFievre;
  final DateTime? derniereEntree;

  const JournalStats({
    required this.totalEntrees,
    required this.entrees7Jours,
    required this.joursRenseignes7Jours,
    this.temperatureMoyenne7Jours,
    this.temperatureMax7Jours,
    required this.joursFievre7Jours,
    this.symptomePrincipal,
    required this.entrees30Jours,
    required this.totalJoursFievre,
    this.derniereEntree,
  });

  double get couverture7Jours => (joursRenseignes7Jours / 7).clamp(0.0, 1.0);

  String get temperatureMoyenneLabel => temperatureMoyenne7Jours == null
      ? '—'
      : '${temperatureMoyenne7Jours!.toStringAsFixed(1)} °C';

  static const empty = JournalStats(
    totalEntrees: 0,
    entrees7Jours: 0,
    joursRenseignes7Jours: 0,
    joursFievre7Jours: 0,
    entrees30Jours: 0,
    totalJoursFievre: 0,
  );
}

class JournalSymptomeService {
  static const _table = 'journal_symptomes';

  // ── Lecture ────────────────────────────────────────────────────────────────
  static Future<List<JournalSymptomeModel>> getEntrees(
    String enfantId, {
    int? limit,
  }) async {
    try {
      final db = await DatabaseService.database;
      final rows = await db.query(
        _table,
        where: 'enfant_id = ?',
        whereArgs: [int.parse(enfantId)],
        orderBy: 'date DESC, id DESC',
        limit: limit,
      );
      return rows.map((e) => JournalSymptomeModel.fromMap(_normalize(e))).toList();
    } catch (e) {
      debugPrint('[Journal] getEntrees error: $e');
      return [];
    }
  }

  static Future<List<JournalSymptomeModel>> getEntreesPeriode(
    String enfantId,
    DateTime debut,
    DateTime fin,
  ) async {
    try {
      final db = await DatabaseService.database;
      final rows = await db.query(
        _table,
        where: 'enfant_id = ? AND date >= ? AND date <= ?',
        whereArgs: [
          int.parse(enfantId),
          _startOfDay(debut).toIso8601String(),
          _endOfDay(fin).toIso8601String(),
        ],
        orderBy: 'date DESC, id DESC',
      );
      return rows.map((e) => JournalSymptomeModel.fromMap(_normalize(e))).toList();
    } catch (e) {
      debugPrint('[Journal] getEntreesPeriode error: $e');
      return [];
    }
  }

  static Future<JournalSymptomeModel?> getDerniere(String enfantId) async {
    final list = await getEntrees(enfantId, limit: 1);
    return list.isEmpty ? null : list.first;
  }

  static Future<bool> aEntreeAujourdhui(String enfantId) async {
    try {
      final db = await DatabaseService.database;
      final debut = _startOfDay(DateTime.now()).toIso8601String();
      final fin = _endOfDay(DateTime.now()).toIso8601String();
      final rows = await db.query(
        _table,
        columns: ['id'],
        where: 'enfant_id = ? AND date >= ? AND date <= ?',
        whereArgs: [int.parse(enfantId), debut, fin],
        limit: 1,
      );
      return rows.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ── Écriture (CRUD) ────────────────────────────────────────────────────────
  static Future<String?> addEntree(JournalSymptomeModel entree) async {
    try {
      final db = await DatabaseService.database;
      final id = await db.insert(_table, entree.toDbMap());
      return id.toString();
    } catch (e) {
      debugPrint('[Journal] addEntree error: $e');
      return null;
    }
  }

  static Future<bool> updateEntree(JournalSymptomeModel entree) async {
    try {
      final db = await DatabaseService.database;
      final count = await db.update(
        _table,
        entree.toDbMap(),
        where: 'id = ?',
        whereArgs: [int.parse(entree.id)],
      );
      return count > 0;
    } catch (e) {
      debugPrint('[Journal] updateEntree error: $e');
      return false;
    }
  }

  static Future<bool> deleteEntree(String id) async {
    try {
      final db = await DatabaseService.database;
      final count = await db.delete(
        _table,
        where: 'id = ?',
        whereArgs: [int.parse(id)],
      );
      return count > 0;
    } catch (e) {
      debugPrint('[Journal] deleteEntree error: $e');
      return false;
    }
  }

  // ── Agrégations (dashboard + statistiques) ────────────────────────────────
  static Future<JournalStats> getStatistiques(
    String enfantId, {
    List<JournalSymptomeModel>? entrees,
  }) async {
    final all = entrees ?? await getEntrees(enfantId);
    if (all.isEmpty) return JournalStats.empty;

    final now = DateTime.now();
    final debut7 = _startOfDay(now.subtract(const Duration(days: 6)));
    final debut30 = _startOfDay(now.subtract(const Duration(days: 29)));

    final last7 = all.where((e) => !e.date.isBefore(debut7)).toList();
    final last30 = all.where((e) => !e.date.isBefore(debut30)).toList();

    final temperatures7 = last7
        .map((e) => e.temperature)
        .whereType<double>()
        .toList(growable: false);
    final joursRenseignes = last7.map((e) => _dateKey(e.date)).toSet();
    final joursFievre = last7
        .where((e) => e.fievre)
        .map((e) => _dateKey(e.date))
        .toSet();
    final joursFievreTotal =
        all.where((e) => e.fievre).map((e) => _dateKey(e.date)).toSet();

    final frequence = <String, int>{};
    for (final e in last7) {
      for (final id in e.symptomes) {
        frequence[id] = (frequence[id] ?? 0) + 1;
      }
    }
    String? principal;
    if (frequence.isNotEmpty) {
      principal = frequence.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
    }

    return JournalStats(
      totalEntrees: all.length,
      entrees7Jours: last7.length,
      joursRenseignes7Jours: joursRenseignes.length,
      temperatureMoyenne7Jours: temperatures7.isEmpty
          ? null
          : temperatures7.reduce((a, b) => a + b) / temperatures7.length,
      temperatureMax7Jours: temperatures7.isEmpty
          ? null
          : temperatures7.reduce((a, b) => a > b ? a : b),
      joursFievre7Jours: joursFievre.length,
      symptomePrincipal:
          principal == null ? null : SymptomesCatalogue.labelDe(principal),
      entrees30Jours: last30.length,
      totalJoursFievre: joursFievreTotal.length,
      derniereEntree: all.first.date,
    );
  }

  static Future<List<JourJournal>> getSerieJournaliere(
    String enfantId, {
    int jours = 14,
    List<JournalSymptomeModel>? entrees,
  }) async {
    final all = entrees ?? await getEntrees(enfantId);
    final now = DateTime.now();
    final debut = _startOfDay(now.subtract(Duration(days: jours - 1)));
    final map = <String, List<JournalSymptomeModel>>{};
    for (final e in all) {
      if (e.date.isBefore(debut)) continue;
      map.putIfAbsent(_dateKey(e.date), () => []).add(e);
    }

    return List.generate(jours, (i) {
      final jour = debut.add(Duration(days: i));
      final cles = map[_dateKey(jour)] ?? const <JournalSymptomeModel>[];
      final temps =
          cles.map((e) => e.temperature).whereType<double>().toList();
      return JourJournal(
        date: jour,
        nbEntrees: cles.length,
        temperatureMoyenne: temps.isEmpty
            ? null
            : temps.reduce((a, b) => a + b) / temps.length,
        temperatureMax:
            temps.isEmpty ? null : temps.reduce((a, b) => a > b ? a : b),
      );
    });
  }

  static Future<Map<String, int>> getFrequenceSymptomes(
    String enfantId, {
    int jours = 30,
    List<JournalSymptomeModel>? entrees,
  }) async {
    final all = entrees ?? await getEntrees(enfantId);
    final debut = _startOfDay(DateTime.now().subtract(Duration(days: jours - 1)));
    final frequence = <String, int>{};
    for (final e in all) {
      if (e.date.isBefore(debut)) continue;
      for (final id in e.symptomes) {
        frequence[id] = (frequence[id] ?? 0) + 1;
      }
    }
    return frequence;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  static Map<String, dynamic> _normalize(Map<String, dynamic> e) => {
        'id': e['id']?.toString() ?? '',
        'enfantId': e['enfant_id']?.toString() ?? '',
        'date': e['date'],
        'temperature': e['temperature'],
        'toux': e['toux'],
        'comportement': e['comportement'],
        'sommeil': e['sommeil'],
        'appetit': e['appetit'],
        'symptomes': e['symptomes'],
        'notes': e['notes'] ?? '',
        'createdAt': e['created_at'],
      };

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
