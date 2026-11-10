import 'package:flutter/material.dart';
import '../../models/consultation_model.dart';
import '../../models/enfant_model.dart';

import '../../models/rendezvous_model.dart';
import '../../models/tableau_bord_model.dart';
import '../../models/traitement_model.dart';
import '../../services/journal_pdf_service.dart';
import '../../services/journal_symptome_service.dart';
import '../../services/tableau_bord_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/journal_charts.dart';
import '../consultation/consultation_screen.dart';
import '../journal/journal_symptomes_screen.dart';
import '../nutrition/nutrition_screen.dart';
import '../pharma/pedipharma_screen.dart';
import '../rendezvous/add_rendezvous_screen.dart';
import '../rendezvous/rendezvous_screen.dart';
import '../vaccination/vaccination_screen.dart';

class TableauBordScreen extends StatefulWidget {
  final EnfantModel enfant;

  const TableauBordScreen({super.key, required this.enfant});

  @override
  State<TableauBordScreen> createState() => _TableauBordScreenState();
}

class _TableauBordScreenState extends State<TableauBordScreen> {
  TableauBordData? _data;
  bool _loading = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erreur = null;
    });
    try {
      final data = await TableauBordService.charger(widget.enfant);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = 'Chargement impossible : $e';
        _loading = false;
      });
    }
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
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
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
                const Text('Tableau de bord',
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
          GestureDetector(
            onTap: _loading ? null : _load,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.secondary),
                    )
                  : const Icon(Icons.refresh_rounded,
                      color: AppColors.textPrimary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _data == null) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.secondary));
    }
    if (_erreur != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 46)),
              const SizedBox(height: 12),
              Text(_erreur!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _load,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: AppColors.buttonGradient),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Réessayer',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final data = _data!;
    return RefreshIndicator(
      color: AppColors.secondary,
      backgroundColor: const Color(0xFF0D2D5E),
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
        children: [
          _buildHero(data),
          const SizedBox(height: 14),
          _buildAnalyse(data),
          const SizedBox(height: 18),
          _buildKpis(data),
          const SizedBox(height: 16),
          _buildActionsRapides(data),
          const SizedBox(height: 20),
          _buildSuiviCard(data),
          const SizedBox(height: 20),
          _buildProchainsRdv(data),
          const SizedBox(height: 20),
          _buildVaccination(data),
          const SizedBox(height: 20),
          _buildTraitements(data),
          const SizedBox(height: 20),
          _buildEvenements(data),
          const SizedBox(height: 20),
          _buildConsultations(data),
        ],
      ),
    );
  }

  // ── En-tête enfant ────────────────────────────────────────────────────────
  Widget _buildHero(TableauBordData data) {
    final enfant = data.enfant;
    final isFille = enfant.sexe == 'F';
    final emoji = isFille ? '👧' : '👦';
    final derniere = data.journalRecent.isNotEmpty
        ? data.journalRecent.first
        : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E6FDB), Color(0xFF4DAAFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
              color: Color(0x441E6FDB),
              blurRadius: 20,
              offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white38, width: 2),
                ),
                child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 31))),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(enfant.nomComplet,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      '${enfant.age} ans · ${isFille ? 'Fille' : 'Garçon'}'
                      '${enfant.allergies != null && enfant.allergies!.trim().isNotEmpty ? ' · Allergies : ${enfant.allergies}' : ''}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('📝', style: TextStyle(fontSize: 15)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    derniere == null
                        ? 'Aucune entrée récente — pensez à remplir le journal du jour.'
                        : 'Dernière entrée le ${_fmtDate(derniere.date)} : ${derniere.resumeCourt}'
                            '${derniere.temperature != null ? ' · ${derniere.temperature!.toStringAsFixed(1)} °C' : ''}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              _heroChip('${data.journalStats.entrees7Jours} saisies / 7 j'),
              const SizedBox(width: 7),
              _heroChip('${data.vaccins.length} vaccins'),
              const SizedBox(width: 7),
              _heroChip('${data.prochainsRdv.length} RDV à venir'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroChip(String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ── Analyse IA ────────────────────────────────────────────────────────────
  Widget _buildAnalyse(TableauBordData data) {
    final analyse = data.analyse;
    final color = analyse.aUrgence
        ? AppColors.danger
        : analyse.aAttention
            ? const Color(0xFFE67E22)
            : const Color(0xFF00C9A7);
    return GestureDetector(
      onTap: () => _ouvrirJournal(),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.35)),
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
                        ? 'Analyse IA du journal'
                        : 'Analyse contextuelle du journal',
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
            const SizedBox(height: 7),
            Text(analyse.message,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11.5,
                    height: 1.4)),
            if (analyse.suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                analyse.suggestions.first.texte,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: color, fontSize: 10.5, height: 1.35),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Indicateurs clés ──────────────────────────────────────────────────────
  Widget _buildKpis(TableauBordData data) {
    final stats = data.journalStats;
    final prochainRdv =
        data.prochainsRdv.isNotEmpty ? data.prochainsRdv.first : null;
    final vacc = data.vaccination;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                emoji: '📝',
                label: 'Journal (7 j)',
                value: '${stats.entrees7Jours}',
                sousTitre: '${stats.joursRenseignes7Jours}/7 jours renseignés',
                color: const Color(0xFF4DAAFF),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _kpiCard(
                emoji: '🌡️',
                label: 'Température moy.',
                value: stats.temperatureMoyenneLabel,
                sousTitre: stats.temperatureMax7Jours == null
                    ? 'Aucune mesure'
                    : 'Max ${stats.temperatureMax7Jours!.toStringAsFixed(1)} °C · ${stats.joursFievre7Jours} j de fièvre',
                color: stats.joursFievre7Jours > 0
                    ? AppColors.danger
                    : const Color(0xFF00C9A7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                emoji: '📅',
                label: 'Prochain RDV',
                value: prochainRdv == null
                    ? '—'
                    : _dansCombien(prochainRdv.dateHeure),
                sousTitre: prochainRdv == null
                    ? 'Aucun rendez-vous planifié'
                    : '${_fmtDate(prochainRdv.dateHeure)} · ${prochainRdv.titre}',
                color: const Color(0xFF1E6FDB),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _kpiCard(
                emoji: '💉',
                label: 'Vaccination',
                value: '${vacc.faits}/${vacc.total}',
                sousTitre: vacc.enRetard > 0
                    ? '${vacc.enRetard} vaccin(s) en retard'
                    : 'Calendrier à jour',
                color: vacc.enRetard > 0
                    ? const Color(0xFFE67E22)
                    : const Color(0xFF00C9A7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _kpiCard({
    required String emoji,
    required String label,
    required String value,
    required String sousTitre,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 17)),
              const SizedBox(width: 7),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: color, fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(sousTitre,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 9, height: 1.25)),
        ],
      ),
    );
  }

  // ── Actions rapides ───────────────────────────────────────────────────────
  Widget _buildActionsRapides(TableauBordData data) {
    return Row(
      children: [
        _actionRapide('📝', 'Journal', _ouvrirJournal),
        const SizedBox(width: 8),
        _actionRapide('🤖', 'Résumé IA', _ouvrirConsultations),
        const SizedBox(width: 8),
        _actionRapide('🥗', 'Nutrition', _ouvrirNutrition),
        const SizedBox(width: 8),
        _actionRapide('📄', 'Rapport PDF', () => _partagerPdf(data)),
        const SizedBox(width: 8),
        _actionRapide('📅', 'Ajouter RDV', _ouvrirAjoutRdv),
      ],
    );
  }

  Widget _actionRapide(String emoji, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 5),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Statistiques de suivi ─────────────────────────────────────────────────
  Widget _buildSuiviCard(TableauBordData data) {
    final mesure = data.derniereMesure;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📈', style: TextStyle(fontSize: 17)),
              SizedBox(width: 8),
              Expanded(
                child: Text('Statistiques de suivi',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ),
              Text('7 derniers jours',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 9.5)),
            ],
          ),
          const SizedBox(height: 10),
          JournalBarChart(serie: data.serieJournaliere, height: 140),
          const SizedBox(height: 10),
          const Divider(color: Colors.white12, height: 12),
          const Text('Température',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          TemperatureLineChart(entrees: data.journalRecent, height: 130),
          if (mesure != null) ...[
            const Divider(color: Colors.white12, height: 18),
            Row(
              children: [
                const Text('📏', style: TextStyle(fontSize: 15)),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Dernière mesure le ${_fmtDate(mesure.date)}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 10),
                  ),
                ),
                Text(
                  '${mesure.poids} kg · ${mesure.taille} cm · IMC ${mesure.imc.toStringAsFixed(1)}',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Prochains rendez-vous ─────────────────────────────────────────────────
  Widget _buildProchainsRdv(TableauBordData data) {
    return _section(
      titre: 'Prochains rendez-vous',
      emoji: '📅',
      actionLabel: 'Tout voir',
      onAction: _ouvrirRdv,
      child: data.prochainsRdv.isEmpty
          ? _emptyLine('Aucun rendez-vous à venir.')
          : Column(
              children: data.prochainsRdv
                  .take(3)
                  .map((r) => _rdvTile(r))
                  .toList(),
            ),
    );
  }

  Widget _rdvTile(RendezVousModel r) {
    final color = _joursRestants(r.dateHeure) <= 2
        ? AppColors.danger
        : const Color(0xFF4DAAFF);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text('${r.dateHeure.day}',
                    style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                Text(_moisCourt(r.dateHeure),
                    style: TextStyle(color: color, fontSize: 8.5)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.titre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '${r.medecin.isEmpty ? 'Médecin non renseigné' : 'Dr. ${r.medecin}'}'
                  ' · ${_fmtTime(r.dateHeure)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _dansCombien(r.dateHeure),
              style: TextStyle(
                  color: color, fontSize: 8.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ── Vaccination ───────────────────────────────────────────────────────────
  Widget _buildVaccination(TableauBordData data) {
    final v = data.vaccination;
    return _section(
      titre: 'Vaccinations',
      emoji: '💉',
      actionLabel: 'Gérer',
      onAction: _ouvrirVaccination,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _vaccStat('Faits', '${v.faits}', const Color(0xFF00C9A7)),
              _vaccStat('En retard', '${v.enRetard}',
                  v.enRetard > 0 ? AppColors.danger : AppColors.textSecondary),
              _vaccStat('À venir', '${v.aVenir}', const Color(0xFF4DAAFF)),
              _vaccStat('Total', '${v.total}', AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: v.couverture,
              minHeight: 6,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF00C9A7)),
            ),
          ),
          const SizedBox(height: 10),
          if (v.prochainVaccin != null)
            Row(
              children: [
                const Text('➡️', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Prochain : ${v.prochainVaccin}'
                    '${v.prochaineEcheance != null ? ' · ${_fmtDate(v.prochaineEcheance!)}' : ''}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 10.5),
                  ),
                ),
              ],
            )
          else
            const Text('Calendrier vaccinal complet.',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 10.5)),
        ],
      ),
    );
  }

  Widget _vaccStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 15, fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 8.5)),
        ],
      ),
    );
  }

  // ── Traitements actifs ────────────────────────────────────────────────────
  Widget _buildTraitements(TableauBordData data) {
    return _section(
      titre: 'Traitements actifs',
      emoji: '💊',
      actionLabel: 'PediPharma',
      onAction: _ouvrirPediPharma,
      child: data.traitementsActifs.isEmpty
          ? _emptyLine('Aucun traitement actif enregistré.')
          : Column(
              children: data.traitementsActifs
                  .map((t) => _traitementTile(t))
                  .toList(),
            ),
    );
  }

  Widget _traitementTile(TraitementModel t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFF9B59B6).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF9B59B6).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
                child: Text('💊', style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.nom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  [
                    if (t.posologie.isNotEmpty) t.posologie,
                    if (t.frequence.isNotEmpty) t.frequence,
                    if (t.dateFin != null)
                      'jusqu\'au ${_fmtDate(t.dateFin!)}',
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 9.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Derniers événements ───────────────────────────────────────────────────
  Widget _buildEvenements(TableauBordData data) {
    return _section(
      titre: 'Derniers événements',
      emoji: '🕒',
      child: data.evenements.isEmpty
          ? _emptyLine('Aucun événement enregistré.')
          : Column(
              children: data.evenements
                  .take(8)
                  .map((e) => _evenementTile(e))
                  .toList(),
            ),
    );
  }

  Widget _evenementTile(EvenementDashboard e) {
    final color = _couleurEvenement(e.type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
                child: Text(e.emoji, style: const TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.titre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 1),
                Text(e.sousTitre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 9.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _dateRelative(e.date),
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 8.5),
          ),
        ],
      ),
    );
  }

  Color _couleurEvenement(String type) {
    switch (type) {
      case 'journal':
        return const Color(0xFF4DAAFF);
      case 'vaccin':
        return const Color(0xFF00C9A7);
      case 'rdv':
        return const Color(0xFF1E6FDB);
      case 'croissance':
        return const Color(0xFF9B59B6);
      case 'consultation':
        return const Color(0xFFE67E22);
      default:
        return AppColors.secondary;
    }
  }

  // ── Résumés de consultation ───────────────────────────────────────────────
  Widget _buildConsultations(TableauBordData data) {
    final dernier = data.dernierResume;
    return _section(
      titre: 'Consultations & résumés',
      emoji: '🩺',
      actionLabel: 'Historique',
      onAction: _ouvrirConsultations,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dernier == null)
            _emptyLine('Aucun résumé généré pour le moment.')
          else
            _resumeTile(dernier),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Générez une synthèse avant la consultation.',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 10),
                ),
              ),
              GestureDetector(
                onTap: _ouvrirConsultations,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF4285F4), Color(0xFF0F9D58)]),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Text('Résumé IA',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resumeTile(ConsultationModel c) {
    final color =
        c.genereeIA ? const Color(0xFF9B59B6) : const Color(0xFF1E6FDB);
    return GestureDetector(
      onTap: _ouvrirConsultations,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Text('📄', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.titre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    '${_fmtDate(c.createdAt)} · ${c.genereeIA ? 'Gemini' : 'Moteur local'} · ${c.nbEntrees} entrée(s)',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 9.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }

  // ── Bloc générique ────────────────────────────────────────────────────────
  Widget _section({
    required String titre,
    required String emoji,
    Widget? child,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 7),
              Expanded(
                child: Text(titre,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700)),
              ),
              if (actionLabel != null)
                GestureDetector(
                  onTap: onAction,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(actionLabel,
                        style: const TextStyle(
                            color: AppColors.secondary,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ?child,
        ],
      ),
    );
  }

  Widget _emptyLine(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(message,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 10.5)),
    );
  }

  // ── Navigation & actions ──────────────────────────────────────────────────
  Future<void> _ouvrirJournal() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JournalSymptomesScreen(enfant: widget.enfant),
      ),
    );
    _load();
  }

  Future<void> _ouvrirConsultations() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConsultationScreen(enfant: widget.enfant),
      ),
    );
    _load();
  }

  Future<void> _ouvrirRdv() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RendezVousScreen(
          enfantId: widget.enfant.id,
          enfantNom: widget.enfant.nomComplet,
        ),
      ),
    );
    _load();
  }

  Future<void> _ouvrirAjoutRdv() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddRendezVousScreen(enfantId: widget.enfant.id),
      ),
    );
    _load();
  }

  Future<void> _ouvrirVaccination() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VaccinationScreen(
          enfantId: widget.enfant.id,
          enfantNom: widget.enfant.nomComplet,
          enfant: widget.enfant,
        ),
      ),
    );
    _load();
  }

  Future<void> _partagerPdf(TableauBordData data) async {
    try {
      final journal =
          await JournalSymptomeService.getEntrees(widget.enfant.id);
      if (journal.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le journal est vide : ajoutez une entrée avant d\'exporter.'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      await JournalPdfService.partagerRapport(
        enfant: widget.enfant,
        journal: journal,
        stats: data.journalStats,
        analyse: data.analyse,
        consultation: data.dernierResume,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export impossible : $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Traitements : prescrits par le pédiatre, le parent confirme les prises.
  Future<void> _ouvrirPediPharma() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PediPharmaScreen(enfant: widget.enfant)),
    );
    await _load();
  }

  /// Nutrition : en lecture seule pour le parent (sauf l'allaitement).
  Future<void> _ouvrirNutrition() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NutritionScreen(enfant: widget.enfant)),
    );
    await _load();
  }

  // ── Helpers de dates ──────────────────────────────────────────────────────
  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';

  String _moisCourt(DateTime d) {
    const mois = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
        'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return mois[d.month - 1];
  }

  int _joursRestants(DateTime d) {
    final now = DateTime.now();
    final a = DateTime(now.year, now.month, now.day);
    final b = DateTime(d.year, d.month, d.day);
    return b.difference(a).inDays;
  }

  String _dansCombien(DateTime d) {
    final jours = _joursRestants(d);
    if (jours == 0) return 'Aujourd\'hui';
    if (jours == 1) return 'Demain';
    if (jours > 1) return 'Dans $jours j';
    return 'Il y a ${-jours} j';
  }

  String _dateRelative(DateTime d) {
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(d.year, d.month, d.day))
        .inDays;
    if (diff == 0) return 'Aujourd\'hui';
    if (diff == 1) return 'Hier';
    if (diff > 1) return 'Il y a $diff j';
    return _fmtDate(d);
  }
}




