class ConversationModel {
  final String contactId;
  final String contactName;
  final String contactRole; // 'parent' ou 'pediatre'
  final String lastMessage;
  final String lastType;    // 'texte' ou 'bilan'
  final DateTime lastDate;
  final String lastSenderId;
  final int nonLus;
  final bool urgent;        // détecté par l'IA de tri

  ConversationModel({
    required this.contactId,
    required this.contactName,
    required this.contactRole,
    required this.lastMessage,
    required this.lastType,
    required this.lastDate,
    required this.lastSenderId,
    required this.nonLus,
    this.urgent = false,
  });
}