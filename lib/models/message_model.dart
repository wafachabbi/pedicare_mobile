class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole; // 'parent' ou 'pediatre'
  final String content;
  final DateTime date;
  final bool lu;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.content,
    required this.date,
    this.lu = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'senderId': senderId,
        'senderName': senderName,
        'senderRole': senderRole,
        'content': content,
        'date': date.toIso8601String(),
        'lu': lu,
      };

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is String) return DateTime.parse(val);
      try { return (val as dynamic).toDate(); } catch (_) {}
      return DateTime.now();
    }
    return MessageModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderRole: map['senderRole'] ?? 'parent',
      content: map['content'] ?? '',
      date: parseDate(map['date']),
      lu: map['lu'] ?? false,
    );
  }
}
