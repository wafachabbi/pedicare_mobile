import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class HomePediatreScreen extends StatelessWidget {
  final Map<String, dynamic> user;
  const HomePediatreScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user['name'] ?? 'Docteur';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'D';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A1628), Color(0xFF0A2340), Color(0xFF0D3B6E)],
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
                _buildProBanner(name),
                const SizedBox(height: 24),
                _buildStatsRow(),
                const SizedBox(height: 24),
                _buildSectionTitle('Mes outils'),
                const SizedBox(height: 14),
                _buildToolsGrid(),
                const SizedBox(height: 24),
                _buildSectionTitle('Prochaines consultations'),
                const SizedBox(height: 14),
                _buildConsultations(),
                const SizedBox(height: 24),
                _buildSectionTitle('Demandes en attente'),
                const SizedBox(height: 14),
                _buildPendingRequests(),
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
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF00C9A7).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00C9A7).withOpacity(0.5)),
              ),
              child: const Text('PRO',
                  style: TextStyle(
                      color: Color(0xFF00C9A7),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1)),
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
                  color: const Color(0xFF00C9A7).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                      color: const Color(0xFF00C9A7).withOpacity(0.5)),
                ),
                child: Center(
                  child: Text(initials,
                      style: const TextStyle(
                          color: Color(0xFF00C9A7),
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

  Widget _buildProBanner(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00855A), Color(0xFF00C9A7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x4400C9A7), blurRadius: 20, offset: Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dr. $name',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                const Text('Espace Pédiatre',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('Pédiatre certifié',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _bannerChip('3 en attente', Icons.pending_outlined),
                    const SizedBox(width: 8),
                    _bannerChip('5 aujourd\'hui', Icons.calendar_today_outlined),
                  ],
                ),
              ],
            ),
          ),
          const Text('👨‍⚕️', style: TextStyle(fontSize: 60)),
        ],
      ),
    );
  }

  Widget _bannerChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _StatCard(value: '128', label: 'Patients', emoji: '👶', color: const Color(0xFF1E6FDB)),
        const SizedBox(width: 12),
        _StatCard(value: '5', label: 'Aujourd\'hui', emoji: '📅', color: const Color(0xFF00C9A7)),
        const SizedBox(width: 12),
        _StatCard(value: '3', label: 'En attente', emoji: '⏳', color: const Color(0xFFE67E22)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700));
  }

  Widget _buildToolsGrid() {
    final tools = [
      {'emoji': '👥', 'title': 'Mes\nPatients', 'color': const Color(0xFF1E6FDB)},
      {'emoji': '📅', 'title': 'Agenda &\nPlanning', 'color': const Color(0xFF00C9A7)},
      {'emoji': '📋', 'title': 'Comptes\nrendus', 'color': const Color(0xFF9B59B6)},
      {'emoji': '💬', 'title': 'Messagerie\nsécurisée', 'color': const Color(0xFFE67E22)},
      {'emoji': '🎥', 'title': 'Télé-\nconsultation', 'color': const Color(0xFFE74C3C)},
      {'emoji': '📊', 'title': 'Statistiques', 'color': const Color(0xFF3498DB)},
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: tools
          .map((t) => _ToolCard(
              emoji: t['emoji'] as String,
              title: t['title'] as String,
              color: t['color'] as Color))
          .toList(),
    );
  }

  Widget _buildConsultations() {
    final items = [
      {'name': 'Famille Benali', 'time': '09:00', 'type': 'Présentiel', 'color': const Color(0xFF1E6FDB)},
      {'name': 'Famille Chabbi', 'time': '10:30', 'type': 'Vidéo', 'color': const Color(0xFF00C9A7)},
      {'name': 'Famille Trabelsi', 'time': '14:00', 'type': 'Présentiel', 'color': const Color(0xFF1E6FDB)},
    ];
    return Column(
      children: items.map((item) {
        final color = item['color'] as Color;
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    item['time'] as String,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'] as String,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                    Text('Consultation pédiatrique',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Text(item['type'] as String,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPendingRequests() {
    final requests = [
      {'name': 'Famille Ghazouani', 'date': 'Demain', 'note': 'Fièvre persistante'},
      {'name': 'Famille Balloumi', 'date': 'Cette semaine', 'note': 'Suivi vaccins'},
      {'name': 'Famille Juili', 'date': 'Flexible', 'note': 'Consultation de routine'},
    ];
    return Column(
      children: requests.map((r) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0x14E67E22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x33E67E22)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0x22E67E22),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                  child: Text('👶', style: TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r['name']!,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  Text(r['note']!,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            Column(
              children: [
                Text(r['date']!,
                    style: const TextStyle(
                        color: Color(0xFFE67E22),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _actionBtn(Icons.check_rounded, const Color(0xFF00C9A7)),
                    const SizedBox(width: 6),
                    _actionBtn(Icons.close_rounded, const Color(0xFFE74C3C)),
                  ],
                ),
              ],
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _actionBtn(IconData icon, Color color) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Icon(icon, color: color, size: 14),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D2D5E),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Déconnexion',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        content: const Text('Voulez-vous vous déconnecter ?',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler',
                  style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await AuthService.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                      (_) => false);
                }
              },
              child: const Text('Déconnecter',
                  style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String emoji;
  final Color color;
  const _StatCard(
      {required this.value,
      required this.label,
      required this.emoji,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final String emoji;
  final String title;
  final Color color;
  const _ToolCard(
      {required this.emoji, required this.title, required this.color});

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
