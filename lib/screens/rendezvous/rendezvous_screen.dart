import 'package:flutter/material.dart';
import '../../models/rendezvous_model.dart';
import '../../services/rendezvous_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import 'add_rendezvous_screen.dart';

class RendezVousScreen extends StatefulWidget {
  final String enfantId;
  final String enfantNom;

  const RendezVousScreen({
    super.key,
    required this.enfantId,
    required this.enfantNom,
  });

  @override
  State<RendezVousScreen> createState() => _RendezVousScreenState();
}

class _RendezVousScreenState extends State<RendezVousScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<RendezVousModel> _rdvs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final rdvs = await RendezVousService.getRendezVous(widget.enfantId);
    if (mounted) {
      setState(() { _rdvs = rdvs; _loading = false; });
      // Planifier les rappels pour les RDV à venir
      final prochains = rdvs.where((r) =>
          r.dateHeure.isAfter(DateTime.now()) &&
          r.statut != StatutRDV.annule).toList();
      await NotificationService.planifierRappelsRDV(
          prochains, widget.enfantNom);
    }
  }

  List<RendezVousModel> get _prochains {
    final now = DateTime.now();
    return _rdvs
        .where((r) => r.dateHeure.isAfter(now) && r.statut != StatutRDV.annule)
        .toList();
  }

  List<RendezVousModel> get _passes {
    final now = DateTime.now();
    return _rdvs
        .where((r) => r.dateHeure.isBefore(now) || r.statut == StatutRDV.termine)
        .toList();
  }

  List<RendezVousModel> get _annules =>
      _rdvs.where((r) => r.statut == StatutRDV.annule).toList();

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
              _buildProchainCard(),
              _buildTabBar(),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildList(_prochains, 'À venir'),
                          _buildList(_passes, 'Passés'),
                          _buildList(_annules, 'Annulés'),
                        ],
                      ),
              ),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Rendez-vous',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
              Text(widget.enfantNom,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProchainCard() {
    if (_prochains.isEmpty) return const SizedBox.shrink();
    final prochain = _prochains.first;
    final jours = prochain.dateHeure.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E6FDB), Color(0xFF4DAAFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x441E6FDB), blurRadius: 16, offset: Offset(0, 6))
        ],
      ),
      child: Row(
        children: [
          const Text('📅', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Prochain rendez-vous',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text(prochain.titre,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                Text('Dr. ${prochain.medecin} • ${prochain.specialite}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              jours == 0 ? "Aujourd'hui" : 'Dans $jours j.',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(colors: AppColors.buttonGradient),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        tabs: [
          Tab(text: 'À venir (${_prochains.length})'),
          Tab(text: 'Passés (${_passes.length})'),
          Tab(text: 'Annulés'),
        ],
      ),
    );
  }

  Widget _buildList(List<RendezVousModel> rdvs, String type) {
    if (rdvs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📭', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Aucun rendez-vous $type'.toLowerCase(),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: rdvs.length,
      itemBuilder: (context, i) => _RDVTile(
        rdv: rdvs[i],
        onStatusChange: (statut) async {
          await RendezVousService.updateRendezVous(rdvs[i].copyWith(statut: statut));
          if (statut == StatutRDV.annule) {
            await NotificationService.annulerRappelsRDV(rdvs[i].id);
          }
          _loadData();
        },
        onDelete: () async {
          await RendezVousService.deleteRendezVous(rdvs[i].enfantId, rdvs[i].id);
          await NotificationService.annulerRappelsRDV(rdvs[i].id);
          _loadData();
        },
        onEdit: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddRendezVousScreen(
                  enfantId: widget.enfantId, rdv: rdvs[i]),
            ),
          );
          _loadData();
        },
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddRendezVousScreen(enfantId: widget.enfantId),
          ),
        );
        _loadData();
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
            Text('Nouveau RDV',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ── Tuile RDV ─────────────────────────────────────────────────────────────────
class _RDVTile extends StatelessWidget {
  final RendezVousModel rdv;
  final Function(StatutRDV) onStatusChange;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _RDVTile({
    required this.rdv,
    required this.onStatusChange,
    required this.onDelete,
    required this.onEdit,
  });

  Color get _statutColor {
    switch (rdv.statut) {
      case StatutRDV.confirme: return const Color(0xFF00C9A7);
      case StatutRDV.enAttente: return const Color(0xFFE67E22);
      case StatutRDV.annule: return AppColors.danger;
      case StatutRDV.termine: return AppColors.textSecondary;
    }
  }

  String get _statutLabel {
    switch (rdv.statut) {
      case StatutRDV.confirme: return 'Confirmé';
      case StatutRDV.enAttente: return 'En attente';
      case StatutRDV.annule: return 'Annulé';
      case StatutRDV.termine: return 'Terminé';
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E6FDB).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(rdv.type == 'video' ? '🎥' : '🏥',
                    style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rdv.titre,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    Text('Dr. ${rdv.medecin} • ${rdv.specialite}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statutColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _statutColor.withOpacity(0.4)),
                ),
                child: Text(_statutLabel,
                    style: TextStyle(
                        color: _statutColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E6FDB).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    color: AppColors.textSecondary, size: 14),
                const SizedBox(width: 6),
                Text(_formatDateTime(rdv.dateHeure),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                if (rdv.lieu.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.location_on_outlined,
                      color: AppColors.textSecondary, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(rdv.lieu,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ActionBtn(
                  label: 'Modifier',
                  icon: Icons.edit_outlined,
                  color: AppColors.secondary,
                  onTap: onEdit),
              const SizedBox(width: 8),
              if (rdv.statut != StatutRDV.annule)
                _ActionBtn(
                    label: 'Annuler',
                    icon: Icons.cancel_outlined,
                    color: AppColors.danger,
                    onTap: () => onStatusChange(StatutRDV.annule)),
              if (rdv.statut == StatutRDV.enAttente) ...[
                const SizedBox(width: 8),
                _ActionBtn(
                    label: 'Confirmer',
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF00C9A7),
                    onTap: () => onStatusChange(StatutRDV.confirme)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${days[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]} ${dt.year} — ${dt.hour.toString().padLeft(2, '0')}h${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
