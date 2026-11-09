import 'package:flutter/material.dart';
import '../../models/analyse_symptomes_model.dart';
import '../../models/consultation_model.dart';
import '../../models/enfant_model.dart';
import '../../services/consultation_service.dart';
import '../../services/croissance_service.dart';
import '../../services/ia_consultation_service.dart';
import '../../services/journal_pdf_service.dart';
import '../../services/journal_symptome_service.dart';
import '../../services/rendezvous_service.dart';
import '../../services/traitement_service.dart';
import '../../services/vaccin_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/gradient_button.dart';

class ResumeConsultationScreen extends StatefulWidget {
  final EnfantModel enfant;
  final ConsultationModel? consultation;

  const ResumeConsultationScreen({
    super.key,
    required this.enfant,
    this.consultation,
  });

  @override
  State<ResumeConsultationScreen> createState() =>
      _ResumeConsultationScreenState();
}

class _ResumeConsultationScreenState extends State<ResumeConsultationScreen> {
  ResumeConsultationIA? _resume;
  bool _loading = false;
  bool _saving = false;
  bool _saved = false;
  String? _savedId;
  String? _erreur;

  bool get _estExistant => widget.consultation != null;

  @override
  void initState() {
    super.initState();
    if (_estExistant) {
      _saved = true;
      _savedId = widget.consultation!.id;
    } else {
      _generer();
    }
  }

  Future<void> _generer() async {
    setState(() {
      _loading = true;
      _erreur = null;
      _resume = null;
    });

    try {
      final journal = await JournalSymptomeService.getEntrees(widget.enfant.id);
      final vaccins = await VaccinService.getVaccins(widget.enfant.id);
      final rdvs = await RendezVousService.getRendezVous(widget.enfant.id);
      final mesures = await CroissanceService.getMesures(widget.enfant.id);
      final traitements =
          await TraitementService.getActifs(widget.enfant.id);
      final derniereMesure =
          mesures.isNotEmpty ? mesures.first : null;

      final resume = await IAConsultationService.genererResumeConsultation(
        enfant: widget.enfant,
        journal: journal,
        vaccins: vaccins,
        rendezvous: rdvs,
        derniereMesure: derniereMesure,
        traitements: traitements,
      );

      if (!mounted) return;
      setState(() {
        _resume = resume;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = 'Impossible de générer le résumé : $e';
        _loading = false;
      });
    }
  }

  ConsultationModel? get _consultationCourante {
    if (_estExistant) return widget.consultation;
    final r = _resume;
    if (r == null) return null;
    return ConsultationModel(
      id: _savedId ?? '',
      enfantId: widget.enfant.id,
      titre: r.titre,
      resume: r.resume,
      pointsCles: r.pointsCles.join('\n'),
      suggestions: r.suggestions.join('\n'),
      periodeDebut: r.periodeDebut,
      periodeFin: r.periodeFin,
      nbEntrees: r.nbEntrees,
      genereeIA: r.genereeIA,
      createdAt: DateTime.now(),
    );
  }

  Future<void> _enregistrer() async {
    final model = _consultationCourante;
    if (model == null || _saved) return;

    setState(() => _saving = true);
    final id = await ConsultationService.addConsultation(model);
    if (!mounted) return;
    setState(() => _saving = false);

    if (id != null) {
      setState(() {
        _saved = true;
        _savedId = id;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Résumé enregistré dans l\'historique.'),
          backgroundColor: Color(0xFF00C9A7),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enregistrement impossible.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _partager() async {
    final model = _consultationCourante;
    if (model == null) return;
    try {
      await JournalPdfService.partagerResume(
          enfant: widget.enfant, consultation: model);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Partage impossible : $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
              Expanded(
                child: _loading
                    ? _buildLoading()
                    : _erreur != null
                        ? _buildErreur()
                        : _buildContenu(),
              ),
              if (!_loading && _erreur == null) _buildActions(),
            ],
          ),
        ),
      ),
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Résumé pré-consultation',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                Text('Synthèse du journal et de l\'historique',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF0F9D58)),
          SizedBox(height: 18),
          Text('Analyse du journal et de l\'historique…',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          SizedBox(height: 4),
          Text('Génération du résumé structuré',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildErreur() {
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
            const SizedBox(height: 18),
            GestureDetector(
              onTap: _generer,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF4285F4), Color(0xFF0F9D58)]),
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

  Widget _buildContenu() {
    final c = _consultationCourante;
    if (c == null) return const SizedBox.shrink();
    final couleur = c.genereeIA ? const Color(0xFF9B59B6) : const Color(0xFF1E6FDB);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      children: [
        _buildEnfantCard(),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: couleur.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: couleur.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Text(c.genereeIA ? '🤖' : '🧠',
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.genereeIA
                          ? 'Résumé généré avec Gemini'
                          : 'Résumé généré par le moteur PediCare',
                      style: TextStyle(
                          color: couleur,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_fmtDate(c.periodeDebut)} → ${_fmtDate(c.periodeFin)}'
                      ' · ${c.nbEntrees} entrée(s) du journal',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionTitle('Résumé général', '📋'),
        const SizedBox(height: 8),
        _card(
          child: Text(c.resume,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13, height: 1.55)),
        ),
        if (c.pointsClesListe.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionTitle('Points clés', '🔎'),
          const SizedBox(height: 8),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: c.pointsClesListe
                  .map((p) => _puced(p, const Color(0xFF4DAAFF)))
                  .toList(),
            ),
          ),
        ],
        if (c.suggestionsListe.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionTitle('Suggestions de suivi', '💡'),
          const SizedBox(height: 8),
          _card(
            color: const Color(0xFFE67E22).withValues(alpha: 0.08),
            borderColor: const Color(0xFFE67E22).withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: c.suggestionsListe
                  .map((s) => _puced(s, const Color(0xFFE67E22)))
                  .toList(),
            ),
          ),
        ],
        const SizedBox(height: 16),
        const Text(
          'Ce résumé est généré automatiquement à titre informatif. '
          'Il ne remplace pas l\'examen clinique ni l\'avis du pédiatre.',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              height: 1.4,
              fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildEnfantCard() {
    final isFille = widget.enfant.sexe == 'F';
    final color =
        isFille ? const Color(0xFFE91E8C) : const Color(0xFF1E6FDB);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
                child: Text(isFille ? '👧' : '👦',
                    style: const TextStyle(fontSize: 25))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.enfant.nomComplet,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  '${widget.enfant.age} ans · ${isFille ? 'Fille' : 'Garçon'}'
                  '${widget.enfant.allergies != null && widget.enfant.allergies!.trim().isNotEmpty ? ' · Allergies : ${widget.enfant.allergies}' : ''}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String titre, String emoji) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 7),
        Text(titre,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _card({
    required Widget child,
    Color? color,
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color ?? AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor ?? AppColors.glassBorder),
      ),
      child: child,
    );
  }

  Widget _puced(String texte, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texte,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    height: 1.45)),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final peutEnregistrer = !_estExistant && !_saved;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        children: [
          if (peutEnregistrer) ...[
            GradientButton(
              label: 'Enregistrer dans l\'historique',
              onTap: _enregistrer,
              loading: _saving,
            ),
            const SizedBox(height: 10),
          ] else if (_saved) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFF00C9A7).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF00C9A7).withValues(alpha: 0.35)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Color(0xFF00C9A7), size: 16),
                  SizedBox(width: 7),
                  Text('Résumé enregistré',
                      style: TextStyle(
                          color: Color(0xFF00C9A7),
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: _boutonSecondaire(
                  label: 'Partager',
                  icon: Icons.ios_share_rounded,
                  onTap: _partager,
                  color: const Color(0xFF00C9A7),
                ),
              ),
              if (!_estExistant) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _boutonSecondaire(
                    label: _saved ? 'Nouveau' : 'Régénérer',
                    icon: Icons.refresh_rounded,
                    onTap: () {
                      if (_saved) {
                        Navigator.pop(context);
                      } else {
                        _generer();
                      }
                    },
                    color: const Color(0xFF4DAAFF),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _boutonSecondaire({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
