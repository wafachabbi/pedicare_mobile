import 'package:flutter/material.dart';
import '../../models/enfant_model.dart';
import '../../models/journal_alimentaire_model.dart';
import '../../models/nutrition_models.dart';
import '../../services/journal_alimentaire_service.dart';
import '../../services/nutrition_service.dart';
import '../../services/open_food_facts_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pc_ui.dart';
import '../nutrition/recherche_produit_sheet.dart';

/// Ajout / modification d'un repas dans le journal alimentaire (Module 9).
/// Avant l'enregistrement, les aliments saisis sont vérifiés contre les
/// allergies de l'enfant et les aliments déconseillés à son âge.
class AddJournalAlimentaireScreen extends StatefulWidget {
  final EnfantModel enfant;
  final JournalAlimentaireModel? entree;

  const AddJournalAlimentaireScreen({
    super.key,
    required this.enfant,
    this.entree,
  });

  @override
  State<AddJournalAlimentaireScreen> createState() =>
      _AddJournalAlimentaireScreenState();
}

class _AddJournalAlimentaireScreenState
    extends State<AddJournalAlimentaireScreen> {
  static const _vert = Color(0xFF00C9A7);

  static const repasTypes = <(String, String)>[
    ('petit-déjeuner', '🥐 Petit-déjeuner'),
    ('déjeuner', '🍽️ Déjeuner'),
    ('goûter', '🍪 Goûter'),
    ('dîner', '🌙 Dîner'),
    ('collation', '🍎 Collation'),
    ('biberon', '🍼 Biberon / tétée'),
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _aliments;
  late final TextEditingController _quantite;
  late final TextEditingController _notes;
  late DateTime _date;
  String? _repas;
  Set<String> _allergenesConnus = {};
  bool _saving = false;

  bool get _edition => widget.entree != null;
  int get _ageMois =>
      NutritionService.ageEnMois(widget.enfant.dateNaissance, le: _date);

  @override
  void initState() {
    super.initState();
    final e = widget.entree;
    _aliments = TextEditingController(text: e?.aliments ?? '');
    _quantite = TextEditingController(text: e?.quantite ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _date = e?.date ?? DateTime.now();
    // Les anciennes entrées stockaient l'heure à part (texte libre « HH:mm »).
    final h = RegExp(r'^(\d{1,2})[:h](\d{2})$').firstMatch(e?.heure ?? '');
    if (h != null) {
      _date = DateTime(_date.year, _date.month, _date.day,
          int.parse(h.group(1)!), int.parse(h.group(2)!));
    }
    _repas = repasTypes.any((r) => r.$1 == e?.repas) ? e!.repas : null;
    _aliments.addListener(_rafraichir);
    _notes.addListener(_rafraichir);
    _chargerAllergies();
  }

  void _rafraichir() => setState(() {});

  /// Ajoute un produit Open Food Facts aux aliments ; ses allergènes sont
  /// écrits dans le texte, donc vérifiés par les alertes du journal.
  Future<void> _rechercherProduit() async {
    final produit = await showModalBottomSheet<ProduitAlimentaire>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D2D5E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => RechercheProduitSheet(allergenesEnfant: _allergenesConnus),
    );
    if (produit == null) return;
    final actuel = _aliments.text.trim();
    _aliments.text =
        actuel.isEmpty ? produit.libelleJournal : '$actuel, ${produit.libelleJournal}';
  }

  Future<void> _chargerAllergies() async {
    final a = await NutritionService.getAllergies(widget.enfant.id);
    if (!mounted) return;
    setState(() => _allergenesConnus = NutritionService.allergenesEnfant(a,
        allergiesProfil: widget.enfant.allergies));
  }

  @override
  void dispose() {
    _aliments.dispose();
    _quantite.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: widget.enfant.dateNaissance,
      lastDate: DateTime.now(),
      builder: pcPickerTheme,
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
      builder: pcPickerTheme,
    );
    setState(() => _date = DateTime(d.year, d.month, d.day,
        t?.hour ?? _date.hour, t?.minute ?? _date.minute));
  }

  List<AlerteAliment> _alertes() => NutritionService.verifierRepas(
        aliments: '${_aliments.text} ${_notes.text}',
        ageMois: _ageMois,
        allergenesConnus: _allergenesConnus,
        solide: _repas != 'biberon',
      );

  Future<void> _sauver() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_repas == null) {
      pcSnack(context, 'Choisissez le type de repas.', erreur: true);
      return;
    }

    final alertes = _alertes();
    if (alertes.isNotEmpty) {
      final continuer = await _confirmerAlertes(alertes);
      if (!continuer) return;
    }

    setState(() => _saving = true);
    final entree = JournalAlimentaireModel(
      id: widget.entree?.id ?? '',
      enfantId: widget.enfant.id,
      date: _date,
      repas: _repas,
      aliments: _aliments.text.trim(),
      quantite: _quantite.text.trim(),
      heure: pcHeure(_date),
      notes: _notes.text.trim(),
      ageMois: _ageMois,
    );
    final ok = _edition
        ? await JournalAlimentaireService.updateEntree(entree)
        : await JournalAlimentaireService.addEntree(entree) != null;
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context, true);
    } else {
      pcSnack(context, 'Erreur lors de l\'enregistrement.', erreur: true);
    }
  }

  Future<bool> _confirmerAlertes(List<AlerteAliment> alertes) async {
    final danger = alertes.any((a) => a.niveau == NiveauAlerteAliment.danger);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D2D5E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(danger ? '⛔ Attention' : '⚠️ À vérifier',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
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
                              color: a.niveau == NiveauAlerteAliment.danger
                                  ? AppColors.danger
                                  : const Color(0xFFE67E22),
                              fontWeight: FontWeight.w700)),
                      Text(a.message,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              const Text(
                'Repère indicatif : en cas de doute, demandez l\'avis du pédiatre.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Modifier le repas',
                  style: TextStyle(color: AppColors.secondary))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enregistrer quand même',
                  style: TextStyle(color: AppColors.textSecondary))),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final alertes = _alertes();
    return PcPage(
      titre: _edition ? 'Modifier le repas' : 'Nouveau repas',
      sousTitre: widget.enfant.nomComplet,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            PcCard(
              color: _vert,
              onTap: _choisirDate,
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: _vert, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('${pcJourRelatif(_date)} à ${pcHeure(_date)}',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700)),
                  ),
                  const Text('Changer',
                      style: TextStyle(color: _vert, fontSize: 12)),
                ],
              ),
            ),
            const PcSectionTitle('Type de repas'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in repasTypes)
                  PcChip(
                    label: r.$2,
                    color: _vert,
                    selected: _repas == r.$1,
                    onTap: () => setState(() => _repas = r.$1),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            PcTextField(
              controller: _aliments,
              label: 'Aliments (ex. purée de carottes, yaourt)',
              icon: Icons.restaurant_outlined,
              maxLines: 2,
              validator: (v) => (_repas != 'biberon' &&
                      (v == null || v.trim().isEmpty))
                  ? 'Indiquez ce que l\'enfant a mangé'
                  : null,
            ),
            PcCard(
              color: const Color(0xFFE67E22),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              onTap: _rechercherProduit,
              child: const Row(
                children: [
                  Icon(Icons.qr_code_scanner_rounded,
                      color: Color(0xFFE67E22), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                        'Ajouter un produit (Open Food Facts) : nom ou code-barres',
                        style: TextStyle(
                            color: AppColors.textPrimary, fontSize: 12.5)),
                  ),
                  Icon(Icons.search_rounded, color: AppColors.textSecondary),
                ],
              ),
            ),
            PcTextField(
              controller: _quantite,
              label: 'Quantité (ex. 150 g, 180 ml, la moitié)',
              icon: Icons.scale_outlined,
            ),
            PcTextField(
              controller: _notes,
              label: 'Notes (appétit, réaction…)',
              icon: Icons.notes_outlined,
              maxLines: 2,
            ),
            // Aperçu en direct des alertes.
            if (alertes.isNotEmpty)
              PcCard(
                color: AppColors.danger,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final a in alertes)
                      Text('${a.titre} — ${a.message}',
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 12)),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            PcPrimaryButton(
              label: _saving
                  ? 'Enregistrement…'
                  : (_edition ? 'Mettre à jour' : 'Enregistrer'),
              color: _vert,
              onPressed: _saving ? null : _sauver,
            ),
          ],
        ),
      ),
    );
  }
}
