import '../models/message_model.dart';
import 'groq_service.dart';
import 'message_service.dart';

/// IA d'assistance au pédiatre : propose 3 réponses prêtes à envoyer
class IAMessageService {
  /// Retourne (suggestions, true si générées par l'IA Groq)
  static Future<(List<String>, bool)> suggererReponses({
    required List<MessageModel> messages,
    required String pediatreId,
    required String nomParent,
  }) async {
    // Contexte : les 8 derniers messages
    final derniers = messages.length > 8 ? messages.sublist(messages.length - 8) : messages;
    if (derniers.isEmpty || !GroqService.disponible) return (_fallback(derniers), false);

    // Historique compact : le bilan est résumé en 1 ligne pour ne pas noyer le contexte
    final historique = derniers.map((m) {
      final auteur = m.senderId == pediatreId ? 'Pédiatre' : 'Parent';
      final texte = m.estBilan ? "[a envoyé le bilan de développement de l'enfant]" : m.content;
      return '$auteur : $texte';
    }).join('\n');

    // Le message auquel le pédiatre doit répondre = dernier message du parent
    final dernierParent = derniers.lastWhere(
          (m) => m.senderId != pediatreId,
      orElse: () => derniers.last,
    );
    final aRepondre = dernierParent.estBilan
        ? "Le parent vient d'envoyer le bilan de développement de son enfant (résultats très bons)."
        : dernierParent.content;
    final urgent = !dernierParent.estBilan &&
        MessageService.analyserUrgence(dernierParent.content) == NiveauUrgence.urgent;

    final prompt = '''
Tu es l'assistant d'un pédiatre dans la messagerie de l'application PediCare.

Contexte de la conversation (du plus ancien au plus récent) :
$historique

MESSAGE AUQUEL LE PÉDIATRE DOIT RÉPONDRE MAINTENANT :
"$aRepondre"
${urgent ? 'ATTENTION : ce message décrit des symptômes potentiellement graves.' : ''}

Rédige exactement 3 réponses différentes que le pédiatre peut envoyer au parent, qui répondent DIRECTEMENT à ce message :
1) une réponse qui rassure et donne la conduite à tenir${urgent ? " (consulter rapidement / aux urgences, appeler le 190 en cas d'aggravation)" : ''}
2) une réponse qui pose 1 ou 2 questions précises pour mieux évaluer la situation
3) une réponse qui propose une téléconsultation ou un rendez-vous

Règles :
- Français, ton professionnel et bienveillant, 1 à 2 phrases par réponse
- Parle uniquement des symptômes réellement mentionnés par le parent, n'invente rien
- Aucune posologie, aucun nom de médicament
- Réponds UNIQUEMENT avec les 3 réponses, une par ligne, sans numéro, sans tiret, sans guillemets
''';

    final texte = await GroqService.generer(prompt, temperature: 0.5, maxTokens: 1500);
    if (texte == null) return (_fallback(derniers), false);

    final lignes = texte
        .split('\n')
        .map((l) => l.replaceFirst(RegExp(r'^\s*([-•*]|\d+[.)])\s*'), '').trim())
        .map((l) => l.replaceAll('"', '').trim())
        .where((l) => l.isNotEmpty)
        .take(3)
        .toList();

    if (lignes.length < 2) return (_fallback(derniers), false);
    return (lignes, true);
  }

  /// Suggestions locales si pas de clé API ou pas de réseau
  static List<String> _fallback(List<MessageModel> derniers) {
    if (derniers.isEmpty) {
      return [
        'Bonjour, comment puis-je vous aider ?',
        "Bonjour, comment va l'enfant aujourd'hui ?",
        'Bonjour, je suis disponible pour répondre à vos questions.',
      ];
    }

    final dernier = derniers.last;

    if (dernier.estBilan) {
      return [
        "Merci pour ce bilan, les résultats sont encourageants. Continuez les activités d'éveil régulièrement.",
        'Merci, je regarde le bilan en détail et je reviens vers vous.',
        'Merci pour le bilan. Nous pourrons en discuter lors de la prochaine consultation.',
      ];
    }

    if (MessageService.analyserUrgence(dernier.content) == NiveauUrgence.urgent) {
      return [
        "Merci de m'avoir prévenu. Au vu de ces symptômes, je vous conseille de consulter rapidement. En cas d'aggravation, appelez le 190 (SAMU).",
        'Pouvez-vous me préciser depuis quand cela dure et la température actuelle ?',
        "Je vous propose une téléconsultation dès aujourd'hui pour évaluer la situation.",
      ];
    }

    return [
      'Merci pour votre message, je reviens vers vous rapidement.',
      'Pouvez-vous me donner un peu plus de détails ?',
      'Je vous propose de prendre un rendez-vous pour en parler.',
    ];
  }
}