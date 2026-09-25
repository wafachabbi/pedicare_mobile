import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class HomeParentScreen extends StatelessWidget {
  final Map<String, dynamic> user;
  const HomeParentScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user['name'] ?? 'Parent';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'P';

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildTopBar(context, name, initials),
                const SizedBox(height: 24),
                _buildBanner(name),
                const SizedBox(height: 24),
                _buildChildCard(),
                const SizedBox(height: 24),
                _buildSectionTitle('Mes modules'),
                const SizedBox(height: 14),
                _buildModulesGrid(),
                const SizedBox(height: 24),
                _buildSectionTitle('Activité récente'),
                const SizedBox(height: 14),
                _buildActivity(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, String name, String initials) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text('🩺', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Colors.white, Color(0xFF4DAAFF)],
              ).createShader(b),
              child: const Text('PediCare AI',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        Row(
          children: [
            _iconBtn(Icons.notifications_outlined),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _logout(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppColors.buttonGradient),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: Text(initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _iconBtn(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Icon(icon, color: AppColors.textPrimary, size: 18),
    );
  }

  Widget _buildBanner(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E6FDB), Color(0xFF4DAAFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x441E6FDB), blurRadius: 20, offset: Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bonjour, $name 👋',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                const Text('Espace Parent',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Voir le carnet →',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const Text('👨‍👩‍👦', style: TextStyle(fontSize: 56)),
        ],
      ),
    );
  }

  Widget _buildChildCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0x221E6FDB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x441E6FDB)),
            ),
            child: const Center(child: Text('👶', style: TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mon enfant',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                SizedBox(height: 3),
                Text('Aucun profil ajouté — Commencer',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.buttonGradient),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700));
  }

  Widget _buildModulesGrid() {
    final modules = [
      {'emoji': '📋', 'title': 'Carnet\nde l\'enfant', 'color': const Color(0xFF1E6FDB)},
      {'emoji': '💉', 'title': 'Vaccination &\nRendez-vous', 'color': const Color(0xFF00C9A7)},
      {'emoji': '📊', 'title': 'Tableau\nde bord', 'color': const Color(0xFF9B59B6)},
      {'emoji': '💊', 'title': 'PediPharma', 'color': const Color(0xFFE74C3C)},
      {'emoji': '👨‍⚕️', 'title': 'Mon\nPédiatre', 'color': const Color(0xFFE67E22)},
      {'emoji': '🤖', 'title': 'Assistant\nIA', 'color': const Color(0xFF3498DB)},
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: modules
          .map((m) => _ModuleCard(
              emoji: m['emoji'] as String,
              title: m['title'] as String,
              color: m['color'] as Color))
          .toList(),
    );
  }

  Widget _buildActivity() {
    final items = [
      {'emoji': '💉', 'title': 'Prochain vaccin dans 7 jours', 'tag': 'Rappel', 'color': const Color(0xFF00C9A7)},
      {'emoji': '📅', 'title': 'Consultation pédiatre planifiée', 'tag': 'Dans 3 jours', 'color': const Color(0xFF1E6FDB)},
      {'emoji': '💊', 'title': 'Traitement en cours — Jour 4/7', 'tag': 'Actif', 'color': const Color(0xFFE74C3C)},
    ];
    return Column(
      children: items.map((item) => _ActivityTile(
        emoji: item['emoji'] as String,
        title: item['title'] as String,
        tag: item['tag'] as String,
        color: item['color'] as Color,
      )).toList(),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _LogoutDialog(onConfirm: () async {
        await AuthService.logout();
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false);
        }
      }),
    );
  }
}

// ─── Dashboard Pédiatre ────────────────────────────────────────────────────────

class _ModuleCard extends StatelessWidget {
  final String emoji;
  final String title;
  final Color color;
  const _ModuleCard({required this.emoji, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          Text(title,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.3)),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String tag;
  final Color color;
  const _ActivityTile(
      {required this.emoji,
      required this.title,
      required this.tag,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
            child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Text(tag,
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _LogoutDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  const _LogoutDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0D2D5E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Déconnexion',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      content: const Text('Voulez-vous vous déconnecter ?',
          style: TextStyle(color: AppColors.textSecondary)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.textSecondary))),
        TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Déconnecter',
                style: TextStyle(
                    color: AppColors.danger, fontWeight: FontWeight.w700))),
      ],
    );
  }
}
