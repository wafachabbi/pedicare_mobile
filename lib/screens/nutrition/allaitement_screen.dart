import 'package:flutter/material.dart';
import '../../models/enfant_model.dart';
import '../../models/nutrition_models.dart';
import '../../services/nutrition_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pc_ui.dart';

/// Suivi de l'allaitement : tétées et biberons (fréquence, durée, quantité).
/// Saisi par le parent ; [lectureSeule] pour le pédiatre.
class AllaitementScreen extends StatefulWidget {
  final EnfantModel enfant;
  final bool lectureSeule;
  const AllaitementScreen(
      {super.key, required this.enfant, this.lectureSeule = false});

  @override
  State<AllaitementScreen> createState() => _AllaitementScreenState();
}

class _AllaitementScreenState extends State<AllaitementScreen> {
  static const _rose = Color(0xFFE91E63);

  List<AllaitementModel> _entrees = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final e = await NutritionService.getAllaitements(widget.enfant.id);
    if (!mounted) return;
    setState(() {
      _entrees = e;
      _loading = false;
    });
  }

  List<AllaitementModel> get _aujourdhui {
    final now = DateTime.now();
    return _entrees
        .where((e) =>
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day)
        .toList();
  }

  Future<void> _editer([AllaitementModel? existant]) async {
    final res = await showModalBottomSheet<AllaitementModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D2D5E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) =>
          _AllaitementSheet(enfantId: widget.enfant.id, existant: existant),
    );
    if (res == null) return;
    final ok = await NutritionService.saveAllaitement(res);
    if (!mounted) return;
    if (!ok) pcSnack(context, 'Enregistrement impossible.', erreur: true);
    _load();
  }

  Future<void> _supprimer(AllaitementModel e) async {
    final ok = await pcConfirmer(context,
        titre: 'Supprimer', message: 'Supprimer cette entrée ?');
    if (!ok) return;
    await NutritionService.deleteAllaitement(e.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final stats = AllaitementStats.depuis(_aujourdhui);
    final ageMois = NutritionService.ageEnMois(widget.enfant.dateNaissance);

    // Groupement par jour (7 derniers jours).
    final parJour = <String, List<AllaitementModel>>{};
    for (final e in _entrees) {
      parJour.putIfAbsent(pcJourRelatif(e.date), () => []).add(e);
    }

    return PcPage(
      titre: 'Allaitement',
      sousTitre: '${widget.enfant.prenom} · 7 derniers jours',
      fab: widget.lectureSeule
          ? null
          : FloatingActionButton.extended(
        onPressed: _editer,
        backgroundColor: _rose,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tétée / biberon',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                if (ageMois >= 24)
                  const PcAvertissement(
                    'Ce suivi est surtout utile pour les nourrissons.',
                  ),
                const PcSectionTitle('Aujourd\'hui'),
                Row(
                  children: [
                    _kpi('${stats.nombre}', 'Tétées / biberons'),
                    const SizedBox(width: 8),
                    _kpi(
                        stats.intervalleMoyen == null
                            ? '—'
                            : _duree(stats.intervalleMoyen!.inMinutes),
                        'Intervalle moyen'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _kpi(stats.dureeTotaleMinutes == 0
                            ? '—'
                            : _duree(stats.dureeTotaleMinutes),
                        'Durée au sein'),
                    const SizedBox(width: 8),
                    _kpi(stats.quantiteTotaleMl == 0
                            ? '—'
                            : '${stats.quantiteTotaleMl} ml',
                        'Quantité biberon'),
                  ],
                ),
                if (stats.derniere != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                        'Dernière à ${pcHeure(stats.derniere!)} '
                        '(il y a ${_duree(DateTime.now().difference(stats.derniere!).inMinutes)})',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ),
                const SizedBox(height: 8),
                if (_entrees.isEmpty)
                  const PcEmpty(
                    emoji: '🍼',
                    titre: 'Aucune entrée',
                    sousTitre: 'Notez chaque tétée ou biberon pour suivre le rythme.',
                  )
                else
                  for (final jour in parJour.entries) ...[
                    PcSectionTitle('${jour.key} (${jour.value.length})'),
                    ...jour.value.map(_tile),
                  ],
              ],
            ),
    );
  }

  static String _duree(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h${m.toString().padLeft(2, '0')}';
  }

  Widget _kpi(String valeur, String label) {
    return Expanded(
      child: PcCard(
        color: _rose,
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(valeur,
                style: const TextStyle(
                    color: _rose, fontSize: 18, fontWeight: FontWeight.w800)),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _tile(AllaitementModel e) {
    final detail = [
      e.type.label,
      if (e.dureeMinutes != null) '${e.dureeMinutes} min',
      if (e.quantiteMl != null) '${e.quantiteMl} ml',
    ].join(' · ');
    return PcCard(
      color: _rose,
      padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
      margin: const EdgeInsets.only(bottom: 6),
      onTap: widget.lectureSeule ? null : () => _editer(e),
      child: Row(
        children: [
          Text(e.type.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Text(pcHeure(e.date),
              style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detail,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 12.5)),
                if (e.notes.isNotEmpty)
                  Text(e.notes,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          if (!widget.lectureSeule)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 19, color: AppColors.textSecondary),
              onPressed: () => _supprimer(e),
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _AllaitementSheet extends StatefulWidget {
  final String enfantId;
  final AllaitementModel? existant;

  const _AllaitementSheet({required this.enfantId, this.existant});

  @override
  State<_AllaitementSheet> createState() => _AllaitementSheetState();
}

class _AllaitementSheetState extends State<_AllaitementSheet> {
  static const _rose = Color(0xFFE91E63);

  late TypeAllaitement _type;
  late DateTime _date;
  late final TextEditingController _duree;
  late final TextEditingController _quantite;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    final e = widget.existant;
    _type = e?.type ?? TypeAllaitement.seinGauche;
    _date = e?.date ?? DateTime.now();
    _duree = TextEditingController(text: e?.dureeMinutes?.toString() ?? '');
    _quantite = TextEditingController(text: e?.quantiteMl?.toString() ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
  }

  @override
  void dispose() {
    _duree.dispose();
    _quantite.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _choisirHeure() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
      builder: pcPickerTheme,
    );
    if (t == null) return;
    setState(() => _date =
        DateTime(_date.year, _date.month, _date.day, t.hour, t.minute));
  }

  @override
  Widget build(BuildContext context) {
    final biberon = _type == TypeAllaitement.biberon;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.existant == null ? 'Nouvelle entrée' : 'Modifier',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: [
                for (final t in TypeAllaitement.values)
                  PcChip(
                    label: '${t.emoji} ${t.label}',
                    color: _rose,
                    selected: _type == t,
                    onTap: () => setState(() => _type = t),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            PcCard(
              color: _rose,
              onTap: _choisirHeure,
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: _rose, size: 18),
                  const SizedBox(width: 8),
                  Text('${pcJourRelatif(_date)} à ${pcHeure(_date)}',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            PcTextField(
              controller: biberon ? _quantite : _duree,
              label: biberon ? 'Quantité (ml)' : 'Durée (minutes)',
              icon: biberon ? Icons.local_drink_outlined : Icons.timer_outlined,
              keyboardType: TextInputType.number,
            ),
            PcTextField(
                controller: _notes,
                label: 'Notes (facultatif)',
                icon: Icons.notes_outlined),
            PcPrimaryButton(
              label: 'Enregistrer',
              color: _rose,
              onPressed: () {
                Navigator.pop(
                  context,
                  AllaitementModel(
                    id: widget.existant?.id ?? '',
                    enfantId: widget.enfantId,
                    date: _date,
                    type: _type,
                    dureeMinutes: biberon ? null : int.tryParse(_duree.text.trim()),
                    quantiteMl: biberon ? int.tryParse(_quantite.text.trim()) : null,
                    notes: _notes.text.trim(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
