import 'package:flutter/material.dart';
import '../../services/eveil_service.dart';
import '../../theme/app_colors.dart';

/// Affiche le score de fin de jeu + les nouveaux badges
Future<void> afficherResultat(
    BuildContext context, {
      required int score,
      required List<BadgeInfo> nouveauxBadges,
    }) {
  final emoji = score >= 80 ? '🌟' : score >= 50 ? '👍' : '💪';
  final message = score >= 80
      ? 'Bravo, excellent travail !'
      : score >= 50
      ? 'Bien joué !'
      : 'Continue, tu progresses !';

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: const Color(0xFF0D2D5E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 8),
          Text('$score %',
              style: const TextStyle(color: Colors.white,
                  fontSize: 32, fontWeight: FontWeight.w800)),
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
          if (nouveauxBadges.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Nouveau badge ! 🎉',
                style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...nouveauxBadges.map((b) => Text('${b.emoji}  ${b.titre}',
                style: const TextStyle(color: Colors.white, fontSize: 16))),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Continuer', style: TextStyle(color: AppColors.secondary)),
        ),
      ],
    ),
  );
}