import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/vaccin_model.dart';
import '../models/rendezvous_model.dart';

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
