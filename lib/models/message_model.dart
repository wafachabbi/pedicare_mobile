class MessageModel {
  final int id;
  final String senderId;
  final String receiverId;
  final String? enfantId;
  final String content;
  final String type; // 'texte' ou 'bilan'
  final DateTime date;
  final bool lu;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.enfantId,
    required this.content,
    this.type = 'texte',
    required this.date,
    this.lu = false,
  });

  bool isMine(String userId) => senderId == userId;
  bool get estBilan => type == 'bilan';

  factory MessageModel.fromMap(Map<String, dynamic> m) {
    // SQLite stocke datetime('now') en UTC : "2026-11-09 18:30:00"
    final raw = (m['created_at'] ?? '').toString();
    final date = DateTime.tryParse('${raw.replaceFirst(' ', 'T')}Z')?.toLocal() ?? DateTime.now();
    return MessageModel(
      id: m['id'] as int,
      senderId: m['sender_id'].toString(),
      receiverId: m['receiver_id'].toString(),
      enfantId: m['enfant_id']?.toString(),
      content: m['content'] ?? '',
      type: m['type'] ?? 'texte',
      date: date,
      lu: (m['lu'] ?? 0) == 1,
    );
  }
}