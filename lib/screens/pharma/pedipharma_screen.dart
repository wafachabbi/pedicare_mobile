import 'package:flutter/material.dart';
import '../../models/acteur.dart';
import '../../models/enfant_model.dart';
import '../../models/prise_medicament_model.dart';
import '../../models/traitement_model.dart';
import '../../services/traitement_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pc_ui.dart';
import 'add_traitement_screen.dart';
import 'traitement_detail_screen.dart';

/// Module 5 — PediPharma : prises du jour, traitements en cours et passés.
///
/// Le pédiatre prescrit (ajout / modification / arrêt des traitements) ;
/// le parent consulte les traitements et confirme les prises.
class PediPharmaScreen extends StatefulWidget {
  final EnfantModel enfant;
  final Acteur acteur;
  const PediPharmaScreen(
      {super.key, required this.enfant, this.acteur = const Acteur.parent()});

  @override
  State<PediPharmaScreen> createState() => _PediPharmaScreenState();
}

class _PediPharmaScreenState extends State<PediPharmaScreen> {
  static const _violet = Color(0xFF9B59B6);

  List<TraitementModel> _traitements = [];
  List<DoseDuJour> _doses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    // Remet les rappels à jour (annule ceux des traitements terminés).
    TraitementService.synchroniserRappels(widget.enfant.id,
        enfantPrenom: widget.enfant.prenom);
  }

  Future<void> _load() async {
    final traitements = await TraitementService.getTraitements(widget.enfant.id);
    final doses = await TraitementService.getDosesDuJour(widget.enfant.id);
    if (!mounted) return;
    setState(() {
      _traitements = traitements;
      _doses = doses;
      _loading = false;
    });
  }

  Future<void> _ouvrirFormulaire([TraitementModel? t]) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) =>
              AddTraitementScreen(
              enfant: widget.enfant, traitement: t, acteur: widget.acteur)),
    );
    if (ok == true) _load();
  }

  Future<void> _ouvrirDetail(TraitementModel t) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) =>
              TraitementDetailScreen(
              enfant: widget.enfant, traitement: t, acteur: widget.acteur)),
    );
    _load();
  }

  Future<void> _confirmer(DoseDuJour d, StatutPrise statut) async {
    final ok = await TraitementService.enregistrerPrise(
      traitement: d.traitement,
      datePrevue: d.heure,
      statut: statut,
      enfantPrenom: widget.enfant.prenom,
    );
    if (!mounted) return;
    if (!ok) {
      pcSnack(context, 'Impossible d\'enregistrer la prise.', erreur: true);
      return;
    }
    if (statut == StatutPrise.reporte) {
      pcSnack(context, 'Rappel dans 30 minutes.');
    }
    _load();
  }

  Future<void> _annuler(DoseDuJour d) async {
    if (d.prise == null) return;
    await TraitementService.annulerPrise(d.prise!.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final actifs = _traitements.where((t) => t.actif).toList();
    final termines = _traitements.where((t) => !t.actif).toList();
    final restantes = _doses.where((d) => d.enAttente).length;

    return PcPage(
      titre: 'PediPharma',
      sousTitre: 'Traitements de ${widget.enfant.prenom}',
      fab: !widget.acteur.estPediatre
          ? null
          : FloatingActionButton.extended(
        onPressed: () => _ouvrirFormulaire(),
        backgroundColor: _violet,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Prescrire',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                children: [
                  PcSectionTitle(
                    'Prises du jour',
                    trailing: _doses.isEmpty
                        ? null
                        : Text(
                            restantes == 0
                                ? 'Tout est fait ✓'
                                : '$restantes à donner',
                            style: TextStyle(
                                color: restantes == 0
                                    ? AppColors.accent
                                    : const Color(0xFFE67E22),
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                  ),
                  if (_doses.isEmpty)
                    const PcCard(
                      color: _violet,
                      child: Text(
                        'Aucune prise prévue aujourd\'hui.',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12.5),
                      ),
                    )
                  else
                    ..._doses.map(_doseTile),
                  const SizedBox(height: 8),
                  PcSectionTitle('Traitements en cours (${actifs.length})'),
                  if (actifs.isEmpty)
                    PcEmpty(
                      emoji: '💊',
                      titre: 'Aucun traitement en cours',
                      sousTitre: widget.acteur.estPediatre
                          ? 'Prescrivez un médicament : le parent recevra les rappels de prise.'
                          : 'Les traitements sont prescrits par le pédiatre. Partagez le dossier de l\'enfant avec lui depuis sa fiche.',
                    )
                  else
                    ...actifs.map(_traitementTile),
                  if (termines.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    PcSectionTitle('Traitements terminés (${termines.length})'),
                    ...termines.map(_traitementTile),
                  ],
                  const SizedBox(height: 8),
                  const PcAvertissement(
                    'PediPharma aide à suivre les traitements prescrits. '
                    'Ne modifiez jamais une posologie sans l\'avis du médecin '
                    'ou du pharmacien.',
                  ),
                ],
              ),
            ),
    );
  }

  Widget _doseTile(DoseDuJour d) {
    final now = DateTime.now();
    final statut = d.prise?.statut;
    final retard = d.enRetard(now);
    final couleur = switch (statut) {
      StatutPrise.pris => AppColors.accent,
      StatutPrise.oublie => AppColors.danger,
      _ => retard ? const Color(0xFFE67E22) : _violet,
    };

    return PcCard(
      color: couleur,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(pcHeure(d.heure),
                    style: TextStyle(
                        color: couleur,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.traitement.nom,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700)),
                    if (d.traitement.posologie.isNotEmpty)
                      Text(d.traitement.posologie,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 11.5)),
                  ],
                ),
              ),
              if (statut != null && statut != StatutPrise.reporte)
                GestureDetector(
                  onTap: widget.acteur.estPediatre ? null : () => _annuler(d),
                  child: Text('${statut.emoji} ${statut.label}',
                      style: TextStyle(
                          color: couleur,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ),
            ],
          ),
          if (d.enAttente && widget.acteur.estPediatre)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                  retard ? 'Non confirmée par le parent (en retard)' : 'À donner par le parent',
                  style: TextStyle(color: couleur, fontSize: 11.5)),
            ),
          if (d.enAttente && !widget.acteur.estPediatre) ...[
            if (statut == StatutPrise.reporte || retard)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                    statut == StatutPrise.reporte
                        ? '⏰ Reportée à ${pcHeure(d.prise!.dateAction.add(const Duration(minutes: 30)))}'
                        : 'En retard',
                    style: const TextStyle(
                        color: Color(0xFFE67E22), fontSize: 11.5)),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                _actionBtn('✅ Pris', AppColors.accent,
                    () => _confirmer(d, StatutPrise.pris)),
                const SizedBox(width: 8),
                _actionBtn('⏰ Reporter', const Color(0xFFE67E22),
                    () => _confirmer(d, StatutPrise.reporte)),
                const SizedBox(width: 8),
                _actionBtn('❌ Oublié', AppColors.danger,
                    () => _confirmer(d, StatutPrise.oublie)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.45)),
          ),
          child: Text(label,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _traitementTile(TraitementModel t) {
    final details = [
      if (t.posologie.isNotEmpty) t.posologie,
      t.heures.isEmpty ? 'Si besoin' : t.heures.join(' · '),
    ].join('  •  ');
    final periode = t.dateFin == null
        ? 'Depuis le ${pcDate(t.dateDebut)} · au long cours'
        : 'Du ${pcDate(t.dateDebut)} au ${pcDate(t.dateFin!)}';

    return PcCard(
      color: t.actif ? _violet : AppColors.textSecondary,
      onTap: () => _ouvrirDetail(t),
      child: Row(
        children: [
          const Text('💊', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.nom,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(details,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11.5)),
                Text(periode,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
                if (t.medecin.isNotEmpty)
                  Text('Prescrit par ${t.medecin}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          if (t.actif && !t.rappels)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.notifications_off_outlined,
                  size: 16, color: AppColors.textSecondary),
            ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
