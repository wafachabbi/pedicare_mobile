import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import 'message_service.dart';

/// Notifications des nouveaux messages (prioritaires si urgents)
class MessageNotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  // Canal normal
  static const _detailsNormal = NotificationDetails(
    android: AndroidNotificationDetails(
      'pedicare_messages',
      'Messages',
      channelDescription: 'Nouveaux messages parent / pédiatre',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF1E6FDB),
    ),
  );

  // Canal URGENT (priorité maximale, vibration)
  static const _detailsUrgent = NotificationDetails(
    android: AndroidNotificationDetails(
      'pedicare_messages_urgents',
      'Messages urgents',
      channelDescription: 'Messages détectés comme urgents par l\'IA',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFFF6B6B),
      enableVibration: true,
      category: AndroidNotificationCategory.message,
    ),
  );

  /// Vérifie les nouveaux messages reçus et affiche une notification.
  /// Retourne le nombre total de messages non lus (pour le badge).
  static Future<int> verifier(String userId) async {
    try {
      final db = await DatabaseService.database;
      final me = int.parse(userId);
      final prefs = await SharedPreferences.getInstance();
      final cle = 'dernier_msg_notifie_$userId';
      final dernierId = prefs.getInt(cle) ?? 0;

      // Nouveaux messages non lus, jamais notifiés
      final rows = await db.rawQuery('''
        SELECT m.id, m.content, m.type, u.name AS sender_name, u.role AS sender_role
        FROM messages m
        JOIN users u ON u.id = m.sender_id
        WHERE m.receiver_id = ? AND m.lu = 0 AND m.id > ?
        ORDER BY m.id ASC
      ''', [me, dernierId]);

      for (final r in rows) {
        final id = r['id'] as int;
        final contenu = r['content'] as String;
        final nom = r['sender_role'] == 'pediatre'
            ? 'Dr. ${r['sender_name']}'
            : r['sender_name'] as String;
        final urgent =
            MessageService.analyserUrgence(contenu) == NiveauUrgence.urgent;

        String titre;
        String corps;
        if (r['type'] == 'bilan') {
          titre = '📊 Nouveau bilan de développement';
          corps = '$nom vous a envoyé un bilan.';
        } else if (urgent) {
          titre = '🔴 URGENT — message de $nom';
          corps = contenu;
        } else {
          titre = '💬 Nouveau message de $nom';
          corps = contenu;
        }

        await _plugin.show(
          100000 + id, // id unique par message
          titre,
          corps,
          urgent ? _detailsUrgent : _detailsNormal,
        );
        await prefs.setInt(cle, id);
      }

      return MessageService.getNonLus(userId);
    } catch (_) {
      return 0;
    }
  }
}