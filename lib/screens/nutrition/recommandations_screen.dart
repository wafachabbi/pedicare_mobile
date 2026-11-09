import 'package:flutter/material.dart';
import '../../data/nutrition_catalogue.dart';
import '../../models/enfant_model.dart';
import '../../services/nutrition_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pc_ui.dart';

/// Recommandations nutritionnelles par tranche d'âge + aliments à éviter.
class RecommandationsScreen extends StatelessWidget {
  final EnfantModel enfant;
  const RecommandationsScreen({super.key, required this.enfant});

  @override
  Widget build(BuildContext context) {
    final ageMois = NutritionService.ageEnMois(enfant.dateNaissance);
    final actuelle = trancheDeAge(ageMois);
    final aEviter = reglesAge.where((r) => ageMois < r.ageMinMois).toList();

    return PcPage(
      titre: 'Recommandations',
      sousTitre: '${enfant.prenom} · tranche ${actuelle.titre}',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _tranche(actuelle, actuelle: true),
          if (aEviter.isNotEmpty) ...[
            const PcSectionTitle('À éviter à son âge'),
            ...aEviter.map((r) => PcCard(
                  color: r.danger ? AppColors.danger : const Color(0xFFE67E22),
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.danger ? '⛔' : '⚠️',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.aliment,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                            Text(
                                '${r.raison} (jusqu\'à ${_age(r.ageMinMois)})',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          const PcSectionTitle('Toutes les tranches d\'âge'),
          for (final t in tranchesAge)
            if (t != actuelle) _tranche(t),
          const SizedBox(height: 6),
          const PcAvertissement(avertissementNutrition),
        ],
      ),
    );
  }

  static String _age(int mois) => mois < 24 ? '$mois mois' : '${mois ~/ 12} ans';

  Widget _tranche(TrancheAge t, {bool actuelle = false}) {
    final color = actuelle ? AppColors.accent : AppColors.secondary;
    return PcCard(
      color: color,
      padding: EdgeInsets.zero,
      child: Theme(
        data: ThemeData.dark().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: actuelle,
          iconColor: AppColors.textSecondary,
          collapsedIconColor: AppColors.textSecondary,
          leading: Text(t.emoji, style: const TextStyle(fontSize: 24)),
          title: Text(t.titre,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          subtitle: actuelle
              ? Text('Âge actuel de l\'enfant',
                  style: TextStyle(color: color, fontSize: 11.5))
              : null,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          children: [
            for (final c in t.conseils)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•  ', style: TextStyle(color: color)),
                    Expanded(
                      child: Text(c,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12.5,
                              height: 1.35)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
