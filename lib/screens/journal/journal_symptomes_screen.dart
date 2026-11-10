import 'package:flutter/material.dart';
import '../../data/symptomes_catalogue.dart';
import '../../models/analyse_symptomes_model.dart';
import '../../models/enfant_model.dart';
import '../../models/journal_symptome_model.dart';
import '../../services/consultation_service.dart';
import '../../services/ia_consultation_service.dart';
import '../../services/journal_pdf_service.dart';
import '../../services/journal_symptome_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/journal_charts.dart';
import 'add_symptome_screen.dart';

class JournalSymptomesScreen extends StatefulWidget {
  final EnfantModel enfant;

  /// Mode pédiatre : consultation seule, sans création/modification/suppression.
  final bool lectureSeule;

  const JournalSymptomesScreen({
    super.key,
    required this.enfant,
    this.lectureSeule = false,
  });

  @override
  State<JournalSymptomesScreen> createState() => _JournalSymptomesScreenState();
}

class _JournalSymptomesScreenState extends State<JournalSymptomesScreen> {
  List<JournalSymptomeModel> _entrees = [];
  JournalStats _stats = JournalStats.empty;
  AnalyseSymptomes? _analyse;
  List<JourJournal> _serie = [];
  int _filtreJours = 7;
  bool _loading = true;
  bool _exportEnCours = false;

  @override
  void initState() {
    super.initState();
    _load();
    if (!widget.lectureSeule) {
      NotificationService.planifierRappelJournalQuotidien(
        enfantId: widget.enfant.id,
        enfantNom: widget.enfant.nomComplet,
      );
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final entrees = await JournalSymptomeService.getEntrees(widget.enfant.id);
    final stats = await JournalSymptomeService.getStatistiques(
      widget.enfant.id,
      entrees: entrees,
    );
    final analyse = await IAConsultationService.analyserContexte(
      enfant: widget.enfant,
      journal: entrees.take(30).toList(),
    );
    final serie = await JournalSymptomeService.getSerieJournaliere(
      widget.enfant.id,
      jours: _filtreJours == 0 ? 30 : _filtreJours,
      entrees: entrees,
    );
    if (!mounted) return;
    setState(() {
      _entrees = entrees;
      _stats = stats;
      _analyse = analyse;
      _serie = serie;
      _loading = false;
    });
  }

  Future<void> _changerFiltre(int jours) async {
    setState(() => _filtreJours = jours);
    final serie = await JournalSymptomeService.getSerieJournaliere(
      widget.enfant.id,
      jours: jours == 0 ? 30 : jours,
      entrees: _entrees,
    );
    if (mounted) setState(() => _serie = serie);
  }

  List<JournalSymptomeModel> get _filtrees {
    if (_filtreJours == 0) return _entrees;
    final now = DateTime.now();
    final debut = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: _filtreJours - 1));
    return _entrees.where((e) => !e.date.isBefore(debut)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
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
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.secondary))
                    : _buildBody(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: widget.lectureSeule ? null : _buildFAB(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Journal des symptômes',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                Text(widget.enfant.nomComplet,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          if (widget.lectureSeule)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.35)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      color: AppColors.secondary, size: 13),
                  SizedBox(width: 4),
                  Text('Lecture seule',
                      style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          _actionIcon(
            icon: Icons.visibility_outlined,
            tooltip: 'Aperçu du rapport',
            onTap: _exportEnCours ? null : () => _exporter(apercu: true),
          ),
          if (!widget.lectureSeule) ...[
            const SizedBox(width: 8),
            _actionIcon(
              icon: Icons.ios_share_rounded,
              tooltip: 'Partager avec le pédiatre',
              color: const Color(0xFF00C9A7),
              onTap: _exportEnCours ? null : () => _exporter(apercu: false),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionIcon({
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (color ?? AppColors.secondary).withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: (color ?? AppColors.secondary).withValues(alpha: 0.35)),
          ),
          child: Icon(icon,
              color: color ?? AppColors.secondary, size: 18),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final filtrees = _filtrees;
    final groups = <String, List<JournalSymptomeModel>>{};
    for (final e in filtrees) {
      final key = _dateKey(e.date);
      groups.putIfAbsent(key, () => []).add(e);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 100),
      children: [
        _buildStatsCard(),
        const SizedBox(height: 14),
        _buildAnalyseCard(),
        const SizedBox(height: 14),
        _buildChartCard(),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(
              child: Text('Historique chronologique',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ),
            _filtreChip('7 j', 7),
            const SizedBox(width: 6),
            _filtreChip('30 j', 30),
            const SizedBox(width: 6),
            _filtreChip('Tout', 0),
          ],
        ),
        const SizedBox(height: 12),
        if (filtrees.isEmpty)
          _buildEmpty()
        else
          ...groups.entries.map((entry) {
            final date = DateTime.tryParse(entry.key) ?? DateTime.now();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 8, left: 2),
                  child: Text(
                    _dayLabel(date),
                    style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                ...entry.value.map((e) => _buildEntreeCard(e)),
                const SizedBox(height: 8),
              ],
            );
          }),
      ],
    );
  }

  Widget _buildStatsCard() {
    final couleur = _stats.joursFievre7Jours > 0
        ? const Color(0xFFFF8A65)
        : const Color(0xFF00C9A7);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [couleur.withValues(alpha: 0.28), const Color(0xFF0D2D5E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: couleur.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Suivi des 7 derniers jours',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ),
              Text(
                '${(_stats.couverture7Jours * 100).round()}% renseigné',
                style: TextStyle(
                    color: couleur, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _stat('Entrées', '${_stats.entrees7Jours}'),
              _stat('Jours', '${_stats.joursRenseignes7Jours}/7'),
              _stat('Temp. moy.', _stats.temperatureMoyenneLabel),
              _stat('Fièvre', '${_stats.joursFievre7Jours} j'),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _stats.couverture7Jours,
              minHeight: 6,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(couleur),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 9.5)),
        ],
      ),
    );
  }

  Widget _buildAnalyseCard() {
    final analyse = _analyse;
    if (analyse == null) return const SizedBox.shrink();
    final color = analyse.aUrgence
        ? AppColors.danger
        : analyse.aAttention
            ? const Color(0xFFE67E22)
            : const Color(0xFF00C9A7);
    return GestureDetector(
      onTap: _showAnalyseComplete,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(analyse.aUrgence ? '🚨' : '🤖',
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    analyse.iaDisponible
                        ? 'Analyse IA (Gemini)'
                        : 'Analyse contextuelle',
                    style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textSecondary, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Text(analyse.message,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 12, height: 1.45)),
            if (analyse.suggestions.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...analyse.suggestions.take(2).map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.emoji, style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(s.texte,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  height: 1.35)),
                        ),
                      ],
                    ),
                  )),
            ],
            const SizedBox(height: 4),
            const Text(
              'Suggestions informatives — ne remplacent pas un avis médical.',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9.5,
                  fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📈', style: TextStyle(fontSize: 17)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Fréquence des saisies',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
              Text(
                '${_filtreJours == 0 ? 30 : _filtreJours} jours',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 8),
          JournalBarChart(serie: _serie, height: 145),
          const SizedBox(height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legende(const Color(0xFF4DAAFF), 'Saisie'),
              const SizedBox(width: 16),
              _legende(AppColors.danger, 'Jour avec fièvre'),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(color: Colors.white12, height: 18),
          const Text('Température',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          TemperatureLineChart(entrees: _filtrees, height: 140),
        ],
      ),
    );
  }

  Widget _legende(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 9.5)),
      ],
    );
  }

  Widget _filtreChip(String label, int jours) {
    final selected = _filtreJours == jours;
    return GestureDetector(
      onTap: () => _changerFiltre(jours),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.28)
              : AppColors.inputFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.secondary : AppColors.glassBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildEntreeCard(JournalSymptomeModel e) {
    final fievre = e.fievre;
    final accent = fievre ? AppColors.danger : const Color(0xFF4DAAFF);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    fievre ? '🌡️' : '📝',
                    style: const TextStyle(fontSize: 19),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.symptomes.isEmpty
                          ? (fievre ? 'Fièvre' : 'Journée sans symptôme')
                          : SymptomesCatalogue.libelleListe(e.symptomes),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${e.date.hour.toString().padLeft(2, '0')}h${e.date.minute.toString().padLeft(2, '0')}'
                      '${e.temperature != null ? ' · ${e.temperature!.toStringAsFixed(1)} °C' : ''}',
                      style: TextStyle(
                          color: accent, fontSize: 11.5,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (!widget.lectureSeule) ...[
                _miniAction(Icons.edit_outlined, () => _editer(e)),
                const SizedBox(width: 6),
                _miniAction(Icons.delete_outline_rounded, () => _supprimer(e),
                    color: AppColors.danger),
              ],
            ],
          ),
          if (e.symptomes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: e.symptomes.map((id) {
                final s = SymptomesCatalogue.parId(id);
                final color =
                    s?.alerte == true ? AppColors.danger : AppColors.secondary;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${s?.emoji ?? ''} ${s?.label ?? id}'.trim(),
                    style: TextStyle(
                        color: color,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _metric('Toux', _labelToux(e.toux), '😷'),
              _metric('Comportement', _labelComportement(e.comportement), '🙂'),
              _metric('Sommeil', _labelSommeil(e.sommeil), '😴'),
              _metric('Appétit', _labelAppetit(e.appetit), '🍽️'),
            ],
          ),
          if (e.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 9),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.035),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(e.notes,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.35)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniAction(IconData icon, VoidCallback onTap, {Color? color}) {
    final c = color ?? AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: c, size: 15),
      ),
    );
  }

  Widget _metric(String label, String value, String emoji) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        '$emoji $label : $value',
        style: const TextStyle(
            color: AppColors.textSecondary, fontSize: 9.5),
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          const Text('📝', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 14),
          const Text('Aucune entrée sur cette période',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text(
            'Utilisez la saisie rapide pour noter les symptômes du jour.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final ok = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddSymptomeScreen(enfantId: widget.enfant.id),
          ),
        );
        if (ok == true) _load();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF1E6FDB), Color(0xFF4DAAFF)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x441E6FDB),
                blurRadius: 16,
                offset: Offset(0, 6)),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Saisie rapide',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  Future<void> _editer(JournalSymptomeModel e) async {
    final ok = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddSymptomeScreen(
          enfantId: widget.enfant.id,
          entree: e,
        ),
      ),
    );
    if (ok == true) _load();
  }

  Future<void> _supprimer(JournalSymptomeModel e) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D2D5E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer l\'entrée',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        content: const Text('Cette entrée du journal sera supprimée.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler',
                  style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer',
                  style: TextStyle(
                      color: AppColors.danger, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirme != true) return;
    final ok = await JournalSymptomeService.deleteEntree(e.id);
    if (ok) {
      _load();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Suppression impossible.'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _exporter({required bool apercu}) async {
    if (_entrees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoutez au moins une entrée avant d\'exporter.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _exportEnCours = true);
    try {
      final consultation = await ConsultationService.getDerniere(widget.enfant.id);
      if (!mounted) return;
      if (apercu) {
        await JournalPdfService.apercuRapport(
          enfant: widget.enfant,
          journal: _entrees,
          stats: _stats,
          analyse: _analyse ??
              const AnalyseSymptomes(
                  suggestions: [], message: 'Analyse indisponible.'),
          consultation: consultation,
        );
      } else {
        await JournalPdfService.partagerRapport(
          enfant: widget.enfant,
          journal: _entrees,
          stats: _stats,
          analyse: _analyse ??
              const AnalyseSymptomes(
                  suggestions: [], message: 'Analyse indisponible.'),
          consultation: consultation,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la génération du PDF : $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exportEnCours = false);
    }
  }

  void _showAnalyseComplete() {
    final analyse = _analyse;
    if (analyse == null) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: const BoxDecoration(
          color: Color(0xFF0D2D5E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('🤖', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Analyse contextuelle des symptômes',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(analyse.message,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            height: 1.5)),
                    const SizedBox(height: 16),
                    ...analyse.suggestions.map((s) {
                      final color = s.niveau == NiveauSuggestion.urgent
                          ? AppColors.danger
                          : s.niveau == NiveauSuggestion.attention
                              ? const Color(0xFFE67E22)
                              : const Color(0xFF00C9A7);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 9),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.emoji, style: const TextStyle(fontSize: 17)),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(s.texte,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 12,
                                      height: 1.4)),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 6),
                    const Text(
                      'Ces suggestions sont informatives et ne constituent pas un diagnostic. '
                      'En cas de doute ou de signe grave, consultez un professionnel de santé.',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10.5,
                          fontStyle: FontStyle.italic,
                          height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final aujourdhui = DateTime(now.year, now.month, now.day);
    final jour = DateTime(d.year, d.month, d.day);
    if (jour == aujourdhui) return 'Aujourd\'hui · ${_fmtDate(d)}';
    if (jour == aujourdhui.subtract(const Duration(days: 1))) {
      return 'Hier · ${_fmtDate(d)}';
    }
    const jours = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche'
    ];
    return '${jours[d.weekday - 1]} · ${_fmtDate(d)}';
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _labelToux(NiveauToux t) {
    switch (t) {
      case NiveauToux.aucune:
        return 'aucune';
      case NiveauToux.legere:
        return 'légère';
      case NiveauToux.moderee:
        return 'modérée';
      case NiveauToux.forte:
        return 'forte';
    }
  }

  String _labelComportement(EtatComportement c) {
    switch (c) {
      case EtatComportement.normal:
        return 'normal';
      case EtatComportement.calme:
        return 'calme';
      case EtatComportement.fatigue:
        return 'fatigué';
      case EtatComportement.irritable:
        return 'irritable';
      case EtatComportement.lethargique:
        return 'très somnolent';
    }
  }

  String _labelSommeil(QualiteSommeil s) {
    switch (s) {
      case QualiteSommeil.bon:
        return 'bon';
      case QualiteSommeil.moyen:
        return 'moyen';
      case QualiteSommeil.agite:
        return 'agité';
      case QualiteSommeil.mauvais:
        return 'mauvais';
    }
  }

  String _labelAppetit(NiveauAppetit a) {
    switch (a) {
      case NiveauAppetit.normal:
        return 'normal';
      case NiveauAppetit.diminue:
        return 'diminué';
      case NiveauAppetit.faible:
        return 'faible';
      case NiveauAppetit.excessif:
        return 'excessif';
    }
  }
}
