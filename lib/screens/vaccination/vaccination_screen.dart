import 'package:flutter/material.dart';
import '../../models/vaccin_model.dart';
import '../../services/vaccin_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import 'add_vaccin_screen.dart';
import 'vaccin_detail_screen.dart';
import '../rendezvous/rendezvous_screen.dart';

class VaccinationScreen extends StatefulWidget {
  final String enfantId;
  final String enfantNom;

  const VaccinationScreen({
    super.key,
    required this.enfantId,
    required this.enfantNom,
  });

  @override
  State<VaccinationScreen> createState() => _VaccinationScreenState();
}

class _VaccinationScreenState extends State<VaccinationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<VaccinModel> _vaccins = [];
  List<VaccinModel> _echeances = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final vaccins = await VaccinService.getVaccins(widget.enfantId);
    final echeances = await VaccinService.getProchainesEcheances(widget.enfantId);
    if (mounted) {
      setState(() {
        _vaccins = vaccins;
        _echeances = echeances;
        _loading = false;
      });
      // Planifier les rappels pour les échéances à venir
      await NotificationService.planifierRappelsVaccins(
          echeances, widget.enfantNom);
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
              _buildStats(),
              const SizedBox(height: 8),
              _buildTabBar(),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildHistorique(),
                          _buildEcheances(),
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
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
              const Text('Vaccination',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              Text(widget.enfantNom,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _StatChip(
            label: 'Vaccins administrés',
            value: '${_vaccins.length}',
            color: const Color(0xFF00C9A7),
            emoji: '💉',
          ),
          const SizedBox(width: 12),
          _StatChip(
            label: 'Prochaines échéances',
            value: '${_echeances.length}',
            color: const Color(0xFFE67E22),
            emoji: '📅',
          ),
        ],
      ),
    );
  }

  Widget _buildRDVButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RendezVousScreen(
            enfantId: widget.enfantId,
            enfantNom: widget.enfantNom,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E6FDB), Color(0xFF4DAAFF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: Color(0x441E6FDB),
                blurRadius: 12,
                offset: Offset(0, 4))
          ],
        ),
        child: const Row(
          children: [
            Text('📅', style: TextStyle(fontSize: 22)),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rendez-vous médicaux',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  Text('Gérer les consultations',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(text: 'Historique'),
          Tab(text: 'Prochaines échéances'),
        ],
      ),
    );
  }

  Widget _buildHistorique() {
    if (_vaccins.isEmpty) {
      return _buildEmptyState(
        '💉',
        'Aucun vaccin enregistré',
        'Ajoutez le premier vaccin de ${widget.enfantNom}',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _vaccins.length,
      itemBuilder: (context, index) => _VaccinTile(
        vaccin: _vaccins[index],
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VaccinDetailScreen(
                vaccin: _vaccins[index],
                onDelete: () async {
                  await VaccinService.deleteVaccin(_vaccins[index].enfantId, _vaccins[index].id);
                  _loadData();
                },
              ),
            ),
          );
          _loadData();
        },
      ),
    );
  }

  Widget _buildEcheances() {
    if (_echeances.isEmpty) {
      return _buildEmptyState(
        '✅',
        'Aucune échéance à venir',
        'Toutes les vaccinations sont à jour !',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _echeances.length,
      itemBuilder: (context, index) =>
          _EcheanceTile(vaccin: _echeances[index]),
    );
  }

  Widget _buildEmptyState(String emoji, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddVaccinScreen(enfantId: widget.enfantId),
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
            BoxShadow(
                color: Color(0x441E6FDB),
                blurRadius: 16,
                offset: Offset(0, 6))
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Ajouter un vaccin',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ── Tuile vaccin ──────────────────────────────────────────────────────────────
class _VaccinTile extends StatelessWidget {
  final VaccinModel vaccin;
  final VoidCallback onTap;

  const _VaccinTile({required this.vaccin, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF00C9A7).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                  child: Text('💉', style: TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vaccin.nom,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(vaccin.maladie,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 3),
                  Text(
                    'Dr. ${vaccin.medecin} • ${_fmt(vaccin.dateAdministre)}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ── Tuile échéance ────────────────────────────────────────────────────────────
class _EcheanceTile extends StatelessWidget {
  final VaccinModel vaccin;
  const _EcheanceTile({required this.vaccin});

  @override
  Widget build(BuildContext context) {
    final jours = vaccin.prochaineDate!.difference(DateTime.now()).inDays;
    final urgent = jours <= 7;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: urgent
            ? const Color(0xFFE67E22).withOpacity(0.1)
            : AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: urgent
              ? const Color(0xFFE67E22).withOpacity(0.4)
              : AppColors.glassBorder,
        ),
      ),
      child: Row(
        children: [
          Text(urgent ? '⚠️' : '📅', style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rappel : ${vaccin.nom}',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                const SizedBox(height: 3),
                Text(vaccin.maladie,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: urgent
                  ? const Color(0xFFE67E22).withOpacity(0.15)
                  : const Color(0xFF1E6FDB).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Dans $jours j.',
              style: TextStyle(
                color: urgent ? const Color(0xFFE67E22) : AppColors.secondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String emoji;

  const _StatChip(
      {required this.label,
      required this.value,
      required this.color,
      required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
