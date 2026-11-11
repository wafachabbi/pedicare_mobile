import 'package:flutter/material.dart';

/// Option de saisie rapide d'un symptôme dans le journal.
class SymptomeOption {
  final String id;
  final String label;
  final String emoji;

  /// Signe d'alerte nécessitant une vigilance particulière (sans diagnostic).
  final bool alerte;

  const SymptomeOption({
    required this.id,
    required this.label,
    required this.emoji,
    this.alerte = false,
  });
}

/// Catalogue centralisé utilisé par la saisie, l'historique, l'IA et le PDF.
class SymptomesCatalogue {
  static const List<SymptomeOption> tous = [
    SymptomeOption(id: 'fievre', label: 'Fièvre', emoji: '🌡️'),
    SymptomeOption(id: 'toux', label: 'Toux', emoji: '😷'),
    SymptomeOption(id: 'rhume', label: 'Rhume', emoji: '🤧'),
    SymptomeOption(id: 'mal_gorge', label: 'Mal de gorge', emoji: '🗣️'),
    SymptomeOption(id: 'otite', label: 'Douleur oreille', emoji: '👂'),
    SymptomeOption(id: 'mal_tete', label: 'Mal de tête', emoji: '🤕'),
    SymptomeOption(id: 'douleur_ventre', label: 'Douleur ventre', emoji: '🤢'),
    SymptomeOption(id: 'vomissement', label: 'Vomissements', emoji: '🤮'),
    SymptomeOption(id: 'diarrhee', label: 'Diarrhée', emoji: '💩'),
    SymptomeOption(id: 'constipation', label: 'Constipation', emoji: '🚽'),
    SymptomeOption(id: 'eruption', label: 'Éruption cutanée', emoji: '🔴'),
    SymptomeOption(id: 'fatigue', label: 'Fatigue', emoji: '😴'),
    SymptomeOption(id: 'pleurs', label: 'Pleurs inhabituels', emoji: '😭'),
    SymptomeOption(
        id: 'respiration',
        label: 'Difficulté à respirer',
        emoji: '🫁',
        alerte: true),
    SymptomeOption(id: 'yeux_rouges', label: 'Yeux rouges', emoji: '👁️'),
    SymptomeOption(
        id: 'deshydratation',
        label: 'Déshydratation',
        emoji: '💧',
        alerte: true),
    SymptomeOption(
        id: 'convulsion',
        label: 'Convulsions',
        emoji: '⚡',
        alerte: true),
    SymptomeOption(id: 'douleur', label: 'Douleur', emoji: '💢'),
  ];

  static SymptomeOption? parId(String id) {
    for (final s in tous) {
      if (s.id == id) return s;
    }
    return null;
  }

  static String labelDe(String id) => parId(id)?.label ?? id;

  static String emojiDe(String id) => parId(id)?.emoji ?? '•';

  static String libelleListe(List<String> ids) {
    if (ids.isEmpty) return 'Aucun symptôme';
    return ids.map(labelDe).join(' · ');
  }

  /// Couleur d'accent utilisée dans les interfaces.
  static Color couleurDe(String id) {
    final option = parId(id);
    if (option?.alerte == true) return const Color(0xFFFF6B6B);
    return const Color(0xFF4DAAFF);
  }
}
