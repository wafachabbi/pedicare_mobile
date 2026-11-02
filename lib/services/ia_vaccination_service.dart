import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/vaccin_model.dart';
import 'calendrier_vaccinal_service.dart';

/// Niveau de priorité de la suggestion IA
enum PrioriteIA { urgente, haute, normale, future }

/// Une suggestion locale (pré-calcul) passée à Gemini comme contexte
class SuggestionVaccin {
  final VaccinProgramme programme;
  final PrioriteIA priorite;
  final String titre;
  final DateTime dateSuggeree;
  final int retardJours;

  const SuggestionVaccin({
    required this.programme,
    required this.priorite,
    required this.titre,
    required this.dateSuggeree,
    required this.retardJours,
  });
}

/// Résultat de l'analyse Gemini
class AnalyseVaccinaleIA {
  final List<SuggestionVaccin> urgentes;
  final List<SuggestionVaccin> prochaines;
  final List<SuggestionVaccin> futures;
  final String resumeGemini;       // texte généré par Gemini
  final double scoreCouverture;
  final int ageMois;
  final bool geminiDisponible;

  const AnalyseVaccinaleIA({
    required this.urgentes,
    required this.prochaines,
    required this.futures,
    required this.resumeGemini,
    required this.scoreCouverture,
    required this.ageMois,
    required this.geminiDisponible,
  });

  bool get estAJour => urgentes.isEmpty;
}

class IAVaccinationService {
  // ⚠️  Remplace cette valeur par ta clé API Google AI Studio
  // https://aistudio.google.com/app/apikey  (gratuit)
  static const String _apiKey = 'GEMINI_API_KEY';

  /// Analyse + appel Gemini
  static Future<AnalyseVaccinaleIA> analyser({
    required DateTime dateNaissance,
    required List<VaccinModel> vaccinsAdministres,
    required String prenomEnfant,
    required String sexe,
  }) async {
    final ageMois = CalendrierVaccinalService.ageMoisDepuis(dateNaissance);
    final evaluation = CalendrierVaccinalService.evaluer(
      ageMois: ageMois,
      vaccinsAdministres: vaccinsAdministres,
    );

    final urgentes = <SuggestionVaccin>[];
    final prochaines = <SuggestionVaccin>[];
    final futures = <SuggestionVaccin>[];
    final now = DateTime.now();

    for (final statut in evaluation) {
      final prog = statut.programme;
      if (statut.statut == StatutVaccin.fait) continue;

      if (statut.statut == StatutVaccin.enRetard) {
        final dateAttendue = DateTime(
            dateNaissance.year, dateNaissance.month + prog.ageMoisMin, dateNaissance.day);
        final retardJours = now.difference(dateAttendue).inDays.clamp(0, 9999);
        urgentes.add(SuggestionVaccin(
          programme: prog,
          priorite: retardJours < 30 ? PrioriteIA.urgente : PrioriteIA.haute,
          titre: retardJours == 0
              ? '${prog.nom} — À faire maintenant'
              : '${prog.nom} — En retard (${(retardJours / 30).floor()} mois)',
          dateSuggeree: now,
          retardJours: retardJours,
        ));
      } else if (statut.statut == StatutVaccin.aVenir) {
        final datePrevue = DateTime(
            dateNaissance.year, dateNaissance.month + prog.ageMoisMin, dateNaissance.day);
        final joursRestants = datePrevue.difference(now).inDays;
        final moisRestants = (joursRestants / 30).ceil();

        if (joursRestants <= 30) {
          prochaines.add(SuggestionVaccin(
            programme: prog,
            priorite: PrioriteIA.haute,
            titre: '${prog.nom} — Dans $joursRestants jours',
            dateSuggeree: datePrevue,
            retardJours: 0,
          ));
        } else if (moisRestants <= 3) {
          prochaines.add(SuggestionVaccin(
            programme: prog,
            priorite: PrioriteIA.normale,
            titre: '${prog.nom} — Dans $moisRestants mois',
            dateSuggeree: datePrevue,
            retardJours: 0,
          ));
        } else {
          futures.add(SuggestionVaccin(
            programme: prog,
            priorite: PrioriteIA.future,
            titre: '${prog.nom} — Prévu à ${prog.ageLabel}',
            dateSuggeree: datePrevue,
            retardJours: 0,
          ));
        }
      }
    }

    // Score couverture
    final total = evaluation.length;
    final faits = evaluation.where((v) => v.statut == StatutVaccin.fait).length;
    final score = total > 0 ? faits / total : 0.0;

    // Appel Gemini
    final resumeGemini = await _appelGemini(
      prenom: prenomEnfant,
      sexe: sexe,
      ageMois: ageMois,
      vaccinsAdministres: vaccinsAdministres,
      urgentes: urgentes,
      prochaines: prochaines,
      score: score,
    );

    return AnalyseVaccinaleIA(
      urgentes: urgentes,
      prochaines: prochaines,
      futures: futures,
      resumeGemini: resumeGemini.$1,
      scoreCouverture: score,
      ageMois: ageMois,
      geminiDisponible: resumeGemini.$2,
    );
  }

  // ── Appel à Gemini ─────────────────────────────────────────────────────────
  static Future<(String, bool)> _appelGemini({
    required String prenom,
    required String sexe,
    required int ageMois,
    required List<VaccinModel> vaccinsAdministres,
    required List<SuggestionVaccin> urgentes,
    required List<SuggestionVaccin> prochaines,
    required double score,
  }) async {
    if (_apiKey == 'GEMINI_API_KEY') {
      return (_fallbackResume(prenom, sexe, ageMois, urgentes, prochaines, score), false);
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 400,
        ),
      );

      final ageStr = ageMois < 24 ? '$ageMois mois' : '${(ageMois / 12).floor()} ans';
      final pronon = sexe == 'F' ? 'elle' : 'il';
      final vaccinsStr = vaccinsAdministres.isEmpty
          ? 'aucun vaccin enregistré'
          : vaccinsAdministres.map((v) => v.nom).join(', ');
      final urgentesStr = urgentes.isEmpty
          ? 'aucun vaccin urgent'
          : urgentes.map((s) => '${s.programme.nom} (${s.programme.maladie})').join(', ');
      final prochainesStr = prochaines.isEmpty
          ? 'aucun vaccin prévu dans les 3 mois'
          : prochaines.map((s) => '${s.programme.nom} (${s.programme.maladie})').join(', ');
      final pct = (score * 100).round();

      final prompt = '''
Tu es un assistant pédiatrique intelligent de l'application PediCare.
Génère un résumé personnalisé et bienveillant en français pour les parents de $prenom.

Données de l'enfant :
- Prénom : $prenom
- Sexe : ${sexe == 'F' ? 'Fille' : 'Garçon'}
- Âge : $ageStr
- Vaccins déjà administrés : $vaccinsStr
- Couverture vaccinale : $pct%
- Vaccins urgents ou en retard : $urgentesStr
- Vaccins prévus dans les 3 prochains mois : $prochainesStr

Instructions :
- Rédige un paragraphe de 3 à 5 phrases maximum
- Sois chaleureux et rassurant envers les parents
- Mentionne le prénom de l'enfant ($prenom)
- Explique clairement ce qui est urgent et pourquoi c'est important
- Donne un conseil pratique concret
- N'utilise pas de markdown ni de listes, texte pur uniquement
- Utilise "il" ou "elle" selon le sexe ($pronon)
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';
      if (text.isEmpty) {
        return (_fallbackResume(prenom, sexe, ageMois, urgentes, prochaines, score), false);
      }
      return (text, true);
    } catch (e) {
      return (_fallbackResume(prenom, sexe, ageMois, urgentes, prochaines, score), false);
    }
  }

  // ── Résumé de secours (si pas de clé ou erreur réseau) ────────────────────
  static String _fallbackResume(
    String prenom, String sexe, int ageMois,
    List<SuggestionVaccin> urgentes, List<SuggestionVaccin> prochaines, double score,
  ) {
    final pct = (score * 100).round();
    final il = sexe == 'F' ? 'Elle' : 'Il';
    final ageStr = ageMois < 24 ? '$ageMois mois' : '${(ageMois / 12).floor()} ans';

    if (urgentes.isEmpty && prochaines.isEmpty) {
      return '$prenom ($ageStr) est parfaitement à jour ! Couverture : $pct%. $il ne nécessite aucune vaccination dans les 3 prochains mois. 🎉';
    }
    if (urgentes.isNotEmpty) {
      return '$prenom ($ageStr) a ${urgentes.length} vaccination(s) urgente(s) à planifier. Couverture actuelle : $pct%. Consultez votre pédiatre rapidement.';
    }
    return '$prenom ($ageStr) est à jour pour les vaccins urgents. ${prochaines.length} vaccination(s) prévue(s) prochainement. Couverture : $pct%.';
  }
}
