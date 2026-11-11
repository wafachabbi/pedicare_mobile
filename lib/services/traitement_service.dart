import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../models/prise_medicament_model.dart';
import '../models/traitement_model.dart';
import 'database_service.dart';
import 'notification_service.dart';

/// Module 5 — PediPharma : traitements, prises et rappels.
class TraitementService {
  static const _table = 'traitements';
  static const _tablePrises = 'prises_medicament';

  // ══ Traitements ═══════════════════════════════════════════════════════════

  static Future<List<TraitementModel>> getTraitements(String enfantId) async {
    try {
      final db = await DatabaseService.database;
      final rows = await db.query(
        _table,
        where: 'enfant_id = ?',
        whereArgs: [int.parse(enfantId)],
        orderBy: 'date_debut DESC, id DESC',
      );
      return rows.map(TraitementModel.fromMap).toList();
    } catch (e) {
      debugPrint('[Traitement] getTraitements error: $e');
      return [];
    }
  }

  static Future<List<TraitementModel>> getActifs(String enfantId) async {
    final tous = await getTraitements(enfantId);
    return tous.where((t) => t.actif).toList();
  }

  /// Ajoute le traitement et programme ses rappels.
  /// [enfantPrenom] personnalise le texte des notifications.
  static Future<String?> addTraitement(TraitementModel traitement,
      {String enfantPrenom = ''}) async {
    try {
      final db = await DatabaseService.database;
      final id = (await db.insert(_table, traitement.toDbMap())).toString();
      await _replanifier(traitement.copyWith(id: id), enfantPrenom);
      return id;
    } catch (e) {
      debugPrint('[Traitement] addTraitement error: $e');
      return null;
    }
  }

  static Future<bool> updateTraitement(TraitementModel traitement,
      {String enfantPrenom = ''}) async {
    try {
      final db = await DatabaseService.database;
      final count = await db.update(
        _table,
        traitement.toDbMap(),
        where: 'id = ?',
        whereArgs: [int.parse(traitement.id)],
      );
      if (count > 0) await _replanifier(traitement, enfantPrenom);
      return count > 0;
    } catch (e) {
      debugPrint('[Traitement] updateTraitement error: $e');
      return false;
    }
  }

  /// Supprime le traitement, ses prises (cascade) et ses rappels.
  static Future<bool> deleteTraitement(String id) async {
    try {
      final db = await DatabaseService.database;
      final count = await db.delete(
        _table,
        where: 'id = ?',
        whereArgs: [int.parse(id)],
      );
      await _annulerRappels(id);
      return count > 0;
    } catch (e) {
      debugPrint('[Traitement] deleteTraitement error: $e');
      return false;
    }
  }

  /// Annule les rappels des traitements terminés et reprogramme les autres.
  /// À appeler au chargement de l'application / de l'écran PediPharma.
  static Future<void> synchroniserRappels(String enfantId,
      {String enfantPrenom = ''}) async {
    for (final t in await getTraitements(enfantId)) {
      await _replanifier(t, enfantPrenom);
    }
  }

  static Future<void> _replanifier(TraitementModel t, String prenom) async {
    try {
      if (t.rappels && t.actif && t.heures.isNotEmpty) {
        await NotificationService.planifierRappelsTraitement(t, prenom);
      } else {
        await NotificationService.annulerRappelsTraitement(t.id);
      }
    } catch (e) {
      // Les notifications ne doivent jamais bloquer l'enregistrement.
      debugPrint('[Traitement] rappels error: $e');
    }
  }

  static Future<void> _annulerRappels(String id) async {
    try {
      await NotificationService.annulerRappelsTraitement(id);
    } catch (e) {
      debugPrint('[Traitement] annulation rappels error: $e');
    }
  }

  // ══ Prises ════════════════════════════════════════════════════════════════

  /// Enregistre (ou remplace) le statut d'une dose.
  /// « Reporté » programme un nouveau rappel dans [delaiReport].
  static Future<bool> enregistrerPrise({
    required TraitementModel traitement,
    required DateTime datePrevue,
    required StatutPrise statut,
    String enfantPrenom = '',
    Duration delaiReport = const Duration(minutes: 30),
  }) async {
    try {
      final db = await DatabaseService.database;
      final prise = PriseMedicamentModel(
        id: '',
        traitementId: traitement.id,
        enfantId: traitement.enfantId,
        datePrevue: datePrevue,
        statut: statut,
        dateAction: DateTime.now(),
      );
      await db.insert(_tablePrises, prise.toDbMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      try {
        if (statut == StatutPrise.reporte) {
          await NotificationService.planifierReportPrise(
              traitement, enfantPrenom, DateTime.now().add(delaiReport));
        } else {
          await NotificationService.annulerReportPrise(traitement.id);
        }
      } catch (e) {
        debugPrint('[Traitement] report rappel error: $e');
      }
      return true;
    } catch (e) {
      debugPrint('[Traitement] enregistrerPrise error: $e');
      return false;
    }
  }

  /// Annule la confirmation d'une dose (retour à « à faire »).
  static Future<bool> annulerPrise(String priseId) async {
    try {
      final db = await DatabaseService.database;
      return await db.delete(_tablePrises,
              where: 'id = ?', whereArgs: [int.parse(priseId)]) >
          0;
    } catch (e) {
      debugPrint('[Traitement] annulerPrise error: $e');
      return false;
    }
  }

  /// Historique des prises d'un enfant ou d'un traitement (plus récent d'abord).
  static Future<List<PriseMedicamentModel>> getPrises({
    String? enfantId,
    String? traitementId,
    DateTime? depuis,
  }) async {
    try {
      final db = await DatabaseService.database;
      final where = <String>[];
      final args = <Object>[];
      if (enfantId != null) {
        where.add('p.enfant_id = ?');
        args.add(int.parse(enfantId));
      }
      if (traitementId != null) {
        where.add('p.traitement_id = ?');
        args.add(int.parse(traitementId));
      }
      if (depuis != null) {
        where.add('p.date_prevue >= ?');
        args.add(depuis.toIso8601String());
      }
      final rows = await db.rawQuery('''
        SELECT p.*, t.nom AS traitement_nom
        FROM $_tablePrises p
        JOIN $_table t ON t.id = p.traitement_id
        ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
        ORDER BY p.date_prevue DESC
      ''', args);
      return rows.map(PriseMedicamentModel.fromMap).toList();
    } catch (e) {
      debugPrint('[Traitement] getPrises error: $e');
      return [];
    }
  }

  /// Doses prévues aujourd'hui pour l'enfant, avec leur statut éventuel.
  static Future<List<DoseDuJour>> getDosesDuJour(String enfantId) async {
    final now = DateTime.now();
    final debutJour = DateTime(now.year, now.month, now.day);
    final traitements = await getTraitements(enfantId);
    final prises = await getPrises(enfantId: enfantId, depuis: debutJour);
    return dosesDuJour(traitements, prises, now);
  }

  /// Calcul pur des doses d'un jour (testable sans base de données).
  static List<DoseDuJour> dosesDuJour(
    List<TraitementModel> traitements,
    List<PriseMedicamentModel> prises,
    DateTime jour,
  ) {
    final doses = <DoseDuJour>[];
    for (final t in traitements) {
      if (!t.couvreLeJour(jour)) continue;
      for (final h in t.heures) {
        final p = h.split(':');
        final heure = DateTime(
            jour.year, jour.month, jour.day, int.parse(p[0]), int.parse(p[1]));
        PriseMedicamentModel? prise;
        for (final x in prises) {
          if (x.traitementId == t.id && x.datePrevue == heure) {
            prise = x;
            break;
          }
        }
        doses.add(DoseDuJour(traitement: t, heure: heure, prise: prise));
      }
    }
    doses.sort((a, b) => a.heure.compareTo(b.heure));
    return doses;
  }
}
