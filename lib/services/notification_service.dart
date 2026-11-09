import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/enfant_model.dart';
import '../models/vaccin_model.dart';
import '../models/rendezvous_model.dart';
import '../models/traitement_model.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // ── Initialisation ────────────────────────────────────────────────────────
  static Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Tunis'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Demander la permission sur Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  // ── Canal Android ─────────────────────────────────────────────────────────
  static NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          'pedicare_channel',
          'PediCare Rappels',
          channelDescription: 'Rappels vaccins et rendez-vous',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF1E6FDB),
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  // ── Planifier rappels vaccins ─────────────────────────────────────────────
  static Future<void> planifierRappelsVaccins(
      List<VaccinModel> vaccins, String enfantPrenom) async {
    await init();

    for (final vaccin in vaccins) {
      if (vaccin.prochaineDate == null) continue;
      final date = vaccin.prochaineDate!;

      // Rappel J-7
      await _planifierSi(
        id: _hashId('vaccin_7_${vaccin.id}'),
        titre: '💉 Rappel vaccin — $enfantPrenom',
        corps: '${vaccin.nom} dans 7 jours (${_fmt(date)})',
        date: date.subtract(const Duration(days: 7)),
      );

      // Rappel J-1
      await _planifierSi(
        id: _hashId('vaccin_1_${vaccin.id}'),
        titre: '⚠️ Vaccin demain — $enfantPrenom',
        corps: '${vaccin.nom} prévu demain. N\'oubliez pas !',
        date: date.subtract(const Duration(days: 1)),
      );

      // Rappel jour J
      await _planifierSi(
        id: _hashId('vaccin_0_${vaccin.id}'),
        titre: '🚨 Vaccin aujourd\'hui — $enfantPrenom',
        corps: '${vaccin.nom} est prévu aujourd\'hui !',
        date: date,
      );
    }
  }

  // ── Planifier rappels rendez-vous ─────────────────────────────────────────
  static Future<void> planifierRappelsRDV(
      List<RendezVousModel> rdvs, String enfantPrenom) async {
    await init();

    for (final rdv in rdvs) {
      if (rdv.statut == StatutRDV.annule) continue;
      final date = rdv.dateHeure;

      // Rappel J-1
      await _planifierSi(
        id: _hashId('rdv_1_${rdv.id}'),
        titre: '📅 RDV demain — $enfantPrenom',
        corps: '${rdv.titre} avec Dr. ${rdv.medecin} demain à ${_heure(date)}',
        date: date.subtract(const Duration(days: 1)),
      );

      // Rappel 2h avant
      await _planifierSi(
        id: _hashId('rdv_2h_${rdv.id}'),
        titre: '🏥 RDV dans 2h — $enfantPrenom',
        corps: '${rdv.titre} à ${_heure(date)} — ${rdv.lieu}',
        date: date.subtract(const Duration(hours: 2)),
      );
    }
  }

  // ── Annuler les rappels d'un RDV ──────────────────────────────────────────
  static Future<void> annulerRappelsRDV(String rdvId) async {
    await _plugin.cancel(_hashId('rdv_1_$rdvId'));
    await _plugin.cancel(_hashId('rdv_2h_$rdvId'));
  }

  // ── Annuler les rappels d'un vaccin ──────────────────────────────────────
  static Future<void> annulerRappelsVaccin(String vaccinId) async {
    await _plugin.cancel(_hashId('vaccin_7_$vaccinId'));
    await _plugin.cancel(_hashId('vaccin_1_$vaccinId'));
    await _plugin.cancel(_hashId('vaccin_0_$vaccinId'));
  }

  // ── Tout annuler ──────────────────────────────────────────────────────────
  static Future<void> annulerTout() async {
    await _plugin.cancelAll();
  }

  // ── Rappel quotidien du journal des symptômes (Module 10) ─────────────────
  static const String _journalBaseId = 'journal_quotidien';
  static const String _journalTitre = '📝 Journal de santé du jour';

  static int _journalNotifId(String? enfantId) =>
      _hashId(enfantId == null || enfantId.isEmpty
          ? _journalBaseId
          : '${_journalBaseId}_$enfantId');

  /// Planifie un rappel quotidien. Si [enfantId] est fourni, un rappel
  /// distinct est créé pour cet enfant ; sinon un rappel global est utilisé.
  static Future<void> planifierRappelJournalQuotidien({
    int heure = 20,
    int minute = 0,
    String? enfantId,
    String? enfantNom,
  }) async {
    await init();

    final now = DateTime.now();
    var prochain = DateTime(now.year, now.month, now.day, heure, minute);
    if (!prochain.isAfter(now)) {
      prochain = prochain.add(const Duration(days: 1));
    }

    final tzDate = tz.TZDateTime.from(prochain, tz.local);
    final id = _journalNotifId(enfantId);
    final nom = (enfantNom == null || enfantNom.trim().isEmpty)
        ? 'votre enfant'
        : enfantNom.trim();
    final corps =
        'Prenez une minute pour noter les symptômes et le comportement de $nom.';

    try {
      await _plugin.zonedSchedule(
        id,
        _journalTitre,
        corps,
        tzDate,
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      await _plugin.zonedSchedule(
        id,
        _journalTitre,
        corps,
        tzDate,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  /// Planifie un rappel par enfant (un créneau quotidien commun).
  static Future<void> planifierRappelsJournalEnfants(
    List<EnfantModel> enfants, {
    int heure = 20,
    int minute = 0,
  }) async {
    if (enfants.isEmpty) {
      await planifierRappelJournalQuotidien(heure: heure, minute: minute);
      return;
    }
    for (final enfant in enfants) {
      await planifierRappelJournalQuotidien(
        heure: heure,
        minute: minute,
        enfantId: enfant.id,
        enfantNom: enfant.nomComplet,
      );
    }
  }

  static Future<void> annulerRappelJournalQuotidien({String? enfantId}) async {
    await _plugin.cancel(_journalNotifId(enfantId));
  }

  // ── Rappels de prise de médicament (Module 5 — PediPharma) ────────────────
  /// Nombre maximum d'heures de prise par traitement (pour l'annulation).
  static const int maxHeuresParTraitement = 8;

  static int _traitementNotifId(String traitementId, int index) =>
      _hashId('traitement_${traitementId}_$index');

  /// Un rappel quotidien par heure de prise. Le premier rappel tombe au plus
  /// tôt le jour de début. Les rappels sont annulés à la fin du traitement
  /// par [TraitementService.synchroniserRappels].
  static Future<void> planifierRappelsTraitement(
      TraitementModel t, String enfantPrenom) async {
    await init();
    await annulerRappelsTraitement(t.id);

    final now = DateTime.now();
    final debut = DateTime(t.dateDebut.year, t.dateDebut.month, t.dateDebut.day);
    final pour = enfantPrenom.trim().isEmpty ? '' : ' — ${enfantPrenom.trim()}';
    final corps = [
      t.nom,
      if (t.posologie.isNotEmpty) t.posologie,
    ].join(' · ');

    final heures = t.heures.take(maxHeuresParTraitement).toList();
    for (var i = 0; i < heures.length; i++) {
      final p = heures[i].split(':');
      var prochain = DateTime(
          now.year, now.month, now.day, int.parse(p[0]), int.parse(p[1]));
      if (prochain.isBefore(debut)) {
        prochain = DateTime(debut.year, debut.month, debut.day,
            int.parse(p[0]), int.parse(p[1]));
      }
      if (!prochain.isAfter(now)) {
        prochain = prochain.add(const Duration(days: 1));
      }
      if (!t.couvreLeJour(prochain)) continue;

      await _planifierQuotidien(
        id: _traitementNotifId(t.id, i),
        titre: '💊 Médicament à donner$pour',
        corps: '$corps (${heures[i]}). Ouvrez PediPharma pour confirmer.',
        date: prochain,
      );
    }
  }

  static Future<void> annulerRappelsTraitement(String traitementId) async {
    for (var i = 0; i < maxHeuresParTraitement; i++) {
      await _plugin.cancel(_traitementNotifId(traitementId, i));
    }
    await annulerReportPrise(traitementId);
  }

  /// Rappel unique après un report de prise.
  static Future<void> planifierReportPrise(
      TraitementModel t, String enfantPrenom, DateTime date) async {
    await init();
    final pour = enfantPrenom.trim().isEmpty ? '' : ' — ${enfantPrenom.trim()}';
    await _planifierSi(
      id: _hashId('traitement_report_${t.id}'),
      titre: '⏰ Prise reportée$pour',
      corps: 'Il est temps de donner ${t.nom}.',
      date: date,
    );
  }

  static Future<void> annulerReportPrise(String traitementId) async {
    await _plugin.cancel(_hashId('traitement_report_$traitementId'));
  }

  static Future<void> _planifierQuotidien({
    required int id,
    required String titre,
    required String corps,
    required DateTime date,
  }) async {
    final tzDate = tz.TZDateTime.from(date, tz.local);
    try {
      await _plugin.zonedSchedule(
        id,
        titre,
        corps,
        tzDate,
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      await _plugin.zonedSchedule(
        id,
        titre,
        corps,
        tzDate,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  // ── Notif immédiate de test ───────────────────────────────────────────────
  static Future<void> notifTest() async {
    await init();
    await _plugin.show(
      0,
      '🔔 PediCare — Test notifications',
      'Les rappels vaccins et RDV sont activés !',
      _details,
    );
  }

  // ── Helpers privés ────────────────────────────────────────────────────────
  static Future<void> _planifierSi({
    required int id,
    required String titre,
    required String corps,
    required DateTime date,
  }) async {
    if (date.isBefore(DateTime.now())) return; // date passée, on skip

    final tzDate = tz.TZDateTime.from(date, tz.local);
    try {
      await _plugin.zonedSchedule(
        id,
        titre,
        corps,
        tzDate,
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      await _plugin.zonedSchedule(
        id,
        titre,
        corps,
        tzDate,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static int _hashId(String key) => key.hashCode.abs() % 100000;

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _heure(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';
}
