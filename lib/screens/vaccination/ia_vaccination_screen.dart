import 'package:flutter/material.dart';
import '../../models/enfant_model.dart';
import '../../services/vaccin_service.dart';
import '../../services/ia_vaccination_service.dart';
import '../../theme/app_colors.dart';

class IAVaccinationScreen extends StatefulWidget {
  final EnfantModel enfant;
  const IAVaccinationScreen({super.key, required this.enfant});

  @override
  State<IAVaccinationScreen> createState() => _IAVaccinationScreenState();
}

class _IAVaccinationScreenState extends State<IAVaccinationScreen> {
  AnalyseVaccinaleIA? _analyse;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _analyser();
  }

  Future<void> _analyser() async {
    setState(() => _loading = true);
    final vaccins = await VaccinService.getVaccins(widget.enfant.id);
    final analyse = await IAVaccinationService.analyser(
      dateNaissance: widget.enfant.dateNaissance,
      vaccinsAdministres: vaccins,
      prenomEnfant: widget.enfant.prenom,
      sexe: widget.enfant.sexe,
    );
    if (mounted) setState(() { _analyse = analyse; _loading = false; });
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
              Expanded(
                child: _loading
                    ? _buildLoading()
                    : _buildContent(),
              ),
            ],
          ),
        ),
      ),
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
                Row(
                  children: [
                    const Text('🤖 ', style: TextStyle(fontSize: 18)),
                    const Text('Suggestions IA',
                        style: TextStyle(color: AppColors.textPrimary,
                            fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF4285F4), Color(0xFF0F9D58)]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Gemini',
                          style: TextStyle(color: Colors.white,
                              fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                Text(widget.enfant.prenom,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          // Bouton rafraîchir
          GestureDetector(
            onTap: _analyser,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF4285F4), Color(0xFF0F9D58)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(child: Text('🤖', style: TextStyle(fontSize: 36))),
          ),
          const SizedBox(height: 20),
          const Text('Analyse en cours...',
              style: TextStyle(color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Gemini analyse le dossier vaccinal',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),
          const CircularProgressIndicator(color: Color(0xFF4285F4)),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final a = _analyse!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildResumeGemini(a),
        const SizedBox(height: 20),
        _buildScoreCouverture(a),
        if (a.urgentes.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSectionLabel('🚨 Urgent — À faire maintenant', AppColors.danger),
          const SizedBox(height: 12),
          ...a.urgentes.map((s) => _SuggestionCard(suggestion: s)),
        ],
        if (a.prochaines.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSectionLabel('📅 Prochainement — 3 prochains mois', const Color(0xFFE67E22)),
          const SizedBox(height: 12),
          ...a.prochaines.map((s) => _SuggestionCard(suggestion: s)),
        ],
        if (a.futures.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSectionLabel('🔮 Planification future', AppColors.textSecondary),
          const SizedBox(height: 12),
          ...a.futures.map((s) => _SuggestionCard(suggestion: s, collapsed: true)),
        ],
        const SizedBox(height: 24),
        _buildDisclaimer(a.geminiDisponible),
      ],
    );
  }

  Widget _buildResumeGemini(AnalyseVaccinaleIA a) {
    final estAJour = a.estAJour;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: estAJour
              ? [const Color(0xFF00855A), const Color(0xFF00C9A7)]
              : [const Color(0xFF1A237E), const Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (estAJour ? const Color(0xFF00C9A7) : const Color(0xFF1565C0)).withValues(alpha: 0.3),
            blurRadius: 16, offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🤖', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Analyse Gemini',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              // Badge Gemini ou Fallback
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      a.geminiDisponible ? Icons.auto_awesome_rounded : Icons.offline_bolt_rounded,
                      color: Colors.white, size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      a.geminiDisponible ? 'Gemini AI' : 'Mode local',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(a.resumeGemini,
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildScoreCouverture(AnalyseVaccinaleIA a) {
    final pct = (a.scoreCouverture * 100).round();
    Color barColor = pct >= 80
        ? const Color(0xFF00C9A7)
        : pct >= 50 ? const Color(0xFFE67E22) : AppColors.danger;

    return Container(
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
              const Text('💉', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              const Text('Couverture vaccinale',
                  style: TextStyle(color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700, fontSize: 14)),
              const Spacer(),
              Text('$pct%',
                  style: TextStyle(color: barColor, fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: a.scoreCouverture,
              backgroundColor: AppColors.glassBorder,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ScoreStat('${a.urgentes.length}', 'Urgents', AppColors.danger),
              _ScoreStat('${a.prochaines.length}', 'Prochains', const Color(0xFFE67E22)),
              _ScoreStat('${a.futures.length}', 'Futurs', AppColors.textSecondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, Color color) {
    return Row(
      children: [
        Container(width: 3, height: 18, color: color, margin: const EdgeInsets.only(right: 10)),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
      ],
    );
  }

  Widget _buildDisclaimer(bool geminiActif) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!geminiActif)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE67E22).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE67E22).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.key_rounded, color: Color(0xFFE67E22), size: 14),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Gemini non connecté. Ajoutez votre clé API dans ia_vaccination_service.dart pour activer l\'IA réelle.',
                        style: TextStyle(color: Color(0xFFE67E22), fontSize: 11, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ℹ️', style: TextStyle(fontSize: 14)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ces suggestions sont basées sur le calendrier vaccinal national tunisien et les recommandations OMS. '
                  'Elles ne remplacent pas l\'avis de votre pédiatre.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Carte suggestion ───────────────────────────────────────────────────────────
class _SuggestionCard extends StatefulWidget {
  final SuggestionVaccin suggestion;
  final bool collapsed;
  const _SuggestionCard({required this.suggestion, this.collapsed = false});

  @override
  State<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<_SuggestionCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = !widget.collapsed;
  }

  Color get _color {
    switch (widget.suggestion.priorite) {
      case PrioriteIA.urgente: return AppColors.danger;
      case PrioriteIA.haute:   return const Color(0xFFE67E22);
      case PrioriteIA.normale: return AppColors.secondary;
      case PrioriteIA.future:  return AppColors.textSecondary;
    }
  }

  String get _emoji {
    switch (widget.suggestion.priorite) {
      case PrioriteIA.urgente: return '🚨';
      case PrioriteIA.haute:   return '⚡';
      case PrioriteIA.normale: return '📅';
      case PrioriteIA.future:  return '🔮';
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.suggestion;
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _color.withValues(alpha: 0.4), width: 1.2),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(16),
                  bottom: _expanded ? Radius.zero : const Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Text(_emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(s.titre,
                        style: TextStyle(color: _color,
                            fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                  if (s.retardJours > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${s.retardJours}j',
                          style: TextStyle(color: _color,
                              fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  const SizedBox(width: 8),
                  Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: _color, size: 18),
                ],
              ),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(icon: Icons.coronavirus_outlined,
                        label: 'Maladie ciblée', value: s.programme.maladie),
                    const SizedBox(height: 8),
                    _InfoRow(icon: Icons.calendar_today_outlined,
                        label: 'Âge recommandé', value: s.programme.ageLabel),
                    const SizedBox(height: 8),
                    _InfoRow(icon: Icons.event_outlined,
                        label: 'Date suggérée',
                        value: '${s.dateSuggeree.day.toString().padLeft(2,'0')}/${s.dateSuggeree.month.toString().padLeft(2,'0')}/${s.dateSuggeree.year}'),
                    const SizedBox(height: 10),
                    Text(s.programme.description,
                        style: const TextStyle(color: AppColors.textSecondary,
                            fontSize: 12, height: 1.5)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 14),
        const SizedBox(width: 6),
        Text('$label : ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        Expanded(
          child: Text(value,
              style: const TextStyle(color: AppColors.textPrimary,
                  fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _ScoreStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _ScoreStat(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18)),
        Text(label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
      ],
    );
  }
}
