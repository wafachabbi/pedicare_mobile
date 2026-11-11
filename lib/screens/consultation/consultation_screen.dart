import 'package:flutter/material.dart';
import '../../models/acteur.dart';
import '../../models/consultation_model.dart';
import '../../models/enfant_model.dart';
import '../../models/observation_consultation_model.dart';
import '../../models/rendezvous_model.dart';
import '../../services/consultation_service.dart';
import '../../services/journal_pdf_service.dart';
import '../../services/observation_consultation_service.dart';
import '../../services/rendezvous_service.dart';
import '../../theme/app_colors.dart';
import 'add_observation_screen.dart';
import 'resume_consultation_screen.dart';

class ConsultationScreen extends StatefulWidget {
  final EnfantModel enfant;

  /// Mode pédiatre : consultation des résumés, sans génération ni suppression.
  final bool lectureSeule;

  /// Pédiatre connecté : il saisit les données de la consultation
  /// (observations, diagnostic…). Le parent en génère ensuite le résumé IA.
  final Acteur? pediatre;

  const ConsultationScreen(
      {super.key,
      required this.enfant,
      this.lectureSeule = false,
      this.pediatre});

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  List<ConsultationModel> _consultations = [];
  List<RendezVousModel> _historique = [];
  List<ObservationConsultationModel> _observations = [];

  /// observation_id → résumé IA généré par le parent.
  Map<String, ConsultationModel> _resumesParObservation = {};
  bool _loading = true;

  bool get _estPediatre => widget.pediatre?.estPediatre ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final consultations =
        await ConsultationService.getConsultations(widget.enfant.id);
    final rdvs = await RendezVousService.getRendezVous(widget.enfant.id);
    final observations =
        await ObservationConsultationService.getObservations(widget.enfant.id);
    final parObservation = <String, ConsultationModel>{
      for (final c in consultations)
        if (c.observationId != null) c.observationId!: c,
    };
    final now = DateTime.now();
    final historique = rdvs
        .where((r) =>
            r.dateHeure.isBefore(now) || r.statut == StatutRDV.termine)
        .toList()
      ..sort((a, b) => b.dateHeure.compareTo(a.dateHeure));
    if (!mounted) return;
    setState(() {
      _consultations = consultations;
      _historique = historique;
      _observations = observations;
      _resumesParObservation = parObservation;
      _loading = false;
    });
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
      floatingActionButton: _estPediatre
          ? _buildFABPediatre(context)
          : widget.lectureSeule
              ? null
              : _buildFAB(context),
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
                const Text('Consultations',
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
          if (!widget.lectureSeule)
          GestureDetector(
            onTap: () => _ouvrirGeneration(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF4285F4), Color(0xFF0F9D58)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🤖', style: TextStyle(fontSize: 15)),
                  SizedBox(width: 6),
                  Text('Résumé IA',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 100),
      children: [
        _buildHero(),
        const SizedBox(height: 22),
        _buildSectionTitle('Consultations du pédiatre',
            '${_observations.length} consultation(s)'),
        const SizedBox(height: 10),
        if (_observations.isEmpty)
          _buildEmptyLine(_estPediatre
              ? 'Ajoutez les données de la consultation avec « Nouvelle consultation ».'
              : "Le pédiatre n'a encore saisi aucune consultation.")
        else
          ..._observations.map(_buildObservationCard),
        const SizedBox(height: 22),
        _buildSectionTitle('Historique des rendez-vous',
            '${_historique.length} rendez-vous passé(s)'),
        const SizedBox(height: 10),
        if (_historique.isEmpty)
          _buildEmptyLine('Aucune consultation passée enregistrée.')
        else
          ..._historique.take(8).map(_buildRdvTile),
        const SizedBox(height: 22),
        _buildSectionTitle('Résumés générés',
            '${_consultations.length} résumé(s)'),
        const SizedBox(height: 10),
        if (_consultations.isEmpty)
          _buildEmptyResumes()
        else
          ..._consultations.map(_buildConsultationCard),
      ],
    );
  }

  Widget _buildHero() {
    final dernier = _consultations.isNotEmpty ? _consultations.first : null;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4285F4), Color(0xFF0F9D58)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x332A8B57),
              blurRadius: 18,
              offset: Offset(0, 7)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🤖', style: TextStyle(fontSize: 26)),
              SizedBox(width: 10),
              Expanded(
                child: Text('Résumé intelligent pré-consultation',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'PediCare agrège le journal des symptômes, les vaccinations, la croissance, '
            'les traitements et les rendez-vous pour préparer la consultation avec le pédiatre.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 11.5,
                height: 1.45),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (!widget.lectureSeule)
              Expanded(
                child: GestureDetector(
                  onTap: () => _ouvrirGeneration(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome,
                            color: Color(0xFF0F9D58), size: 16),
                        SizedBox(width: 7),
                        Text('Générer un résumé',
                            style: TextStyle(
                                color: Color(0xFF0F6B3D),
                                fontSize: 12,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ),
              if (dernier != null) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _ouvrirResume(dernier),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: const Text('Dernier',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String titre, String sousTitre) {
    return Row(
      children: [
        Expanded(
          child: Text(titre,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
        ),
        Text(sousTitre,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 10)),
      ],
    );
  }

  Widget _buildRdvTile(RendezVousModel rdv) {
    final termine = rdv.statut == StatutRDV.termine;
    final annule = rdv.statut == StatutRDV.annule;
    final color = annule
        ? AppColors.danger
        : termine
            ? const Color(0xFF00C9A7)
            : const Color(0xFF4DAAFF);
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text('${rdv.dateHeure.day}',
                    style: TextStyle(
                        color: color,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
                Text(_moisCourt(rdv.dateHeure),
                    style: TextStyle(
                        color: color, fontSize: 9)),
              ],
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rdv.titre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '${rdv.medecin.isEmpty ? 'Médecin non renseigné' : 'Dr. ${rdv.medecin}'}'
                  '${rdv.specialite.isEmpty ? '' : ' · ${rdv.specialite}'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 10.5),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              annule ? 'Annulé' : termine ? 'Terminé' : 'Passé',
              style: TextStyle(
                  color: color, fontSize: 9, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationCard(ConsultationModel c) {
    final color =
        c.genereeIA ? const Color(0xFF9B59B6) : const Color(0xFF1E6FDB);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Center(
                    child: Text('📄', style: TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.titre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      '${_fmtDate(c.createdAt)} · ${c.nbEntrees} entrée(s)',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  c.genereeIA ? 'IA' : 'Local',
                  style: TextStyle(
                      color: color,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            c.resume,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _action('Ouvrir', Icons.open_in_new_rounded,
                  () => _ouvrirResume(c)),
              const SizedBox(width: 8),
              _action('Partager', Icons.ios_share_rounded,
                  () => _partager(c), color: const Color(0xFF00C9A7)),
              const Spacer(),
              if (!widget.lectureSeule)
                _action('Supprimer', Icons.delete_outline_rounded,
                  () => _supprimer(c), color: AppColors.danger),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(String label, IconData icon, VoidCallback onTap,
      {Color? color}) {
    final c = color ?? AppColors.secondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: c, size: 12),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: c, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyResumes() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: const Column(
        children: [
          Text('🧠', style: TextStyle(fontSize: 38)),
          SizedBox(height: 10),
          Text('Aucun résumé généré',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text(
            'Générez un résumé structuré avant votre prochaine consultation.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLine(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Text(message,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 11)),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return GestureDetector(
      onTap: () => _ouvrirGeneration(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF4285F4), Color(0xFF0F9D58)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x332A8B57),
                blurRadius: 16,
                offset: Offset(0, 6)),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Générer un résumé',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5)),
          ],
        ),
      ),
    );
  }

  // ── Consultations saisies par le pédiatre ─────────────────────────────────
  Widget _buildObservationCard(ObservationConsultationModel o) {
    const color = Color(0xFFE67E22);
    final resume = _resumesParObservation[o.id];
    final mesures = [
      if (o.poids != null) '${o.poids} kg',
      if (o.taille != null) '${o.taille} cm',
      if (o.temperature != null) '${o.temperature!.toStringAsFixed(1)} °C',
    ].join(' · ');
    Widget ligne(String label, String valeur) => valeur.trim().isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                    text: '$label : ',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700)),
                TextSpan(text: valeur.trim()),
              ]),
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11, height: 1.4),
            ),
          );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🩺', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.motif,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    Text('${_fmtDate(o.dateConsultation)} · ${o.signature}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 10.5)),
                  ],
                ),
              ),
              if (resume != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9B59B6).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Text('Résumé IA',
                      style: TextStyle(
                          color: Color(0xFF9B59B6),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800)),
                ),
            ],
          ),
          ligne('Mesures', mesures),
          ligne('Observations', o.observations),
          ligne('Diagnostic', o.diagnostic),
          ligne('Traitement', o.traitement),
          ligne('Recommandations', o.recommandations.replaceAll('\n', ' ; ')),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (resume != null)
                _action('Voir le résumé IA', Icons.auto_awesome,
                    () => _ouvrirResume(resume),
                    color: const Color(0xFF9B59B6))
              else if (!_estPediatre && !widget.lectureSeule)
                _action('Générer le résumé IA', Icons.auto_awesome,
                    () => _genererDepuisObservation(o),
                    color: const Color(0xFF0F9D58)),
              if (_estPediatre) ...[
                _action('Modifier', Icons.edit_outlined,
                    () => _editerObservation(o)),
                _action('Supprimer', Icons.delete_outline_rounded,
                    () => _supprimerObservation(o),
                    color: AppColors.danger),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editerObservation([ObservationConsultationModel? o]) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddObservationScreen(
          enfant: widget.enfant,
          pediatre: widget.pediatre!,
          existante: o,
        ),
      ),
    );
    if (ok == true) _load();
  }

  Future<void> _genererDepuisObservation(ObservationConsultationModel o) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ResumeConsultationScreen(enfant: widget.enfant, observation: o),
      ),
    );
    _load();
  }

  Future<void> _supprimerObservation(ObservationConsultationModel o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D2D5E),
        title: const Text('Supprimer la consultation ?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
            'Les données saisies et le résumé IA associé seront supprimés.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Supprimer',
                  style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok != true) return;
    await ObservationConsultationService.deleteObservation(o.id);
    _load();
  }

  Widget _buildFABPediatre(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _editerObservation(),
      backgroundColor: const Color(0xFFE67E22),
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text('Nouvelle consultation',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  Future<void> _ouvrirGeneration(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResumeConsultationScreen(enfant: widget.enfant),
      ),
    );
    _load();
  }

  void _ouvrirResume(ConsultationModel c) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResumeConsultationScreen(
          enfant: widget.enfant,
          consultation: c,
        ),
      ),
    ).then((_) => _load());
  }

  Future<void> _partager(ConsultationModel c) async {
    try {
      await JournalPdfService.partagerResume(
          enfant: widget.enfant, consultation: c);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Partage impossible : $e'),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _supprimer(ConsultationModel c) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D2D5E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer le résumé',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        content: const Text('Ce résumé sera définitivement supprimé.',
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
    await ConsultationService.deleteConsultation(c.id);
    _load();
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _moisCourt(DateTime d) {
    const mois = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
        'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return mois[d.month - 1];
  }
}
