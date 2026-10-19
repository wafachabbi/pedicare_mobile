import 'package:flutter/material.dart';
import '../../models/vaccin_model.dart';
import '../../models/enfant_model.dart';
import '../../services/vaccin_service.dart';
import '../../services/calendrier_vaccinal_service.dart';
import '../../theme/app_colors.dart';

class CalendrierVaccinalScreen extends StatefulWidget {
  final EnfantModel enfant;

  const CalendrierVaccinalScreen({super.key, required this.enfant});

  @override
  State<CalendrierVaccinalScreen> createState() =>
      _CalendrierVaccinalScreenState();
}

class _CalendrierVaccinalScreenState extends State<CalendrierVaccinalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<VaccinModel> _vaccinsAdministres = [];
  List<VaccinStatut> _calendrier = [];
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
    final vaccins = await VaccinService.getVaccins(widget.enfant.id);
    final ageMois = CalendrierVaccinalService.ageMoisDepuis(
        widget.enfant.dateNaissance);
    final calendrier = CalendrierVaccinalService.evaluer(
      ageMois: ageMois,
      vaccinsAdministres: vaccins,
    );
    if (mounted) {
      setState(() {
        _vaccinsAdministres = vaccins;
        _calendrier = calendrier;
        _loading = false;
      });
    }
  }

  List<VaccinStatut> get _faits =>
      _calendrier.where((v) => v.statut == StatutVaccin.fait).toList();

  List<VaccinStatut> get _enRetard =>
      _calendrier.where((v) => v.statut == StatutVaccin.enRetard).toList();

  List<VaccinStatut> get _aVenir =>
      _calendrier.where((v) => v.statut == StatutVaccin.aVenir).toList();

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
              if (!_loading) _buildResume(),
              const SizedBox(height: 8),
              if (!_loading) _buildTabBar(),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.secondary))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildListe(_enRetard, 'enRetard'),
                          _buildListe(_aVenir, 'aVenir'),
                          _buildListe(_faits, 'fait'),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final ageMois = CalendrierVaccinalService.ageMoisDepuis(
        widget.enfant.dateNaissance);
    final ageLabel = ageMois < 24
        ? '$ageMois mois'
        : '${(ageMois / 12).floor()} ans';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Calendrier vaccinal',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                Text('${widget.enfant.prenom} • $ageLabel',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResume() {
    final taux = _calendrier.isEmpty
        ? 0
        : (_faits.length / _calendrier.length * 100).round();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00855A), Color(0xFF00C9A7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x4400C9A7), blurRadius: 16, offset: Offset(0, 6))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('💉', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Couverture vaccinale : $taux%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      '${_faits.length} / ${_calendrier.length} vaccins',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (_enRetard.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '⚠️ ${_enRetard.length} en retard',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _calendrier.isEmpty ? 0 : _faits.length / _calendrier.length,
              backgroundColor: Colors.white24,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatMin(
                  value: '${_faits.length}',
                  label: 'Faits',
                  color: Colors.white),
              _StatMin(
                  value: '${_enRetard.length}',
                  label: 'En retard',
                  color: const Color(0xFFFFD166)),
              _StatMin(
                  value: '${_aVenir.length}',
                  label: 'À venir',
                  color: Colors.white70),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        tabs: [
          Tab(text: '⚠️ Retard (${_enRetard.length})'),
          Tab(text: '📅 À venir (${_aVenir.length})'),
          Tab(text: '✅ Faits (${_faits.length})'),
        ],
      ),
    );
  }

  Widget _buildListe(List<VaccinStatut> liste, String type) {
    if (liste.isEmpty) {
      final msgs = {
        'enRetard': ('🎉', 'Aucun vaccin en retard', 'Le calendrier est respecté !'),
        'aVenir':   ('📅', 'Aucun vaccin prévu', 'Tous les vaccins sont à jour pour l\'âge actuel'),
        'fait':     ('💉', 'Aucun vaccin enregistré', 'Ajoutez les vaccins depuis l\'historique'),
      };
      final m = msgs[type]!;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(m.$1, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(m.$2,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(m.$3,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      itemCount: liste.length,
      itemBuilder: (context, i) => _VaccinCard(statut: liste[i]),
    );
  }
}

// ── Carte vaccin du calendrier ────────────────────────────────────────────────
class _VaccinCard extends StatelessWidget {
  final VaccinStatut statut;
  const _VaccinCard({required this.statut});

  Color get _color {
    switch (statut.statut) {
      case StatutVaccin.fait:
        return const Color(0xFF00C9A7);
      case StatutVaccin.enRetard:
        return const Color(0xFFE67E22);
      case StatutVaccin.aVenir:
        return AppColors.secondary;
      case StatutVaccin.nonConcerne:
        return AppColors.textSecondary;
    }
  }

  String get _statutLabel {
    switch (statut.statut) {
      case StatutVaccin.fait:
        return '✅ Administré';
      case StatutVaccin.enRetard:
        return '⚠️ En retard';
      case StatutVaccin.aVenir:
        return '📅 À venir';
      case StatutVaccin.nonConcerne:
        return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = statut.programme;
    final v = statut.vaccinAdministre;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: _color.withOpacity(0.4), width: 1.2),
      ),
      child: Column(
        children: [
          // ── Bandeau âge + statut ──────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(p.ageLabel,
                      style: TextStyle(
                          color: _color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
                const Spacer(),
                Text(_statutLabel,
                    style: TextStyle(
                        color: _color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          // ── Corps ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: _color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                          child: Text('💉',
                              style: TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.nom,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                          Text(p.maladie,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(p.description,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontStyle: FontStyle.italic)),
                // Si administré, afficher la date
                if (v != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C9A7).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF00C9A7), size: 13),
                        const SizedBox(width: 6),
                        Text(
                          'Administré le ${_fmt(v.dateAdministre)} par Dr. ${v.medecin}',
                          style: const TextStyle(
                              color: Color(0xFF00C9A7),
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ── Mini stat ─────────────────────────────────────────────────────────────────
class _StatMin extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatMin(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800)),
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}
