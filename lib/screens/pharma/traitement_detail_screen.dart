import 'package:flutter/material.dart';
import '../../models/acteur.dart';
import '../../models/enfant_model.dart';
import '../../models/prise_medicament_model.dart';
import '../../models/traitement_model.dart';
import '../../data/medicaments_catalogue.dart';
import '../../services/ia_pharma_service.dart';
import '../../services/traitement_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pc_ui.dart';
import 'add_traitement_screen.dart';

/// Fiche d'un traitement : informations, observance et historique des prises.
class TraitementDetailScreen extends StatefulWidget {
  final EnfantModel enfant;
  final TraitementModel traitement;
  final Acteur acteur;

  const TraitementDetailScreen({
    super.key,
    required this.enfant,
    required this.traitement,
    this.acteur = const Acteur.parent(),
  });

  @override
  State<TraitementDetailScreen> createState() => _TraitementDetailScreenState();
}

class _TraitementDetailScreenState extends State<TraitementDetailScreen> {
  static const _violet = Color(0xFF9B59B6);

  late TraitementModel _t;
  List<PriseMedicamentModel> _prises = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _t = widget.traitement;
    _load();
  }

  Future<void> _load() async {
    final prises = await TraitementService.getPrises(traitementId: _t.id);
    if (!mounted) return;
    setState(() {
      _prises = prises;
      _loading = false;
    });
  }

  Future<void> _modifier() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) =>
              AddTraitementScreen(
              enfant: widget.enfant, traitement: _t, acteur: widget.acteur)),
    );
    if (ok != true) return;
    final maj = (await TraitementService.getTraitements(widget.enfant.id))
        .where((x) => x.id == _t.id);
    if (!mounted || maj.isEmpty) return;
    setState(() => _t = maj.first);
  }

  /// Explication IA (Gemini) ou locale du médicament, sans aucune posologie.
  void _expliquer() {
    final future = IaPharmaService.expliquer(_t, widget.enfant);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D2D5E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        builder: (_, scroll) => FutureBuilder<ExplicationMedicament>(
          future: future,
          builder: (_, snap) {
            if (!snap.hasData) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.secondary));
            }
            final e = snap.data!;
            return ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              children: [
                Text(_t.nom,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(e.parIA ? '✨ Explication générée par IA' : '📚 Base de médicaments PediCare',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11.5)),
                const SizedBox(height: 14),
                Text(e.texte,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13.5, height: 1.45)),
                const SizedBox(height: 16),
                const PcAvertissement(avertissementMedicament),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _supprimer() async {
    final ok = await pcConfirmer(context,
        titre: 'Arrêter et supprimer',
        message:
            'Supprimer la prescription « ${_t.nom} », son historique de prises et ses rappels ? Pour simplement arrêter le traitement, modifiez plutôt sa date de fin.');
    if (!ok) return;
    await TraitementService.deleteTraitement(_t.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final stats = ObservanceStats.depuis(_prises);
    return PcPage(
      titre: _t.nom,
      sousTitre: _t.actif ? 'Traitement en cours' : 'Traitement terminé',
      actions: !widget.acteur.estPediatre
          ? const []
          : [
        PcIconButton(icon: Icons.edit_outlined, onTap: _modifier, tooltip: 'Modifier'),
        const SizedBox(width: 8),
        PcIconButton(
            icon: Icons.delete_outline_rounded,
            color: AppColors.danger,
            onTap: _supprimer,
            tooltip: 'Supprimer'),
      ],
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                PcCard(
                  color: _violet,
                  child: Column(
                    children: [
                      _info('Posologie', _t.posologie),
                      _info('Fréquence',
                          _t.heures.isEmpty ? 'Si besoin' : '${_t.frequence} (${_t.heures.join(', ')})'),
                      _info('Début', pcDate(_t.dateDebut)),
                      _info('Fin',
                          _t.dateFin == null ? 'Au long cours' : pcDate(_t.dateFin!)),
                      _info('Médecin prescripteur', _t.medecin),
                      _info('Rappels', _t.rappels ? 'Activés' : 'Désactivés'),
                      _info('Notes', _t.notes),
                    ],
                  ),
                ),
                PcCard(
                  color: AppColors.secondary,
                  onTap: _expliquer,
                  child: const Row(
                    children: [
                      Text('✨', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text('Expliquer ce médicament simplement',
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600)),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: AppColors.textSecondary),
                    ],
                  ),
                ),
                const PcSectionTitle('Observance'),
                Row(
                  children: [
                    _kpi(
                        stats.taux == null
                            ? '—'
                            : '${(stats.taux! * 100).round()} %',
                        'Observance',
                        _violet),
                    const SizedBox(width: 8),
                    _kpi('${stats.pris}', 'Pris', AppColors.accent),
                    const SizedBox(width: 8),
                    _kpi('${stats.oublies}', 'Oubliés', AppColors.danger),
                    const SizedBox(width: 8),
                    _kpi('${stats.reportes}', 'Reportés', const Color(0xFFE67E22)),
                  ],
                ),
                const SizedBox(height: 8),
                PcSectionTitle('Historique des prises (${_prises.length})'),
                if (_prises.isEmpty)
                  const PcEmpty(
                    emoji: '🗓️',
                    titre: 'Aucune prise enregistrée',
                    sousTitre:
                        'Confirmez les prises depuis l\'écran PediPharma : pris, reporté ou oublié.',
                  )
                else
                  ..._prises.map(_priseTile),
              ],
            ),
    );
  }

  Widget _info(String label, String valeur) {
    if (valeur.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ),
          Expanded(
            child: Text(valeur,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _kpi(String valeur, String label, Color color) {
    return Expanded(
      child: PcCard(
        color: color,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        child: Column(
          children: [
            Text(valeur,
                style: TextStyle(
                    color: color, fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 10.5)),
          ],
        ),
      ),
    );
  }

  Widget _priseTile(PriseMedicamentModel p) {
    final color = switch (p.statut) {
      StatutPrise.pris => AppColors.accent,
      StatutPrise.oublie => AppColors.danger,
      StatutPrise.reporte => const Color(0xFFE67E22),
    };
    return PcCard(
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(p.statut.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
                '${pcJourRelatif(p.datePrevue)} · ${pcHeure(p.datePrevue)}',
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 12.5)),
          ),
          Text(p.statut.label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}
