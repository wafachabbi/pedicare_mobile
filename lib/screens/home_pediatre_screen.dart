import 'package:flutter/material.dart';
import '../models/rendezvous_model.dart';
import '../services/auth_service.dart';
import '../services/rendezvous_service.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';

class HomePediatreScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const HomePediatreScreen({super.key, required this.user});

  @override
  State<HomePediatreScreen> createState() => _HomePediatreScreenState();
}

class _HomePediatreScreenState extends State<HomePediatreScreen> {
  List<RendezVousModel> _rdvs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRDVs();
  }

  Future<void> _loadRDVs() async {
    setState(() => _loading = true);
    final id = (widget.user['id'] ?? widget.user['uid'] ?? '').toString();
    final rdvs = await RendezVousService.getRendezVousPediatre(id);
    if (mounted) setState(() { _rdvs = rdvs; _loading = false; });
  }

  List<RendezVousModel> get _prochains {
    final now = DateTime.now();
    return _rdvs.where((r) =>
        r.dateHeure.isAfter(now) && r.statut != StatutRDV.annule).toList();
  }

  List<RendezVousModel> get _enAttente =>
      _rdvs.where((r) => r.statut == StatutRDV.enAttente).toList();

  @override
  Widget build(BuildContext context) {
    final name = widget.user['name'] ?? 'Docteur';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'D';

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A1628), Color(0xFF0A2340), Color(0xFF0D3B6E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: const Color(0xFF00C9A7),
            backgroundColor: const Color(0xFF0D2D5E),
            onRefresh: _loadRDVs,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                  _buildSectionTitle('Prochains rendez-vous'),
                  const SizedBox(height: 14),
                  _loading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C9A7)))
                      : _buildProchains(),
                  const SizedBox(height: 24),
                  if (_enAttente.isNotEmpty) ...[
                    _buildSectionTitle('Demandes en attente'),
                    const SizedBox(height: 14),
                    _buildEnAttente(),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, String name, String initials) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          const Text('🩺', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
                colors: [Colors.white, Color(0xFF4DAAFF)]).createShader(b),
            child: const Text('PediCare AI',
                style: TextStyle(color: Colors.white,
                    fontSize: 17, fontWeight: FontWeight.w800)),
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
                style: TextStyle(color: Color(0xFF00C9A7),
                    fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
          ),
        ]),
        Row(children: [
          _iconBtn(Icons.refresh_rounded, onTap: _loadRDVs),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _logout(context),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF00C9A7).withOpacity(0.2),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: const Color(0xFF00C9A7).withOpacity(0.5)),
              ),
              child: Center(child: Text(initials,
                  style: const TextStyle(color: Color(0xFF00C9A7),
                      fontWeight: FontWeight.w700, fontSize: 14))),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _iconBtn(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 18),
      ),
    );
  }

  // ── Banner ────────────────────────────────────────────────────────────────
  Widget _buildProBanner(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00855A), Color(0xFF00C9A7)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x4400C9A7), blurRadius: 20, offset: Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dr. $name',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              const Text('Espace Pédiatre',
                  style: TextStyle(color: Colors.white,
                      fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              Row(children: [
                _bannerChip('${_enAttente.length} en attente', Icons.pending_outlined),
                const SizedBox(width: 8),
                _bannerChip('${_prochains.length} à venir', Icons.calendar_today_outlined),
              ]),
            ],
          )),
          const Text('👨‍⚕️', style: TextStyle(fontSize: 60)),
        ],
      ),
    );
  }

  Widget _bannerChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: Colors.white24, borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 12),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ── Stats ─────────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    final aujourd = _rdvs.where((r) {
      final now = DateTime.now();
      return r.dateHeure.year == now.year &&
          r.dateHeure.month == now.month &&
          r.dateHeure.day == now.day;
    }).length;

    return Row(children: [
      _StatCard(value: '${_rdvs.length}', label: 'Total RDV',
          emoji: '📋', color: const Color(0xFF1E6FDB)),
      const SizedBox(width: 12),
      _StatCard(value: '$aujourd', label: "Aujourd'hui",
          emoji: '📅', color: const Color(0xFF00C9A7)),
      const SizedBox(width: 12),
      _StatCard(value: '${_enAttente.length}', label: 'En attente',
          emoji: '⏳', color: const Color(0xFFE67E22)),
    ]);
  }

  // ── Prochains RDV ─────────────────────────────────────────────────────────
  Widget _buildProchains() {
    if (_prochains.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: const Center(
          child: Column(children: [
            Text('📭', style: TextStyle(fontSize: 40)),
            SizedBox(height: 8),
            Text('Aucun rendez-vous à venir',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ]),
        ),
      );
    }
    return Column(
      children: _prochains.map((rdv) => _RDVPediatreTile(
        rdv: rdv,
        onConfirm: () => _updateStatut(rdv, StatutRDV.confirme),
        onTermine: () => _updateStatut(rdv, StatutRDV.termine),
        onAnnule: () => _updateStatut(rdv, StatutRDV.annule),
      )).toList(),
    );
  }

  // ── En attente ────────────────────────────────────────────────────────────
  Widget _buildEnAttente() {
    return Column(
      children: _enAttente.map((rdv) => _RDVPediatreTile(
        rdv: rdv,
        onConfirm: () => _updateStatut(rdv, StatutRDV.confirme),
        onTermine: () => _updateStatut(rdv, StatutRDV.termine),
        onAnnule: () => _updateStatut(rdv, StatutRDV.annule),
      )).toList(),
    );
  }

  Future<void> _updateStatut(RendezVousModel rdv, StatutRDV statut) async {
    await RendezVousService.updateRendezVous(rdv.copyWith(statut: statut));
    _loadRDVs();
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(color: AppColors.textPrimary,
            fontSize: 16, fontWeight: FontWeight.w700));
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D2D5E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Déconnexion',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: const Text('Voulez-vous vous déconnecter ?',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Annuler',
                  style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false);
              }
            },
            child: const Text('Déconnecter',
                style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Tuile RDV pédiatre ────────────────────────────────────────────────────────
class _RDVPediatreTile extends StatelessWidget {
  final RendezVousModel rdv;
  final VoidCallback onConfirm;
  final VoidCallback onTermine;
  final VoidCallback onAnnule;

  const _RDVPediatreTile({
    required this.rdv,
    required this.onConfirm,
    required this.onTermine,
    required this.onAnnule,
  });

  Color get _statutColor {
    switch (rdv.statut) {
      case StatutRDV.confirme:  return const Color(0xFF00C9A7);
      case StatutRDV.enAttente: return const Color(0xFFE67E22);
      case StatutRDV.annule:    return AppColors.danger;
      case StatutRDV.termine:   return AppColors.textSecondary;
    }
  }

  String get _statutLabel {
    switch (rdv.statut) {
      case StatutRDV.confirme:  return 'Confirmé';
      case StatutRDV.enAttente: return 'En attente';
      case StatutRDV.annule:    return 'Annulé';
      case StatutRDV.termine:   return 'Terminé';
    }
  }

  @override
  Widget build(BuildContext context) {
    final jours = rdv.dateHeure.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF00C9A7).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(rdv.type == 'video' ? '🎥' : '👶',
                  style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rdv.enfantNomComplet ?? rdv.titre,
                    style: const TextStyle(color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text(rdv.titre,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                if (rdv.parentNom != null)
                  Text('Parent : ${rdv.parentNom}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
              ],
            )),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statutColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _statutColor.withOpacity(0.4)),
                ),
                child: Text(_statutLabel,
                    style: TextStyle(color: _statutColor,
                        fontSize: 10, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 4),
              Text(jours == 0 ? "Auj." : jours == 1 ? 'Demain' : 'Dans $jours j.',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 10)),
            ]),
          ]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E6FDB).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Icon(Icons.access_time_rounded,
                  color: AppColors.textSecondary, size: 14),
              const SizedBox(width: 6),
              Text(_formatDateTime(rdv.dateHeure),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              if (rdv.lieu.isNotEmpty) ...[
                const SizedBox(width: 10),
                const Icon(Icons.location_on_outlined,
                    color: AppColors.textSecondary, size: 14),
                const SizedBox(width: 4),
                Expanded(child: Text(rdv.lieu,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                    overflow: TextOverflow.ellipsis)),
              ],
            ]),
          ),
          const SizedBox(height: 10),
          Row(children: [
            if (rdv.statut == StatutRDV.enAttente)
              _btn('Confirmer', Icons.check_circle_outline,
                  const Color(0xFF00C9A7), onConfirm),
            if (rdv.statut == StatutRDV.confirme) ...[
              _btn('Terminé', Icons.done_all_rounded,
                  const Color(0xFF1E6FDB), onTermine),
              const SizedBox(width: 8),
            ],
            if (rdv.statut != StatutRDV.annule &&
                rdv.statut != StatutRDV.termine) ...[
              const SizedBox(width: 8),
              _btn('Annuler', Icons.cancel_outlined, AppColors.danger, onAnnule),
            ],
          ]),
        ],
      ),
    );
  }

  Widget _btn(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
        'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${days[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]} '
        '${dt.year} — ${dt.hour.toString().padLeft(2, '0')}h'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String emoji;
  final Color color;
  const _StatCard({required this.value, required this.label,
      required this.emoji, required this.color});

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
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color,
              fontSize: 18, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 10)),
        ]),
      ),
    );
  }
}
