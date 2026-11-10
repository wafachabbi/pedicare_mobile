// Script CLI de diagnostic : print est voulu ici.
// ignore_for_file: avoid_print

import 'package:projet_mobile/services/gemini_service.dart';

Future<void> main() async {
  print('clé configurée : ${GeminiService.configuree}');
  final sw = Stopwatch()..start();
  final texte = await GeminiService.generer(
    prompt: 'En une seule phrase en francais, explique pourquoi il faut '
        'hydrater un enfant qui a de la fievre. Pas de diagnostic.',
    temperature: 0.4,
    maxOutputTokens: 512,
  );
  sw.stop();
  print('durée   : ${sw.elapsedMilliseconds} ms');
  print('résultat: ${texte ?? "ÉCHEC — repli local"}');
}
