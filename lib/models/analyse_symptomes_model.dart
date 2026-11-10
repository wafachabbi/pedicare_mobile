enum NiveauSuggestion { info, attention, urgent }

class SuggestionSante {
  final String texte;
  final NiveauSuggestion niveau;
  final String emoji;

  const SuggestionSante({
    required this.texte,
    this.niveau = NiveauSuggestion.info,
    this.emoji = '💡',
  });
}

/// Résultat de l'analyse contextuelle du journal (non diagnostique).
class AnalyseSymptomes {
  final List<SuggestionSante> suggestions;
  final String message;
  final bool iaDisponible;
  final DateTime? derniereEntree;

  const AnalyseSymptomes({
    required this.suggestions,
    required this.message,
    this.iaDisponible = false,
    this.derniereEntree,
  });

  bool get aUrgence =>
      suggestions.any((s) => s.niveau == NiveauSuggestion.urgent);

  bool get aAttention => suggestions.any(
      (s) => s.niveau == NiveauSuggestion.attention || s.niveau == NiveauSuggestion.urgent);

  NiveauSuggestion get niveauMax {
    if (suggestions.any((s) => s.niveau == NiveauSuggestion.urgent)) {
      return NiveauSuggestion.urgent;
    }
    if (suggestions.any((s) => s.niveau == NiveauSuggestion.attention)) {
      return NiveauSuggestion.attention;
    }
    return NiveauSuggestion.info;
  }
}

/// Résumé pré-consultation généré par l'IA (ou le moteur local de secours).
class ResumeConsultationIA {
  final String titre;
  final String resume;
  final List<String> pointsCles;
  final List<String> suggestions;
  final bool genereeIA;
  final DateTime periodeDebut;
  final DateTime periodeFin;
  final int nbEntrees;

  const ResumeConsultationIA({
    required this.titre,
    required this.resume,
    required this.pointsCles,
    required this.suggestions,
    required this.genereeIA,
    required this.periodeDebut,
    required this.periodeFin,
    required this.nbEntrees,
  });
}
