import 'package:flutter/material.dart';
import '../../models/enfant_model.dart';
import '../../services/enfant_service.dart';
import '../../theme/app_colors.dart';
import '../croissance/croissance_screen.dart';
import '../vaccination/vaccination_screen.dart';
import '../rendezvous/rendezvous_screen.dart';

class EnfantDetailScreen extends StatelessWidget {
  final EnfantModel enfant;
  final VoidCallback? onDelete;

  const EnfantDetailScreen({
    super.key,
    required this.enfant,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isFille = enfant.sexe == 'F';
    final color = isFille ? const Color(0xFFE91E8C) : const Color(0xFF1E6FDB);
    final emoji = isFille ? '👧' : '👦';

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.backgroundGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppColors.textPrimary, size: 16),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Profil enfant',
                            style: TextStyle(color: AppColors.textPrimary,
                                fontSize: 20, fontWeight: FontWeight.w700)),
                        Text('Modules & suivi',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Profil card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 70, height: 70,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withOpacity(0.5), width: 2),
                        ),
                        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 36))),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(enfant.nomComplet,
                                style: const TextStyle(color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800, fontSize: 18)),
                            const SizedBox(height: 4),
                            Text(
                              '${enfant.age} ans · ${isFille ? "Fille" : "Garçon"}',
                              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            if (enfant.groupeSanguin != null) ...[
                              const SizedBox(height: 3),
                              Text('Groupe sanguin : ${enfant.groupeSanguin}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                            if (enfant.allergies != null) ...[
                              const SizedBox(height: 3),
                              Text('Allergies : ${enfant.allergies}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _confirmDelete(context),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                          ),
                          child: const Icon(Icons.delete_outline_rounded,
                              color: AppColors.danger, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),
                const Text('Modules',
                    style: TextStyle(color: AppColors.textPrimary,
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                  children: [
                    _ModuleCard(
                      emoji: '💉',
                      title: 'Vaccination',
                      subtitle: 'Vaccins & rappels',
                      color: const Color(0xFF00C9A7),
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => VaccinationScreen(
                          enfantId: enfant.id, enfantNom: enfant.nomComplet),
                      )),
                    ),
                    _ModuleCard(
                      emoji: '📅',
                      title: 'Rendez-vous',
                      subtitle: 'Consultations',
                      color: const Color(0xFF1E6FDB),
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => RendezVousScreen(
                          enfantId: enfant.id, enfantNom: enfant.nomComplet),
                      )),
                    ),
                    _ModuleCard(
                      emoji: '📏',
                      title: 'Croissance',
                      subtitle: 'Poids & taille',
                      color: const Color(0xFF9B59B6),
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => CroissanceScreen(
                          enfantId: enfant.id, enfantNom: enfant.nomComplet),
                      )),
                    ),
                    _ModuleCard(
                      emoji: '📋',
                      title: 'Carnet',
                      subtitle: 'Dossier médical',
                      color: const Color(0xFFE67E22),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Module en cours de développement...'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D2D5E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Supprimer le profil de ${enfant.nomComplet} ?',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await EnfantService.deleteEnfant(enfant.id);
              if (context.mounted) Navigator.pop(context);
              onDelete?.call();
            },
            child: const Text('Supprimer',
                style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(color: AppColors.textPrimary,
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
