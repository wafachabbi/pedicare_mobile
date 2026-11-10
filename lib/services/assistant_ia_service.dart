import 'package:flutter/foundation.dart';
import '../models/assistant_models.dart';
import '../models/enfant_model.dart';
import 'database_service.dart';
import 'gemini_service.dart';
import 'nutrition_service.dart';
import 'rag/rag_service.dart';

/// Assistant pédiatrique IA (IA globale — Molka), fondé sur un RAG :
///
///  1. détection locale des signes d'alerte (avant tout appel réseau) ;
///  2. recherche des passages pertinents dans la base de connaissances
///     (BM25 hors ligne + embeddings Gemini si disponibles) ;
///  3. lecture du dossier de l'enfant (allergies, traitements, journal…) ;
///  4. génération par le LLM (Gemini), limitée aux sources, avec citations ;
///  5. sans LLM : réponse extractive construite à partir des passages.
///
/// L'assistant ne pose jamais de diagnostic et ne donne aucune dose.
class AssistantIaService {
  AssistantIaService._();

  static const String messageUrgence =
      '⚠️ Ces signes peuvent être graves. Appelez immédiatement le SAMU '
      '(190 en Tunisie, 15 en France) ou rendez-vous aux urgences les plus proches.';

  static const String avertissement =
      'L\'assistant répond à partir des fiches santé de PediCare et du dossier de '
      'l\'enfant, en citant ses sources. Il ne remplace pas un avis médical et ne '
      'pose pas de diagnostic.';

  // ══ Détection des signes d'alerte ═════════════════════════════════════════

  static const List<String> _signesAlerte = [
    'convulsion', 'convulse', 'crise convulsive', 'ne respire', 'respire mal',
    'difficulte a respirer', 'difficultes a respirer', 'du mal a respirer',
    's etouffe', 'etouffement', 'levres bleues', 'devient bleu', 'inconscient',
    'perte de connaissance', 'ne se reveille', 'ne reagit plus', 'tres mou',
    'raideur de la nuque', 'nuque raide', 'taches violettes', 'purpura',
    'avale un produit', 'avale des medicaments', 'intoxication', 'empoisonn',
    'saigne beaucoup', 'hemorragie', 'chute grave', 'tombe sur la tete',
  ];

  /// Vrai si la question décrit un signe d'alerte (ou une fièvre chez un
  /// nourrisson de moins de 3 mois).
  static bool estUrgent(String question, {int? ageMois}) {
    final t = NutritionService.normaliser(question);
    if (_signesAlerte.any(t.contains)) return true;
    if (ageMois != null && ageMois < 3 && t.contains('fievre')) return true;
    return false;
  }

  // ══ Réponse (pipeline RAG) ════════════════════════════════════════════════

  static Future<ReponseAssistant> repondre({
    required String question,
    required DossierEnfant dossier,
    List<MessageIA> historique = const [],
  }) async {
    final urgent = estUrgent(question, ageMois: dossier.ageMois);

    // La question précédente aide à comprendre une relance (« et la nuit ? »).
    final derniereQuestion = historique.lastWhere((m) => m.duParent,
        orElse: () => MessageIA(
            id: '', conversationId: '', duParent: true, texte: '', date: DateTime.now()));
    var passages =
        await RagService.rechercher(question, ageMois: dossier.ageMois);
    if (passages.isEmpty && derniereQuestion.texte.isNotEmpty) {
      passages = await RagService.rechercher(
          '${derniereQuestion.texte} $question',
          ageMois: dossier.ageMois);
    }
    final sources = RagService.sourcesDe(passages);

    final ia = await GeminiService.generer(
      prompt: RagService.construirePrompt(
        question: question,
        dossier: dossier,
        passages: passages,
        historique: historique,
        urgent: urgent,
      ),
      temperature: 0.2,
      maxOutputTokens: 900,
    );

    if (ia != null) {
      final texte = urgent && !ia.contains('190') ? '$messageUrgence\n\n$ia' : ia;
      return ReponseAssistant(
        texte: texte,
        urgent: urgent,
        parIA: true,
        sources: RagService.sourcesCitees(ia, sources),
      );
    }

    final extractif = RagService.reponseExtractive(
        question: question, dossier: dossier, passages: passages);
    return ReponseAssistant(
      texte: urgent ? '$messageUrgence\n\n$extractif' : extractif,
      urgent: urgent,
      sources: sources.take(3).toList(),
    );
  }

  // ══ Conversations (SQLite) ════════════════════════════════════════════════

  static Future<List<ConversationIA>> getConversations(String enfantId) async {
    try {
      final db = await DatabaseService.database;
      final rows = await db.query('conversations_ia',
          where: 'enfant_id = ?',
          whereArgs: [int.parse(enfantId)],
          orderBy: 'updated_at DESC');
      return rows.map(ConversationIA.fromMap).toList();
    } catch (e) {
      debugPrint('[Assistant] getConversations error: $e');
      return [];
    }
  }

  static Future<List<MessageIA>> getMessages(String conversationId) async {
    try {
      final db = await DatabaseService.database;
      final rows = await db.query('messages_ia',
          where: 'conversation_id = ?',
          whereArgs: [int.parse(conversationId)],
          orderBy: 'id ASC');
      return rows.map(MessageIA.fromMap).toList();
    } catch (e) {
      debugPrint('[Assistant] getMessages error: $e');
      return [];
    }
  }

  static Future<bool> supprimerConversation(String id) async {
    try {
      final db = await DatabaseService.database;
      return await db.delete('conversations_ia',
              where: 'id = ?', whereArgs: [int.parse(id)]) >
          0;
    } catch (e) {
      debugPrint('[Assistant] supprimerConversation error: $e');
      return false;
    }
  }

  /// Titre d'une conversation à partir de la première question.
  static String titreDepuis(String question) {
    final t = question.trim().replaceAll(RegExp(r'\s+'), ' ');
    return t.length <= 45 ? t : '${t.substring(0, 42)}…';
  }

  /// Envoie une question : crée la conversation si besoin, enregistre la
  /// question et la réponse (avec ses sources). Renvoie l'id de la conversation.
  static Future<String> envoyer({
    required EnfantModel enfant,
    String? conversationId,
    required String question,
  }) async {
    final db = await DatabaseService.database;
    final maintenant = DateTime.now();
    final convId = conversationId ??
        (await db.insert('conversations_ia', {
          'enfant_id': int.parse(enfant.id),
          'titre': titreDepuis(question),
          'created_at': maintenant.toIso8601String(),
          'updated_at': maintenant.toIso8601String(),
        }))
            .toString();
    final historique = await getMessages(convId);
    await db.insert(
        'messages_ia',
        MessageIA(
          id: '',
          conversationId: convId,
          duParent: true,
          texte: question.trim(),
          date: maintenant,
        ).toDbMap());

    final reponse = await repondre(
      question: question,
      dossier: await RagService.chargerDossier(enfant),
      historique: historique,
    );
    await db.insert(
        'messages_ia',
        MessageIA(
          id: '',
          conversationId: convId,
          duParent: false,
          texte: reponse.texte,
          urgent: reponse.urgent,
          parIA: reponse.parIA,
          sources: reponse.sources,
          date: DateTime.now(),
        ).toDbMap());
    await db.update('conversations_ia',
        {'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?', whereArgs: [int.parse(convId)]);
    return convId;
  }
}
