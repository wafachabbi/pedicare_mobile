import 'dart:developer' as dev;
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import 'database_service.dart';

/// Niveau d'urgence estimé d'un message (IA de tri pour le pédiatre)
enum NiveauUrgence { urgent, normal }

class MessageService {
  // ── Envoyer ───────────────────────────────────────────────────────────────
  /// Retourne null si OK, sinon un message d'erreur
  static Future<String?> envoyer({
    required String senderId,
    required String receiverId,
    required String content,
    String type = 'texte',
    String? enfantId,
  }) async {
    final texte = content.trim();
    if (texte.isEmpty) return 'Message vide.';
    try {
      final db = await DatabaseService.database;

      // Règle métier : un parent écrit à un pédiatre (ou l'inverse)
      final users = await db.query('users',
          columns: ['id', 'role'],
          where: 'id IN (?, ?)',
          whereArgs: [int.parse(senderId), int.parse(receiverId)]);
      final roles = {for (final u in users) u['id'].toString(): u['role']};
      if (roles.length != 2 || roles[senderId] == roles[receiverId]) {
        return 'Conversation autorisée uniquement entre parent et pédiatre.';
      }

      await db.insert('messages', {
        'sender_id': int.parse(senderId),
        'receiver_id': int.parse(receiverId),
        'enfant_id': enfantId == null ? null : int.parse(enfantId),
        'content': texte,
        'type': type,
      });
      return null;
    } catch (e) {
      dev.log('envoyer message error: $e');
      return "Erreur lors de l'envoi.";
    }
  }

  // ── Lire une conversation (et marquer comme lus) ──────────────────────────
  static Future<List<MessageModel>> getMessages(String userId, String otherId) async {
    try {
      final db = await DatabaseService.database;
      final me = int.parse(userId);
      final other = int.parse(otherId);
      final rows = await db.query(
        'messages',
        where: '(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)',
        whereArgs: [me, other, other, me],
        orderBy: 'id ASC',
      );
      await db.update('messages', {'lu': 1},
          where: 'sender_id = ? AND receiver_id = ? AND lu = 0', whereArgs: [other, me]);
      return rows.map((e) => MessageModel.fromMap(e)).toList();
    } catch (e) {
      dev.log('getMessages error: $e');
      return [];
    }
  }

  // ── Liste des conversations ───────────────────────────────────────────────
  static Future<List<ConversationModel>> getConversations(String userId) async {
    try {
      final db = await DatabaseService.database;
      final me = int.parse(userId);
      final rows = await db.rawQuery('''
        SELECT u.id AS contact_id, u.name AS contact_name, u.role AS contact_role,
               m.content AS last_message, m.type AS last_type,
               m.created_at AS last_date, m.sender_id AS last_sender,
               (SELECT COUNT(*) FROM messages x
                 WHERE x.sender_id = u.id AND x.receiver_id = ? AND x.lu = 0) AS non_lus
        FROM messages m
        JOIN users u
          ON u.id = CASE WHEN m.sender_id = ? THEN m.receiver_id ELSE m.sender_id END
        WHERE m.id IN (
          SELECT MAX(id) FROM messages
          WHERE sender_id = ? OR receiver_id = ?
          GROUP BY MIN(sender_id, receiver_id), MAX(sender_id, receiver_id)
        )
        ORDER BY m.id DESC
      ''', [me, me, me, me]);

      final convs = <ConversationModel>[];
      for (final r in rows) {
        final contactId = r['contact_id'].toString();
        final nonLus = r['non_lus'] as int;
        // Urgent si un des messages NON LUS reçus de ce contact est urgent
        bool urgent = false;
        if (nonLus > 0) {
          final nonLusRows = await db.query('messages',
              columns: ['content'],
              where: 'sender_id = ? AND receiver_id = ? AND lu = 0',
              whereArgs: [int.parse(contactId), me]);
          urgent = nonLusRows.any(
                  (m) => analyserUrgence(m['content'] as String) == NiveauUrgence.urgent);
        }
        final raw = (r['last_date'] ?? '').toString();
        convs.add(ConversationModel(
          contactId: contactId,
          contactName: r['contact_name'] as String,
          contactRole: r['contact_role'] as String,
          lastMessage: r['last_message'] as String,
          lastType: (r['last_type'] ?? 'texte') as String,
          lastDate: DateTime.tryParse('${raw.replaceFirst(' ', 'T')}Z')?.toLocal() ?? DateTime.now(),
          lastSenderId: r['last_sender'].toString(),
          nonLus: nonLus,
          urgent: urgent,
        ));
      }
      // IA de tri : conversations urgentes en premier
      convs.sort((a, b) => (b.urgent ? 1 : 0) - (a.urgent ? 1 : 0));
      return convs;
    } catch (e) {
      dev.log('getConversations error: $e');
      return [];
    }
  }

  // ── Supprimer un de ses messages ──────────────────────────────────────────
  static Future<bool> supprimer(int messageId, String userId) async {
    final db = await DatabaseService.database;
    final n = await db.delete('messages',
        where: 'id = ? AND sender_id = ?', whereArgs: [messageId, int.parse(userId)]);
    return n > 0;
  }

  // ── Nombre de non lus (badge) ─────────────────────────────────────────────
  static Future<int> getNonLus(String userId) async {
    final db = await DatabaseService.database;
    final r = await db.rawQuery(
        'SELECT COUNT(*) AS n FROM messages WHERE receiver_id = ? AND lu = 0',
        [int.parse(userId)]);
    return r.first['n'] as int;
  }

  // ── IA de tri : détection des messages urgents ────────────────────────────
  static const List<String> _motsUrgents = [
    'urgence', 'urgent', 'fièvre', 'fievre', 'convulsion', 'respire mal',
    'respirer', 'étouffe', 'etouffe', 'sang', 'saigne', 'inconscient', 'vomit',
    'vomissement', 'déshydrat', 'deshydrat', 'chute', 'brûlure', 'brulure',
    'avalé', 'avale', 'allergie', 'gonfle', 'lèvres bleues', 'ne mange plus',
  ];

  static NiveauUrgence analyserUrgence(String texte) {
    final t = texte.toLowerCase();
    return _motsUrgents.any((mot) => t.contains(mot)) ? NiveauUrgence.urgent : NiveauUrgence.normal;
  }
}