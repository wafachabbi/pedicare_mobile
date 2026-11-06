import 'package:flutter/material.dart';
import '../../models/croissance_model.dart';
import '../../services/ia_croissance_service.dart';
import '../../services/percentile_service.dart';
import '../../theme/app_colors.dart';

class IACroissanceScreen extends StatefulWidget {
  final List<CroissanceModel> mesures;
  final String enfantNom;
  final String sexe;
  final DateTime dateNaissance;

  const IACroissanceScreen({
    super.key,
    required this.mesures,
    required this.enfantNom,
    required this.sexe,
    required this.dateNaissance,
  });

  @override
  State<IACroissanceScreen> createState() => _IACroissanceScreenState();
}

class _IACroissanceScreenState extends State<IACroissanceScreen> {
  AnalyseCroissanceIA? _analyse;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _analyser();
  }

  Future<void> _analyser() async {
    setState(() => _loading = true);
    final analyse = await IACroissanceService.analyser(
      mesures: widget.mesures,
      prenomEnfant: widget.enfantNom,
      sexe: widget.sexe,
      dateNaissance: widget.dateNaissance,
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
                child: _loading ? _buildLoading() : _buildContent(),
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
                    const Text('Analyse IA Croissance',
                        style: TextStyle(color: AppColors.textPrimary,
                            fontSize: 18, fontWeight: FontWeight.w700)),
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
                Text(widget.enfantNom,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
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
              gradient: const LinearGradient(
                  colors: [Color(0xFF9B59B6), Color(0xFF4285F4)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(child: Text('🤖', style: TextStyle(fontSize: 36))),
          ),
          const SizedBox(height: 20),
          const Text('Analyse en cours...',
              style: TextStyle(color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Gemini analyse les données de croissance',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),
          const CircularProgressIndicator(color: Color(0xFF9B59B6)),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final a = _analyse!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildAnalyseGemini(a),
        const SizedBox(height: 20),
        _buildPercentileCard(a),
        const SizedBox(height: 20),
        _buildTendances(a),
        if (a.alertes.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildAlertes(a),
        ],
        const SizedBox(height: 20),
        _buildDisclaimer(a.geminiDisponible),
      ],
    );
  }

  Widget _buildAnalyseGemini(AnalyseCroissanceIA a) {
    final color = a.estNormal
        ? const Color(0xFF00C9A7)
        : a.aAlerteElevee ? AppColors.danger : const Color(0xFFE67E22);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: a.estNormal
              ? [const Color(0xFF00855A), const Color(0xFF00C9A7)]
              : a.aAlerteElevee
                  ? [const Color(0xFF8B1A1A), const Color(0xFFD32F2F)]
                  : [const Color(0xFF7B4500), const Color(0xFFE67E22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
            color: color.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(a.estNormal ? '✅' : a.aAlerteElevee ? '🚨' : '⚠️',
                  style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Analyse Gemini',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(a.geminiDisponible
                        ? Icons.auto_awesome_rounded
                        : Icons.offline_bolt_rounded,
                        color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(a.geminiDisponible ? 'Gemini AI' : 'Mode local',
                        style: const TextStyle(color: Colors.white,
                            fontSize: 10, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(a.analyseGemini,
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildPercentileCard(AnalyseCroissanceIA a) {
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
          const Text('📊 Percentiles OMS (dernière mesure)',
              style: TextStyle(color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 14),
          if (a.dernierPctPoids != null)
            _PercentileBar(
              label: 'Poids',
              emoji: '⚖️',
              percentile: a.dernierPctPoids!,
              color: const Color(0xFF9B59B6),
            ),
          const SizedBox(height: 10),
          if (a.dernierPctTaille != null)
            _PercentileBar(
              label: 'Taille',
              emoji: '📏',
              percentile: a.dernierPctTaille!,
              color: const Color(0xFF1E6FDB),
            ),
          const SizedBox(height: 10),
          if (a.dernierIMC != null)
            _IMCBar(imc: a.dernierIMC!),
        ],
      ),
    );
  }

  Widget _buildTendances(AnalyseCroissanceIA a) {
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
          const Text('📈 Tendances',
              style: TextStyle(color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _TendanceChip(
                  label: 'Poids', tendance: a.tendancePoids, emoji: '⚖️')),
              const SizedBox(width: 12),
              Expanded(child: _TendanceChip(
                  label: 'Taille', tendance: a.tendanceTaille, emoji: '📏')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertes(AnalyseCroissanceIA a) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('${a.alertes.length} anomalie(s) détectée(s)',
                  style: const TextStyle(color: AppColors.danger,
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          ...a.alertes.map((alerte) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (alerte.gravite == GraviteAlerte.elevee
                  ? AppColors.danger : const Color(0xFFE67E22)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (alerte.gravite == GraviteAlerte.elevee
                    ? AppColors.danger : const Color(0xFFE67E22)).withOpacity(0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  alerte.gravite == GraviteAlerte.elevee
                      ? Icons.error_outline_rounded
                      : Icons.warning_amber_rounded,
                  color: alerte.gravite == GraviteAlerte.elevee
                      ? AppColors.danger : const Color(0xFFE67E22),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alerte.gravite == GraviteAlerte.elevee ? 'Alerte critique' : 'Avertissement',
                        style: TextStyle(
                          color: alerte.gravite == GraviteAlerte.elevee
                              ? AppColors.danger : const Color(0xFFE67E22),
                          fontWeight: FontWeight.w700, fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(alerte.message,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
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
        children: [
          if (!geminiActif)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE67E22).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE67E22).withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.key_rounded, color: Color(0xFFE67E22), size: 14),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ajoutez votre clé API Gemini dans ia_croissance_service.dart pour activer l\'IA réelle.',
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
                  'Cette analyse est basée sur les standards OMS et ne remplace pas un avis médical. '
                  'Consultez votre pédiatre pour toute interprétation clinique.',
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

// ── Widgets ────────────────────────────────────────────────────────────────────
class _PercentileBar extends StatelessWidget {
  final String label;
  final String emoji;
  final double percentile;
  final Color color;

  const _PercentileBar({
    required this.label, required this.emoji,
    required this.percentile, required this.color,
  });

  String get _interpretation {
    if (percentile < 3) return 'Très faible ⚠️';
    if (percentile < 15) return 'Faible';
    if (percentile < 85) return 'Normal ✓';
    if (percentile < 97) return 'Élevé';
    return 'Très élevé ⚠️';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const Spacer(),
            Text('P${percentile.round()}',
                style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(width: 8),
            Text(_interpretation,
                style: TextStyle(color: percentile < 3 || percentile > 97
                    ? AppColors.danger : const Color(0xFF00C9A7),
                    fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percentile / 100,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(
                percentile < 3 || percentile > 97 ? AppColors.danger : color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _IMCBar extends StatelessWidget {
  final double imc;
  const _IMCBar({required this.imc});

  Color get _color {
    if (imc < 18.5) return const Color(0xFF1E6FDB);
    if (imc < 25) return const Color(0xFF00C9A7);
    if (imc < 30) return const Color(0xFFE67E22);
    return AppColors.danger;
  }

  String get _label {
    if (imc < 18.5) return 'Insuffisance pondérale';
    if (imc < 25) return 'Normal ✓';
    if (imc < 30) return 'Surpoids';
    return 'Obésité ⚠️';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('📊', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        const Text('IMC', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const Spacer(),
        Text(imc.toStringAsFixed(1),
            style: TextStyle(color: _color, fontWeight: FontWeight.w800, fontSize: 13)),
        const SizedBox(width: 8),
        Text(_label, style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _TendanceChip extends StatelessWidget {
  final String label;
  final String tendance;
  final String emoji;
  const _TendanceChip({required this.label, required this.tendance, required this.emoji});

  Color get _color {
    switch (tendance) {
      case 'hausse': return const Color(0xFF00C9A7);
      case 'baisse': return AppColors.danger;
      default: return AppColors.secondary;
    }
  }

  String get _icon {
    switch (tendance) {
      case 'hausse': return '↗️';
      case 'baisse': return '↘️';
      default: return '➡️';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text('$emoji $_icon', style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          Text(tendance[0].toUpperCase() + tendance.substring(1),
              style: TextStyle(color: _color, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}
