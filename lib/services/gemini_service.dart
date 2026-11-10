import 'package:google_generative_ai/google_generative_ai.dart';

/// Configuration centralisée de l'accès à Gemini pour toute l'application.
///
/// Point d'entrée unique : ne plus écrire de clé ni de nom de modèle dans les
/// services (`ia_consultation_service`, `ia_croissance_service`,
/// `ia_vaccination_service`).
///
/// Deux façons de fournir la clé :
///   1. à la compilation (recommandé) :
///        flutter run --dart-define=GEMINI_API_KEY=xxxx
///        flutter build apk --dart-define=GEMINI_API_KEY=xxxx
///   2. depuis le fichier local non versionné `gemini.local.json` :
///        flutter run --dart-define-from-file=gemini.local.json
///
/// Sans clé, l'IA bascule sur le moteur local de règles (aucune erreur).
/// Ne JAMAIS remettre de clé en dur ici : le code source est partagé.
class GeminiService {
  GeminiService._();

  static const String apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Vrai si une clé exploitable est disponible.
  static bool get configuree => !_iaDesactivee && apiKey.trim().isNotEmpty;

  static bool _iaDesactivee = false;

  /// Coupe l'IA pour les tests unitaires : sans cela, chaque analyse
  /// déclencherait un appel réseau réel (lent et non déterministe).
  static void desactiverPourTests() => _iaDesactivee = true;

  /// Modèles essayés dans l'ordre.
  ///
  /// Google retire régulièrement des modèles : `gemini-1.5-flash` a été
  /// supprimé et renvoie désormais une erreur 404. En testant plusieurs noms,
  /// l'application continue de fonctionner si l'un d'eux disparaît.
  static const List<String> modeles = <String>[
    'gemini-3.5-flash-lite',
    'gemini-flash-lite-latest',
    'gemini-3.8-flash',
    'gemini-flash-latest',
  ];

  /// Dernier modèle qui a répondu, pour éviter de retester les modèles morts.
  static String? _modeleActif;

  /// Génère un texte. Renvoie `null` si aucun modèle n'a répondu
  /// (clé absente, réseau coupé, quota atteint...).
  ///
  /// L'appelant doit alors utiliser son moteur de règles local.
  static Future<String?> generer({
    required String prompt,
    double temperature = 0.5,
    int maxOutputTokens = 512,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!configuree) return null;

    // Les modèles à raisonnement consomment des jetons avant de rédiger :
    // un plafond trop bas renvoie un texte vide. On garde un plancher.
    final plafond = maxOutputTokens < 512 ? 512 : maxOutputTokens;
    final candidats = <String>[
      ?_modeleActif,
      ...modeles.where((m) => m != _modeleActif),
    ];

    for (final nom in candidats) {
      try {
        final model = GenerativeModel(
          model: nom,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: temperature,
            maxOutputTokens: plafond,
          ),
        );
        final response =
            await model.generateContent([Content.text(prompt)]).timeout(timeout);
        final texte = response.text?.trim();
        if (texte != null && texte.isNotEmpty) {
          _modeleActif = nom;
          return texte;
        }
      } catch (_) {
        // Modèle retiré, saturé ou prompt refusé : on essaie le suivant.
      }
    }
    return null;
  }

  /// Réinitialise la préférence de modèle (utile pour les tests).
  static void reinitialiserModele() => _modeleActif = null;
}
