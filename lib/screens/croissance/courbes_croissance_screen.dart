import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/croissance_model.dart';
import '../../services/percentile_service.dart';
import '../../theme/app_colors.dart';

class CourbesCroissanceScreen extends StatefulWidget {
  final List<CroissanceModel> mesures;
  final String enfantNom;
  final String sexe;
  final DateTime dateNaissance;

  const CourbesCroissanceScreen({
    super.key,
    required this.mesures,
    required this.enfantNom,
    required this.sexe,
    required this.dateNaissance,
  });

  @override
  State<CourbesCroissanceScreen> createState() => _CourbesCroissanceScreenState();
}

class _CourbesCroissanceScreenState extends State<CourbesCroissanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  List<CroissanceModel> get _sorted => List<CroissanceModel>.from(widget.mesures)
    ..sort((a, b) => a.date.compareTo(b.date));

  int _ageMois(DateTime d) =>
      (d.year - widget.dateNaissance.year) * 12 + (d.month - widget.dateNaissance.month);

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
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _buildGrapheMesure(estPoids: true),
                    _buildGrapheMesure(estPoids: false),
                    _buildGrapheIMC(),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Courbes de croissance',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
              Text(widget.enfantNom,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
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
        controller: _tab,
        indicator: BoxDecoration(
          gradient: const LinearGradient(colors: AppColors.buttonGradient),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        tabs: const [Tab(text: 'Poids'), Tab(text: 'Taille'), Tab(text: 'IMC')],
      ),
    );
  }

  Widget _buildGrapheMesure({required bool estPoids}) {
    final sorted = _sorted;
    if (sorted.isEmpty) return _buildEmpty();

    final color = estPoids ? const Color(0xFF9B59B6) : const Color(0xFF1E6FDB);
    final unit  = estPoids ? 'kg' : 'cm';

    final spots = sorted.map((m) => FlSpot(
      _ageMois(m.date).toDouble(),
      estPoids ? m.poids : m.taille,
    )).toList();

    final minAge = spots.first.x;
    final maxAge = spots.last.x;

    // Courbes percentiles
    List<FlSpot> refSpots(String key) {
      final pts = <FlSpot>[];
      for (int a = minAge.toInt(); a <= maxAge.toInt(); a++) {
        final r = PercentileService.getReferences(ageMois: a, sexe: widget.sexe, estPoids: estPoids);
        if (r.containsKey(key)) pts.add(FlSpot(a.toDouble(), r[key]!));
      }
      return pts;
    }

    final p3  = refSpots('P3');
    final p50 = refSpots('P50');
    final p97 = refSpots('P97');

    final lastM = sorted.last;
    final pct = PercentileService.calculerPercentile(
      valeur: estPoids ? lastM.poids : lastM.taille,
      ageMois: _ageMois(lastM.date),
      sexe: widget.sexe,
      estPoids: estPoids,
    );

    final allY = [...spots.map((s) => s.y), ...p3.map((s) => s.y), ...p97.map((s) => s.y)];
    final minY = allY.reduce((a, b) => a < b ? a : b) * 0.95;
    final maxY = allY.reduce((a, b) => a > b ? a : b) * 1.05;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPercentileBadge(pct, estPoids ? 'Poids' : 'Taille', color, unit,
              estPoids ? lastM.poids : lastM.taille),
          const SizedBox(height: 14),
          _buildLegende(color),
          const SizedBox(height: 10),
          SizedBox(
            height: 270,
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 12, 16, 4),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: LineChart(LineChartData(
                minX: minAge - 0.5, maxX: maxAge + 0.5,
                minY: minY, maxY: maxY,
                gridData: FlGridData(
                  show: true, drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: Colors.white10, strokeWidth: 0.5),
                ),
                borderData: FlBorderData(show: false),
                titlesData: _titlesData(),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) => touchedSpots.map((ts) {
                      if (ts.barIndex != 3) return null;
                      return LineTooltipItem(
                        '${ts.y.toStringAsFixed(1)} $unit\n${ts.x.toInt()} mois',
                        const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  _refLine(p3, Colors.red.withValues(alpha: 0.45)),
                  _refLine(p97, Colors.red.withValues(alpha: 0.45)),
                  _refLine(p50, Colors.white.withValues(alpha: 0.2), dash: true),
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                        radius: 4, color: color,
                        strokeColor: Colors.white, strokeWidth: 1.5,
                      ),
                    ),
                    belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.07)),
                  ),
                ],
              )),
            ),
          ),
          const SizedBox(height: 16),
          _buildTableau(sorted, estPoids, unit, color),
        ],
      ),
    );
  }

  Widget _buildGrapheIMC() {
    final sorted = _sorted;
    if (sorted.isEmpty) return _buildEmpty();

    final spots = sorted.map((m) => FlSpot(
      _ageMois(m.date).toDouble(),
      double.parse(m.imc.toStringAsFixed(1)),
    )).toList();

    final allY = spots.map((s) => s.y).toList();
    final minY = (allY.reduce((a, b) => a < b ? a : b) - 2).clamp(10.0, 50.0);
    final maxY = allY.reduce((a, b) => a > b ? a : b) + 3;
    final minX = spots.first.x - 0.5;
    final maxX = spots.last.x + 0.5;
    final lastIMC = sorted.last.imc;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIMCBadge(lastIMC),
          const SizedBox(height: 14),
          _buildZonesIMCLegende(),
          const SizedBox(height: 10),
          SizedBox(
            height: 270,
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 12, 16, 4),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: LineChart(LineChartData(
                minX: minX, maxX: maxX, minY: minY, maxY: maxY,
                gridData: FlGridData(
                  show: true, drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: Colors.white10, strokeWidth: 0.5),
                ),
                borderData: FlBorderData(show: false),
                titlesData: _titlesData(),
                extraLinesData: ExtraLinesData(horizontalLines: [
                  HorizontalLine(y: 18.5, color: const Color(0xFF1E6FDB).withValues(alpha: 0.6),
                      strokeWidth: 1, dashArray: [4, 4]),
                  HorizontalLine(y: 25.0, color: const Color(0xFFE67E22).withValues(alpha: 0.6),
                      strokeWidth: 1, dashArray: [4, 4]),
                  HorizontalLine(y: 30.0, color: AppColors.danger.withValues(alpha: 0.6),
                      strokeWidth: 1, dashArray: [4, 4]),
                ]),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (ts) => ts.map((s) => LineTooltipItem(
                      'IMC ${s.y.toStringAsFixed(1)}\n${s.x.toInt()} mois',
                      const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    )).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF00C9A7),
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, _, _) {
                        Color c = const Color(0xFF00C9A7);
                        if (spot.y < 18.5) {
                          c = const Color(0xFF1E6FDB);
                        } else if (spot.y >= 30) {
                          c = AppColors.danger;
                        } else if (spot.y >= 25) {
                          c = const Color(0xFFE67E22);
                        }
                        return FlDotCirclePainter(radius: 5, color: c,
                            strokeColor: Colors.white, strokeWidth: 1.5);
                      },
                    ),
                    belowBarData: BarAreaData(show: true, color: const Color(0xFF00C9A7).withValues(alpha: 0.07)),
                  ),
                ],
              )),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers UI ──────────────────────────────────────────────────────────────
  Widget _buildPercentileBadge(double pct, String label, Color color, String unit, double val) {
    String interp;
    if (pct < 3) {
      interp = 'Très faible ⚠️';
    } else if (pct < 15) {
      interp = 'Faible';
    } else if (pct < 85) {
      interp = 'Normal ✓';
    } else if (pct < 97) {
      interp = 'Élevé';
    } else {
      interp = 'Très élevé ⚠️';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Center(
              child: Text('P${pct.round()}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$label — ${val.toStringAsFixed(1)} $unit',
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 3),
                Text(interp, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text('${pct.round()}% des enfants du même âge et sexe ont une valeur inférieure',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIMCBadge(double imc) {
    String label; Color color;
    if (imc < 18.5) { label = 'Insuffisance pondérale'; color = const Color(0xFF1E6FDB); }
    else if (imc < 25) { label = 'Poids normal ✓'; color = const Color(0xFF00C9A7); }
    else if (imc < 30) { label = 'Surpoids'; color = const Color(0xFFE67E22); }
    else { label = 'Obésité ⚠️'; color = AppColors.danger; }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Center(child: Text(imc.toStringAsFixed(1),
                style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13))),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('IMC actuel', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegende(Color color) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        _legendeDot(color, 'Enfant'),
        _legendeDot(Colors.white38, 'P50 (médiane)'),
        _legendeDot(Colors.red.withValues(alpha: 0.6), 'P3 / P97'),
      ],
    );
  }

  Widget _buildZonesIMCLegende() {
    return Wrap(
      spacing: 12, runSpacing: 6,
      children: [
        _legendeLine(const Color(0xFF1E6FDB), '< 18.5 Insuffisance'),
        _legendeLine(const Color(0xFF00C9A7), '18.5–25 Normal'),
        _legendeLine(const Color(0xFFE67E22), '25–30 Surpoids'),
        _legendeLine(AppColors.danger, '> 30 Obésité'),
      ],
    );
  }

  Widget _legendeDot(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
    ],
  );

  Widget _legendeLine(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 14, height: 2, color: color),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
    ],
  );

  Widget _buildTableau(List<CroissanceModel> sorted, bool estPoids, String unit, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Détail des mesures',
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 8),
        ...sorted.reversed.take(5).map((m) {
          final age = _ageMois(m.date);
          final val = estPoids ? m.poids : m.taille;
          final pct = PercentileService.calculerPercentile(
              valeur: val, ageMois: age, sexe: widget.sexe, estPoids: estPoids);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              children: [
                Text(_fmt(m.date),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const Spacer(),
                Text('${val.toStringAsFixed(1)} $unit',
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('P${pct.round()}',
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  FlTitlesData _titlesData() => FlTitlesData(
    leftTitles: AxisTitles(sideTitles: SideTitles(
      showTitles: true, reservedSize: 38,
      getTitlesWidget: (v, _) => Text(v.toStringAsFixed(1),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 9)),
    )),
    bottomTitles: AxisTitles(sideTitles: SideTitles(
      showTitles: true, reservedSize: 22,
      getTitlesWidget: (v, _) {
        if (v % 3 != 0) return const SizedBox.shrink();
        return Text('${v.toInt()}m',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 9));
      },
    )),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
  );

  LineChartBarData _refLine(List<FlSpot> spots, Color color, {bool dash = false}) =>
      LineChartBarData(
        spots: spots,
        isCurved: true,
        color: color,
        barWidth: 1,
        dashArray: dash ? [4, 4] : null,
        dotData: const FlDotData(show: false),
      );

  Widget _buildEmpty() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('📊', style: TextStyle(fontSize: 48)),
        SizedBox(height: 12),
        Text('Ajoutez des mesures pour voir les courbes',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      ],
    ),
  );

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
