import 'package:flutter/material.dart';
import '../../models/acteur.dart';
import '../../models/enfant_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pc_ui.dart';
import '../consultation/consultation_screen.dart';
import '../journal/journal_symptomes_screen.dart';
import '../nutrition/nutrition_screen.dart';
import '../pharma/pedipharma_screen.dart';

/// Espace pédiatre : dossier d'un enfant dont le parent a partagé le suivi.
///
/// Lecture seule : journal des symptômes, résumés de consultation.
/// Actions du pédiatre : prescriptions (PediPharma), allergies, consignes
/// alimentaires et journal alimentaire (Nutrition).
class DossierEnfantScreen extends StatelessWidget {
  final EnfantModel enfant;
  final Acteur pediatre;

  const DossierEnfantScreen(
      {super.key, required this.enfant, required this.pediatre});

  @override
  Widget build(BuildContext context) {
    final isFille = enfant.sexe == 'F';
    final color = isFille ? const Color(0xFFE91E8C) : const Color(0xFF4DAAFF);

    void ouvrir(Widget page) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));

    return PcPage(
      titre: enfant.nomComplet,
      sousTitre: 'Dossier partagé'
          '${enfant.parentNom != null ? ' · parent : ${enfant.parentNom}' : ''}',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          PcCard(
            color: color,
            child: Row(
              children: [
                Text(isFille ? '👧' : '👦', style: const TextStyle(fontSize: 34)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${enfant.age} an${enfant.age > 1 ? 's' : ''} · ${isFille ? 'Fille' : 'Garçon'}'
                          ' · né${isFille ? 'e' : ''} le ${pcDate(enfant.dateNaissance)}',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700)),
                      if (enfant.groupeSanguin != null)
                        Text('Groupe sanguin : ${enfant.groupeSanguin}',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      if ((enfant.allergies ?? '').trim().isNotEmpty)
                        Text('Allergies (profil) : ${enfant.allergies}',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const PcSectionTitle('Suivi par le parent (lecture seule)'),
          _ligne(
            '📝',
            'Journal des symptômes',
            'Saisies quotidiennes du parent',
            const Color(0xFF00C9A7),
            () => ouvrir(JournalSymptomesScreen(enfant: enfant, lectureSeule: true)),
          ),
          _ligne(
            '🩺',
            'Résumés de consultation',
            'Préparés par le parent avant la visite',
            const Color(0xFFE67E22),
            () => ouvrir(ConsultationScreen(enfant: enfant, lectureSeule: true)),
          ),
          const PcSectionTitle('Vos actions'),
          _ligne(
            '💊',
            'PediPharma',
            'Prescrire, suivre l\'observance des prises',
            const Color(0xFF9B59B6),
            () => ouvrir(PediPharmaScreen(enfant: enfant, acteur: pediatre)),
          ),
          _ligne(
            '🥗',
            'Nutrition',
            'Allergies, consignes, journal alimentaire',
            const Color(0xFF2ECC71),
            () => ouvrir(NutritionScreen(enfant: enfant, acteur: pediatre)),
          ),
        ],
      ),
    );
  }

  Widget _ligne(String emoji, String titre, String sousTitre, Color color,
      VoidCallback onTap) {
    return PcCard(
      color: color,
      onTap: onTap,
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700)),
                Text(sousTitre,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11.5)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
