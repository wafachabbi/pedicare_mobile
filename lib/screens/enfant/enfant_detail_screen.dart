import 'package:flutter/material.dart';
import '../../models/enfant_model.dart';
import '../../models/pediatre_model.dart';
import '../../services/carnet_pdf_service.dart';
import '../../services/document_service.dart';
import '../../services/enfant_service.dart';
import '../../services/pediatre_service.dart';
import '../../theme/app_colors.dart';
import '../assistant/assistant_screen.dart';
import '../consultation/consultation_screen.dart';
import '../croissance/croissance_screen.dart';
import '../dashboard/tableau_bord_screen.dart';
import '../documents/documents_screen.dart';
import '../journal/journal_symptomes_screen.dart';
import '../nutrition/nutrition_screen.dart';
import '../pharma/pedipharma_screen.dart';
import '../vaccination/vaccination_screen.dart';
import '../rendezvous/rendezvous_screen.dart';
import '../eveil/eveil_screen.dart';

class EnfantDetailScreen extends StatefulWidget {
  final EnfantModel enfant;
  final VoidCallback? onDelete;

  const EnfantDetailScreen({
    super.key,
    required this.enfant,
    this.onDelete,
  });

  @override
  State<EnfantDetailScreen> createState() => _EnfantDetailScreenState();
}

class _EnfantDetailScreenState extends State<EnfantDetailScreen> {
  EnfantModel get enfant => widget.enfant;
  VoidCallback? get onDelete => widget.onDelete;

  late bool _partageJournal;
  List<PediatreModel> _pediatres = [];
  String? _pediatreSelectionne; // ID du pédiatre choisi par le parent
  int _nbDocuments = 0;
  bool _exportingPdf = false;

  @override
  void initState() {
    super.initState();
    _partageJournal = enfant.partageJournal;
    _pediatreSelectionne = enfant.pediatreId;
    _chargerPediatres();
    _chargerNbDocuments();
  }

  Future<void> _chargerNbDocuments() async {
    final n = await DocumentService.compterDocuments(enfant.id);
    if (mounted) setState(() => _nbDocuments = n);
  }

  Future<void> _chargerPediatres() async {
    final list = await PediatreService.getPediatres();
    setState(() => _pediatres = list);
  }

  Future<void> _basculerPartage(bool valeur) async {
    setState(() => _partageJournal = valeur);

    // Si on active le partage, on demande de choisir un pédiatre
    if (valeur && _pediatres.isNotEmpty) {
      // Show bottom sheet for pediatrician selection
      final String? result = await showModalBottomSheet<String?>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF0D2D5E),
        builder: (_) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Choisir le pédiatre',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const Divider(color: Colors.white24),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _pediatres.length,
                  itemBuilder: (context, index) {
                    final pediatre = _pediatres[index];
                    return ListTile(
                      title: Text(pediatre.name,
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text(pediatre.email,
                          style: TextStyle(color: Colors.white70)),
                      tileColor: const Color(0xFF162d4e),
                      onTap: () => Navigator.pop(context, pediatre.id),
                    );
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Aucun (personne n\'aura accès)',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Aucun pédiatre'),
              ),
            ],
          ),
        ),
      );

      if (result != null) {
        _pediatreSelectionne = result;
      } else {
        _pediatreSelectionne = null;
      }
    }

    final ok = await EnfantService.setPartageJournal(
        enfant.id, valeur, pediatreId: _pediatreSelectionne);
    if (!mounted) return;
    if (!ok) {
      setState(() => _partageJournal = !valeur);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mise à jour du partage impossible.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

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
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 70, height: 70,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
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
                            color: AppColors.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.delete_outline_rounded,
                              color: AppColors.danger, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),
                _buildPartageCard(),
                const SizedBox(height: 22),
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
                  childAspectRatio: 1.15,
                  children: [
                    _ModuleCard(
                      emoji: '📊',
                      title: 'Tableau de bord',
                      subtitle: 'Vue d\'ensemble',
                      color: const Color(0xFF4DAAFF),
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => TableauBordScreen(enfant: enfant),
                      )),
                    ),
                    _ModuleCard(
                      emoji: '📝',
                      title: 'Journal santé',
                      subtitle: 'Symptômes du jour',
                      color: const Color(0xFF00C9A7),
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => JournalSymptomesScreen(enfant: enfant),
                      )),
                    ),
                    _ModuleCard(
                      emoji: '🩺',
                      title: 'Consultation',
                      subtitle: 'Résumé & historique',
                      color: const Color(0xFFE67E22),
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ConsultationScreen(enfant: enfant),
                      )),
                    ),
                    _ModuleCard(
                      emoji: '💉',
                      title: 'Vaccination',
                      subtitle: 'Vaccins & rappels',
                      color: const Color(0xFF00C9A7),
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => VaccinationScreen(
                          enfantId: enfant.id,
                          enfantNom: enfant.nomComplet,
                          enfant: enfant,
                        ),
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
                          enfantId: enfant.id,
                          enfantNom: enfant.nomComplet,
                          enfantSexe: enfant.sexe,
                          enfantAge: '${enfant.age} ans',
                          dateNaissance: enfant.dateNaissance,
                        ),
                      )),
                    ),
                    _ModuleCard(
                      emoji: '💊',
                      title: 'PediPharma',
                      subtitle: 'Traitements & prises',
                      color: const Color(0xFF9B59B6),
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => PediPharmaScreen(enfant: enfant),
                      )),
                    ),
                    _ModuleCard(
                      emoji: '🥗',
                      title: 'Nutrition',
                      subtitle: 'Repas, allergies, recettes',
                      color: const Color(0xFF2ECC71),
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => NutritionScreen(enfant: enfant),
                      )),
                    ),
                    _ModuleCard(
                      emoji: '🤖',
                      title: 'Assistant IA',
                      subtitle: 'Questions santé',
                      color: const Color(0xFF4285F4),
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => AssistantScreen(enfant: enfant),
                      )),
                    ),
                    // ── Module Éveil & Jeux (Arij) ──
                    _ModuleCard(
                      emoji: '🎨',
                      title: 'Éveil & Jeux',
                      subtitle: 'Apprendre en jouant',
                      color: const Color(0xFFFF8A00),
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => EveilScreen(enfant: enfant),
                      )),
                    ),
                    // ── Module Documents médicaux ──
                    _ModuleCard(
                      emoji: '📋',
                      title: 'Documents',
                      subtitle: '$_nbDocuments doc${_nbDocuments > 1 ? "s" : ""}',
                      color: const Color(0xFF9B59B6),
                      onTap: () async {
                        final user = {
                          'id': enfant.parentId,
                          'name': '',
                          'role': 'parent',
                        };
                        await Navigator.push(context, MaterialPageRoute(
                          builder: (_) => DocumentsScreen(
                            enfant: enfant,
                            user: user,
                          ),
                        ));
                        _chargerNbDocuments();
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                // ── Exporter carnet PDF ──────────────────────────────
                GestureDetector(
                  onTap: _exportingPdf ? null : _exporterCarnetPdf,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E6FDB), Color(0xFF4DAAFF)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x441E6FDB),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _exportingPdf
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('📄', style: TextStyle(fontSize: 18)),
                                SizedBox(width: 10),
                                Text(
                                  'Exporter le carnet de santé (PDF)',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPartageCard() {
    // Détermine le libellé selon l'état actuel
    String libellePartage() {
      if (!_partageJournal) return 'Partager le dossier avec un pédiatre';
      if (_pediatreSelectionne != null && _pediatreSelectionne!.isNotEmpty) {
        // Trouver le nom du pédiatre sélectionné
        final p = _pediatres.firstWhere(
          (e) => e.id == _pediatreSelectionne,
          orElse: () => PediatreModel(id: '', name: 'Pédiatre inconnu', email: ''),
        );
        return 'Dossier partagé avec le Dr. ${p.name}';
      }
      return 'Partage activé sans pédiatre';
    }

    String sousTitre() {
      if (!_partageJournal) {
        return 'Le pédiatre choisi pourra lire le journal de santé et les '
            'résumés, prescrire les traitements et gérer la nutrition.';
      }
      if (_pediatreSelectionne != null && _pediatreSelectionne!.isNotEmpty) {
        return 'Il lit le journal de santé et les résumés, prescrit les '
            'traitements et gère la nutrition. Désactivez pour retirer l\'accès.';
      }
      return 'Aucun pédiatre n\'y a accès : désactivez puis réactivez pour en choisir un.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF00C9A7).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF00C9A7).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF00C9A7).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('🩺', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(libellePartage(),
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(
                  sousTitre(),
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 10.5, height: 1.3),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _partageJournal,
            activeThumbColor: const Color(0xFF00C9A7),
            onChanged: _basculerPartage,
          ),
        ],
      ),
    );
  }

  Future<void> _exporterCarnetPdf() async {
    setState(() => _exportingPdf = true);
    try {
      await CarnetPdfService.genererEtPartager(enfant);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export PDF impossible : $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
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
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
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