import 'package:flutter/material.dart';
import '../../data/nutrition_catalogue.dart';
import '../../models/acteur.dart';
import '../../models/enfant_model.dart';
import '../../models/nutrition_models.dart';
import '../../services/nutrition_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pc_ui.dart';

/// Allergies alimentaires de l'enfant (Module 9).
/// Déclarées par le pédiatre (allergies diagnostiquées) ; le parent consulte.
class AllergiesScreen extends StatefulWidget {
  final EnfantModel enfant;
  final Acteur acteur;
  const AllergiesScreen(
      {super.key, required this.enfant, this.acteur = const Acteur.parent()});

  @override
  State<AllergiesScreen> createState() => _AllergiesScreenState();
}

class _AllergiesScreenState extends State<AllergiesScreen> {
  List<AllergieAlimentaireModel> _allergies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final a = await NutritionService.getAllergies(widget.enfant.id);
    if (!mounted) return;
    setState(() {
      _allergies = a;
      _loading = false;
    });
  }

  Future<void> _supprimer(AllergieAlimentaireModel a) async {
    final ok = await pcConfirmer(context,
        titre: 'Supprimer l\'allergie',
        message: 'Retirer « ${libelleAllergene(a.allergene)} » de la liste ?');
    if (!ok) return;
    await NutritionService.deleteAllergie(a.id);
    _load();
  }

  Future<void> _ajouter() async {
    final dejaPresents = _allergies.map((a) => a.allergene).toSet();
    final nouvelle = await showModalBottomSheet<AllergieAlimentaireModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D2D5E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AjoutAllergieSheet(
          enfantId: widget.enfant.id, dejaPresents: dejaPresents),
    );
    if (nouvelle == null) return;
    final ok = await NutritionService.addAllergie(nouvelle);
    if (!mounted) return;
    if (!ok) pcSnack(context, 'Enregistrement impossible.', erreur: true);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final profil = widget.enfant.allergies?.trim() ?? '';
    return PcPage(
      titre: 'Allergies alimentaires',
      sousTitre: widget.enfant.nomComplet,
      fab: !widget.acteur.estPediatre
          ? null
          : FloatingActionButton(
        onPressed: _ajouter,
        backgroundColor: AppColors.danger,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                if (profil.isNotEmpty)
                  PcCard(
                    color: AppColors.textSecondary,
                    child: Text('Noté sur le profil de l\'enfant : $profil',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ),
                if (_allergies.isEmpty)
                  PcEmpty(
                    emoji: '✅',
                    titre: 'Aucune allergie alimentaire',
                    sousTitre: widget.acteur.estPediatre
                        ? 'Déclarez les allergies diagnostiquées : le journal '
                            'alimentaire alertera et les recettes seront filtrées.'
                        : 'Les allergies sont déclarées par le pédiatre après diagnostic.',
                  )
                else
                  ..._allergies.map(_tile),
                const SizedBox(height: 8),
                const PcAvertissement(
                  'En cas de réaction grave (gonflement du visage, difficulté '
                  'à respirer), appelez immédiatement le SAMU (190 en Tunisie, '
                  '15 en France).',
                ),
              ],
            ),
    );
  }

  Widget _tile(AllergieAlimentaireModel a) {
    final cat = allergeneParId(a.allergene);
    final color = switch (a.severite) {
      SeveriteAllergie.legere => const Color(0xFFE67E22),
      SeveriteAllergie.moderee => const Color(0xFFFF8A65),
      SeveriteAllergie.severe => AppColors.danger,
    };
    return PcCard(
      color: color,
      child: Row(
        children: [
          Text(cat?.emoji ?? '⚠️', style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(libelleAllergene(a.allergene),
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700)),
                Text('Sévérité : ${a.severite.label}',
                    style: TextStyle(color: color, fontSize: 12)),
                if (a.reaction.isNotEmpty)
                  Text(a.reaction,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11.5)),
              ],
            ),
          ),
          if (widget.acteur.estPediatre)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.textSecondary),
              onPressed: () => _supprimer(a),
            ),
        ],
      ),
    );
  }
}

class _AjoutAllergieSheet extends StatefulWidget {
  final String enfantId;
  final Set<String> dejaPresents;

  const _AjoutAllergieSheet(
      {required this.enfantId, required this.dejaPresents});

  @override
  State<_AjoutAllergieSheet> createState() => _AjoutAllergieSheetState();
}

class _AjoutAllergieSheetState extends State<_AjoutAllergieSheet> {
  String? _selection;
  final _autre = TextEditingController();
  final _reaction = TextEditingController();
  SeveriteAllergie _severite = SeveriteAllergie.moderee;

  @override
  void dispose() {
    _autre.dispose();
    _reaction.dispose();
    super.dispose();
  }

  String get _allergene =>
      _selection == 'autre' ? _autre.text.trim() : (_selection ?? '');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nouvelle allergie',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in allergenesCatalogue)
                  if (!widget.dejaPresents.contains(a.id))
                    PcChip(
                      label: '${a.emoji} ${a.label}',
                      color: AppColors.danger,
                      selected: _selection == a.id,
                      onTap: () => setState(() => _selection = a.id),
                    ),
                PcChip(
                  label: '✏️ Autre',
                  color: AppColors.danger,
                  selected: _selection == 'autre',
                  onTap: () => setState(() => _selection = 'autre'),
                ),
              ],
            ),
            if (_selection == 'autre') ...[
              const SizedBox(height: 12),
              PcTextField(
                  controller: _autre,
                  label: 'Aliment (ex. fraise, moutarde)',
                  icon: Icons.edit_outlined),
            ],
            const SizedBox(height: 14),
            const Text('Sévérité',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final s in SeveriteAllergie.values)
                  PcChip(
                    label: s.label,
                    color: AppColors.danger,
                    selected: _severite == s,
                    onTap: () => setState(() => _severite = s),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            PcTextField(
                controller: _reaction,
                label: 'Réaction observée (facultatif)',
                icon: Icons.notes_outlined),
            const SizedBox(height: 4),
            PcPrimaryButton(
              label: 'Ajouter',
              color: AppColors.danger,
              onPressed: () {
                if (_allergene.isEmpty) return;
                Navigator.pop(
                  context,
                  AllergieAlimentaireModel(
                    id: '',
                    enfantId: widget.enfantId,
                    allergene: _allergene,
                    severite: _severite,
                    reaction: _reaction.text.trim(),
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
