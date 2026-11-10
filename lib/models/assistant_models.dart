/// Modèles de l'assistant IA pédiatrique (IA globale — Molka).
library;

import 'dart:convert';

/// Source citée dans une réponse (passage de la base de connaissances).
class SourceCitee {
  final int numero;
  final String passageId;
  final String titre;
  final String source;

  const SourceCitee({
    required this.numero,
    required this.passageId,
    required this.titre,
    required this.source,
  });

  Map<String, dynamic> toJson() =>
      {'n': numero, 'id': passageId, 'titre': titre, 'source': source};

  factory SourceCitee.fromJson(Map<String, dynamic> j) => SourceCitee(
        numero: (j['n'] as num?)?.toInt() ?? 0,
        passageId: j['id']?.toString() ?? '',
        titre: j['titre']?.toString() ?? '',
        source: j['source']?.toString() ?? '',
      );

  static String encoder(List<SourceCitee> s) =>
      jsonEncode(s.map((e) => e.toJson()).toList());

  static List<SourceCitee> decoder(String? texte) {
    if (texte == null || texte.isEmpty) return const [];
    try {
      return (jsonDecode(texte) as List)
          .map((e) => SourceCitee.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}

class ConversationIA {
  final String id;
  final String enfantId;
  final String titre;
  final DateTime creeLe;
  final DateTime majLe;

  ConversationIA({
    required this.id,
    required this.enfantId,
    required this.titre,
    required this.creeLe,
    required this.majLe,
  });

  factory ConversationIA.fromMap(Map<String, dynamic> m) => ConversationIA(
        id: m['id']?.toString() ?? '',
        enfantId: m['enfant_id']?.toString() ?? '',
        titre: m['titre']?.toString() ?? 'Conversation',
        creeLe: DateTime.tryParse(m['created_at']?.toString() ?? '') ??
            DateTime.now(),
        majLe: DateTime.tryParse(m['updated_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class MessageIA {
  final String id;
  final String conversationId;

  /// true = message du parent, false = réponse de l'assistant.
  final bool duParent;
  final String texte;

  /// Signes d'alerte détectés : l'assistant oriente vers les urgences.
  final bool urgent;

  /// Réponse générée par Gemini (sinon : moteur local).
  final bool parIA;

  /// Sources de la base de connaissances citées dans la réponse.
  final List<SourceCitee> sources;
  final DateTime date;

  MessageIA({
    required this.id,
    required this.conversationId,
    required this.duParent,
    required this.texte,
    this.urgent = false,
    this.parIA = false,
    this.sources = const [],
    required this.date,
  });

  Map<String, dynamic> toDbMap() => {
        'conversation_id': int.tryParse(conversationId) ?? conversationId,
        'auteur': duParent ? 'parent' : 'assistant',
        'texte': texte,
        'urgent': urgent ? 1 : 0,
        'par_ia': parIA ? 1 : 0,
        'sources': sources.isEmpty ? null : SourceCitee.encoder(sources),
        'created_at': date.toIso8601String(),
      };

  factory MessageIA.fromMap(Map<String, dynamic> m) => MessageIA(
        id: m['id']?.toString() ?? '',
        conversationId: m['conversation_id']?.toString() ?? '',
        duParent: m['auteur'] == 'parent',
        texte: m['texte']?.toString() ?? '',
        urgent: m['urgent'] == 1,
        parIA: m['par_ia'] == 1,
        sources: SourceCitee.decoder(m['sources'] as String?),
        date: DateTime.tryParse(m['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}

/// Réponse produite par l'assistant.
class ReponseAssistant {
  final String texte;
  final bool urgent;
  final bool parIA;
  final List<SourceCitee> sources;

  const ReponseAssistant({
    required this.texte,
    this.urgent = false,
    this.parIA = false,
    this.sources = const [],
  });
}
