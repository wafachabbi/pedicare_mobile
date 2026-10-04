import 'package:flutter/material.dart';
import '../../models/enfant_model.dart';
import '../../services/enfant_service.dart';
import '../../theme/app_colors.dart';
import 'add_enfant_screen.dart';
import '../croissance/croissance_screen.dart';
import '../vaccination/vaccination_screen.dart';
import '../rendezvous/rendezvous_screen.dart';

class EnfantsScreen extends StatefulWidget {
  final String parentId;
  final String parentNom;

  const EnfantsScreen({
    super.key,
    required this.parentId,
    required this.parentNom,
  });

  @override
  State<EnfantsScreen> createState() => _EnfantsScreenState();
}

class _EnfantsScreenState extends State<EnfantsScreen> {
  List<EnfantModel> _enfants = [];
  bool _loading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadEnfants();
  }

  Future<void> _loadEnfants() async {
    setState(() => _loading = true);
    final enfants = await EnfantService.getEnfants(widget.parentId);
    if (mounted) {
      setState(() {
        _enfants = enfants;
        _loading = false;
        if (_selectedIndex >= enfants.length) _selectedIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.backgroundGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              if (_loading)
                const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.secondary)))
              else if (_enfants.isEmpty)
                _buildEmpty()
              else ...[
                _buildChildTabs(),
                Expanded(child: _buildChildSpace(_enfants[_selectedIndex])),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
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
              Text('Mes enfants',
                  style: TextStyle(color: AppColors.textPrimary,
                      fontSize: 20, fontWeight: FontWeight.w700)),
              Text('Espace personnel de chaque enfant',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChildTabs() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _enfants.length,
        itemBuilder: (context, index) {
          final enfant = _enfants[index];
          final selected = index == _selectedIndex;
          final color = enfant.sexe == 'F' ? const Color(0xFFE91E8C) : const Color(0xFF1E6FDB);
          final emoji = enfant.sexe == 'F' ? '👧' : '👦';
          return GestureDetector(
            onTap: () => setState(() => _selectedIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.only(right: 12, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? color.withOpacity(0.2) : AppColors.inputFill,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? color : AppColors.glassBorder,
                  width: selected ? 2 : 1,
                ),
                boxShadow: selected
                    ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(height: 4),
                  Text(
                    enfant.prenom,
                    style: TextStyle(
                      color: selected ? color : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChildSpace(EnfantModel enfant) {
    final color = enfant.sexe == 'F' ? const Color(0xFFE91E8C) : const Color(0xFF1E6FDB);
    final emoji = enfant.sexe == 'F' ? '👧' : '👦';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: color.withOpacity(0.4), width: 2),
                  ),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 32))),
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
                        '${enfant.age} ans · ${enfant.sexe == "F" ? "Fille" : "Garçon"}',
                        style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      if (enfant.groupeSanguin != null) ...[
                        const SizedBox(height: 2),
                        Text('Groupe sanguin : ${enfant.groupeSanguin}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                      if (enfant.allergies != null) ...[
                        const SizedBox(height: 2),
                        Text('Allergies : ${enfant.allergies}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _confirmDelete(context, enfant),
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                    ),
                    child: Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 17),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text('Modules',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),

          // Modules grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
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
                  const SnackBar(content: Text('Module en cours de développement...'),
                      backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👶', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('Aucun enfant ajouté',
                style: TextStyle(color: AppColors.textPrimary,
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Ajoutez le profil de votre enfant',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => AddEnfantScreen(parentId: widget.parentId),
        ));
        _loadEnfants();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: AppColors.buttonGradient),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x441E6FDB), blurRadius: 16, offset: Offset(0, 6))
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Ajouter un enfant',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, EnfantModel enfant) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D2D5E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Supprimer le profil de ${enfant.nomComplet} ?',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await EnfantService.deleteEnfant(enfant.id);
              _loadEnfants();
            },
            child: const Text('Supprimer',
                style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Module Card ───────────────────────────────────────────────────────────────
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
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
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
