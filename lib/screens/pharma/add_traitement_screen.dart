import 'package:flutter/material.dart';
import '../../models/acteur.dart';
import '../../models/enfant_model.dart';
import '../../models/traitement_model.dart';
import '../../services/ia_pharma_service.dart';
import '../../services/traitement_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pc_ui.dart';
import 'scan_ordonnance_screen.dart';

/// Prescription / modification d'un traitement (Module 5 — PediPharma).
/// Réservé au pédiatre : son nom est prérempli comme prescripteur.
class AddTraitementScreen extends StatefulWidget {
  final EnfantModel enfant;
  final TraitementModel? traitement;
  final Acteur acteur;

  const AddTraitementScreen({
    super.key,
    required this.enfant,
    this.traitement,
    this.acteur = const Acteur.parent(),
  });

  @override
  State<AddTraitementScreen> createState() => _AddTraitementScreenState();
}

class _AddTraitementScreenState extends State<AddTraitementScreen> {
  static const _violet = Color(0xFF9B59B6);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nom;
  late final TextEditingController _posologie;
  late final TextEditingController _medecin;
  late final TextEditingController _notes;

  late DateTime _dateDebut;
  DateTime? _dateFin;
  late bool _enCours;
  late bool _rappels;
  late List<String> _heures;
  bool _saving = false;

  bool get _edition => widget.traitement != null;

  @override
  void initState() {
    super.initState();
    final t = widget.traitement;
    _nom = TextEditingController(text: t?.nom ?? '');
    _posologie = TextEditingController(text: t?.posologie ?? '');
    _medecin = TextEditingController(
        text: t?.medecin ?? (widget.acteur.estPediatre ? widget.acteur.signature : ''));
    _notes = TextEditingController(text: t?.notes ?? '');
    _dateDebut = t?.dateDebut ?? DateTime.now();
    _dateFin = t?.dateFin;
    _enCours = t != null && t.dateFin == null;
    _dateFin ??= _enCours ? null : DateTime.now().add(const Duration(days: 6));
    _rappels = t?.rappels ?? true;
    _heures = [...?t?.heures];
    if (t == null) _heures = [...TraitementModel.heuresParDefaut(2)];
  }

  @override
  void dispose() {
    _nom.dispose();
    _posologie.dispose();
    _medecin.dispose();
    _notes.dispose();
    super.dispose();
  }

  String get _frequenceLabel {
    final n = _heures.length;
    if (n == 0) return 'Si besoin';
    return '$n fois par jour';
  }

  Future<void> _choisirDate({required bool debut}) async {
    final initiale = debut ? _dateDebut : (_dateFin ?? _dateDebut);
    final d = await showDatePicker(
      context: context,
      initialDate: initiale,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: pcPickerTheme,
    );
    if (d == null) return;
    setState(() {
      if (debut) {
        _dateDebut = d;
        if (_dateFin != null && _dateFin!.isBefore(d)) _dateFin = d;
      } else {
        _dateFin = d;
      }
    });
  }

  Future<void> _ajouterHeure({int? index}) async {
    final init = index != null
        ? TimeOfDay(
            hour: int.parse(_heures[index].split(':')[0]),
            minute: int.parse(_heures[index].split(':')[1]))
        : const TimeOfDay(hour: 12, minute: 0);
    final t = await showTimePicker(
        context: context, initialTime: init, builder: pcPickerTheme);
    if (t == null) return;
    final h =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (index != null) _heures.removeAt(index);
      _heures = TraitementModel.trierHeures([..._heures, h]).toList();
    });
  }

  /// Préremplit le formulaire à partir d'une ordonnance scannée (Tesseract).
  Future<void> _scannerOrdonnance() async {
    final res = await Navigator.push<ResultatScan>(
      context,
      MaterialPageRoute(builder: (_) => const ScanOrdonnanceScreen()),
    );
    if (res == null || !mounted) return;
    final l = res.ligne;
    setState(() {
      _nom.text = l.nom;
      if (l.posologie.isNotEmpty) _posologie.text = l.posologie;
      if (l.prisesParJour >= 1 && l.prisesParJour <= 4) {
        _heures = [...TraitementModel.heuresParDefaut(l.prisesParJour)];
      }
      if (l.dureeJours != null && l.dureeJours! > 0) {
        _enCours = false;
        _dateFin = _dateDebut.add(Duration(days: l.dureeJours! - 1));
      }
      if (res.medecin.isNotEmpty && _medecin.text.trim().isEmpty) {
        _medecin.text = res.medecin;
      }
    });
    pcSnack(context, 'Formulaire prérempli : vérifiez chaque champ.');
  }

  /// Avertit des interactions avec les autres traitements en cours.
  Future<bool> _verifierInteractions() async {
    final actifs = (await TraitementService.getActifs(widget.enfant.id))
        .where((t) => t.id != widget.traitement?.id)
        .toList();
    final alertes = IaPharmaService.interactions(_nom.text, actifs);
    if (alertes.isEmpty || !mounted) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D2D5E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('⚠️ Interactions possibles',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final a in alertes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.titre,
                          style: TextStyle(
                              color: a.danger
                                  ? AppColors.danger
                                  : const Color(0xFFE67E22),
                              fontWeight: FontWeight.w700)),
                      Text(a.message,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Revoir',
                  style: TextStyle(color: AppColors.secondary))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Prescrire quand même',
                  style: TextStyle(color: AppColors.textSecondary))),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _enregistrer() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_heures.length > 8) {
      pcSnack(context, 'Maximum 8 prises par jour.', erreur: true);
      return;
    }
    if (!await _verifierInteractions()) return;
    if (!mounted) return;
    setState(() => _saving = true);
    final t = TraitementModel(
      id: widget.traitement?.id ?? '',
      enfantId: widget.enfant.id,
      nom: _nom.text.trim(),
      posologie: _posologie.text.trim(),
      frequence: _frequenceLabel,
      dateDebut: _dateDebut,
      dateFin: _enCours ? null : _dateFin,
      notes: _notes.text.trim(),
      medecin: _medecin.text.trim(),
      heures: _heures,
      rappels: _rappels,
    );
    final ok = _edition
        ? await TraitementService.updateTraitement(t,
            enfantPrenom: widget.enfant.prenom)
        : await TraitementService.addTraitement(t,
                enfantPrenom: widget.enfant.prenom) !=
            null;
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context, true);
    } else {
      pcSnack(context, 'Enregistrement du traitement impossible.', erreur: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PcPage(
      titre: _edition ? 'Modifier la prescription' : 'Nouvelle prescription',
      sousTitre: widget.enfant.nomComplet,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            if (!_edition)
              PcCard(
                color: _violet,
                onTap: _scannerOrdonnance,
                child: const Row(
                  children: [
                    Icon(Icons.document_scanner_outlined, color: _violet),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('Scanner une ordonnance papier (OCR)',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600)),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: AppColors.textSecondary),
                  ],
                ),
              ),
            PcTextField(
              controller: _nom,
              label: 'Médicament *',
              icon: Icons.medication_outlined,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Indiquez le nom du médicament'
                  : null,
            ),
            PcTextField(
              controller: _posologie,
              label: 'Posologie (ex. 5 ml, 1 sachet)',
              icon: Icons.science_outlined,
            ),
            PcTextField(
              controller: _medecin,
              label: 'Médecin prescripteur',
              icon: Icons.person_outline,
            ),

            // ── Prises par jour ──
            PcSectionTitle('Prises par jour',
                trailing: Text(_frequenceLabel,
                    style: const TextStyle(
                        color: _violet,
                        fontSize: 12,
                        fontWeight: FontWeight.w700))),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final n in [1, 2, 3, 4])
                  PcChip(
                    label: '$n×/jour',
                    color: _violet,
                    selected: _heures.length == n &&
                        _heures.join() ==
                            TraitementModel.heuresParDefaut(n).join(),
                    onTap: () => setState(() =>
                        _heures = [...TraitementModel.heuresParDefaut(n)]),
                  ),
                PcChip(
                  label: 'Si besoin',
                  color: _violet,
                  selected: _heures.isEmpty,
                  onTap: () => setState(() => _heures = []),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _heures.length; i++)
                  InputChip(
                    label: Text(_heures[i]),
                    labelStyle: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700),
                    backgroundColor: _violet.withValues(alpha: 0.2),
                    side: BorderSide(color: _violet.withValues(alpha: 0.5)),
                    deleteIconColor: AppColors.textSecondary,
                    onPressed: () => _ajouterHeure(index: i),
                    onDeleted: () => setState(() => _heures.removeAt(i)),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16, color: _violet),
                  label: const Text('Heure'),
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  backgroundColor: AppColors.inputFill,
                  side: const BorderSide(color: AppColors.glassBorder),
                  onPressed: _ajouterHeure,
                ),
              ],
            ),
            if (_heures.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                    'Sans heure fixe : pas de rappel automatique ni de suivi des prises.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 11.5)),
              ),

            // ── Durée ──
            const PcSectionTitle('Durée du traitement'),
            Row(
              children: [
                Expanded(
                  child: _dateTile('Début', pcDate(_dateDebut),
                      () => _choisirDate(debut: true)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Opacity(
                    opacity: _enCours ? 0.4 : 1,
                    child: _dateTile(
                        'Fin',
                        _dateFin == null ? '—' : pcDate(_dateFin!),
                        _enCours ? null : () => _choisirDate(debut: false)),
                  ),
                ),
              ],
            ),
            _switch(
              'Traitement au long cours (sans date de fin)',
              _enCours,
              (v) => setState(() {
                _enCours = v;
                if (!v && _dateFin == null) {
                  _dateFin = _dateDebut.add(const Duration(days: 6));
                }
              }),
            ),
            _switch('Rappels de prise (notifications)', _rappels,
                (v) => setState(() => _rappels = v)),
            const SizedBox(height: 8),
            PcTextField(
              controller: _notes,
              label: 'Notes (pendant le repas, à conserver au frais…)',
              icon: Icons.notes_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            PcPrimaryButton(
              label: _saving
                  ? 'Enregistrement…'
                  : (_edition ? 'Mettre à jour' : 'Prescrire'),
              color: _violet,
              onPressed: _saving ? null : _enregistrer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateTile(String label, String valeur, VoidCallback? onTap) {
    return PcCard(
      color: _violet,
      margin: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 14, color: _violet),
              const SizedBox(width: 6),
              Text(valeur,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _switch(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13)),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: _violet,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
