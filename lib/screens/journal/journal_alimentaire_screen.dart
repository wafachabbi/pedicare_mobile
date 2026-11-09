import 'package:flutter/material.dart';
import '../../models/enfant_model.dart';
import '../../models/journal_alimentaire_model.dart';
import '../../models/nutrition_models.dart';
import '../../services/journal_alimentaire_service.dart';
import '../../services/nutrition_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pc_ui.dart';
import 'add_journal_alimentaire_screen.dart';

/// Journal alimentaire quotidien (Module 9) : historique groupé par jour,
/// filtres, modification et suppression. [lectureSeule] masque les actions.
class JournalAlimentaireScreen extends StatefulWidget {
  final EnfantModel enfant;
  final bool lectureSeule;

  const JournalAlimentaireScreen({
    super.key,
    required this.enfant,
    this.lectureSeule = false,
  });

  @override
  State<JournalAlimentaireScreen> createState() =>
      _JournalAlimentaireScreenState();
}

class _JournalAlimentaireScreenState extends State<JournalAlimentaireScreen> {
  static const _vert = Color(0xFF00C9A7);

  List<JournalAlimentaireModel> _entrees = [];
  Set<String> _allergenesConnus = {};
  bool _loading = true;

  /// 7, 30 ou 0 (= tout).
  int _filtreJours = 7;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entrees = _filtreJours == 0
        ? await JournalAlimentaireService.getEntrees(widget.enfant.id)
        : await JournalAlimentaireService.getEntreesPeriode(
            widget.enfant.id,
            DateTime.now().subtract(Duration(days: _filtreJours - 1)),
            DateTime.now(),
          );
    final allergies = await NutritionService.getAllergies(widget.enfant.id);
    if (!mounted) return;
    setState(() {
      _entrees = entrees;
      _allergenesConnus = NutritionService.allergenesEnfant(allergies,
          allergiesProfil: widget.enfant.allergies);
      _loading = false;
    });
  }

  void _changerFiltre(int jours) {
    setState(() => _filtreJours = jours);
    _load();
  }

  Future<void> _ouvrirFormulaire([JournalAlimentaireModel? entree]) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddJournalAlimentaireScreen(enfant: widget.enfant, entree: entree),
      ),
    );
    if (ok == true) _load();
  }

  Future<void> _supprimer(JournalAlimentaireModel e) async {
    final ok = await pcConfirmer(context,
        titre: 'Supprimer le repas', message: 'Supprimer cette entrée du journal ?');
    if (!ok) return;
    await JournalAlimentaireService.deleteEntree(e.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final parJour = <String, List<JournalAlimentaireModel>>{};
    for (final e in _entrees) {
      parJour.putIfAbsent(pcJourRelatif(e.date), () => []).add(e);
    }
    final joursRenseignes = parJour.length;

    return PcPage(
      titre: 'Journal alimentaire',
      sousTitre: widget.enfant.nomComplet,
      fab: widget.lectureSeule
          ? null
          : FloatingActionButton(
              onPressed: _ouvrirFormulaire,
              backgroundColor: _vert,
              child: const Icon(Icons.add, color: Colors.white),
            ),
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                Row(
                  children: [
                    for (final f in const [(7, '7 jours'), (30, '30 jours'), (0, 'Tout')]) ...[
                      PcChip(
                        label: f.$2,
                        color: _vert,
                        selected: _filtreJours == f.$1,
                        onTap: () => _changerFiltre(f.$1),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                if (_entrees.isNotEmpty)
                  PcCard(
                    color: _vert,
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '🍽️ ${_entrees.length} repas sur $joursRenseignes jour(s) '
                      '${_filtreJours == 0 ? 'au total' : 'sur les $_filtreJours derniers jours'}',
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 12.5),
                    ),
                  ),
                if (_entrees.isEmpty)
                  PcEmpty(
                    emoji: '🍽️',
                    titre: 'Aucun repas enregistré',
                    sousTitre: widget.lectureSeule
                        ? 'Le journal alimentaire est tenu par le pédiatre.'
                        : 'Ajoutez les repas pour suivre l\'alimentation de l\'enfant.',
                  )
                else
                  for (final jour in parJour.entries) ...[
                    PcSectionTitle('${jour.key} (${jour.value.length})'),
                    ...jour.value.map(_carte),
                  ],
              ],
            ),
    );
  }

  static String _emojiRepas(String? repas) => switch (repas) {
        'petit-déjeuner' => '🥐',
        'déjeuner' => '🍽️',
        'goûter' => '🍪',
        'dîner' => '🌙',
        'collation' => '🍎',
        'biberon' => '🍼',
        _ => '🍴',
      };

  Widget _carte(JournalAlimentaireModel e) {
    final ageMois = e.ageMois ??
        NutritionService.ageEnMois(widget.enfant.dateNaissance, le: e.date);
    final alertes = NutritionService.verifierRepas(
      aliments: '${e.aliments ?? ''} ${e.notes ?? ''}',
      ageMois: ageMois,
      allergenesConnus: _allergenesConnus,
      solide: e.repas != 'biberon',
    );
    final danger =
        alertes.any((a) => a.niveau == NiveauAlerteAliment.danger);
    final color = alertes.isEmpty
        ? _vert
        : (danger ? AppColors.danger : const Color(0xFFE67E22));
    final repas = e.repas == null || e.repas!.isEmpty
        ? 'Repas'
        : '${e.repas![0].toUpperCase()}${e.repas!.substring(1)}';

    return PcCard(
      color: color,
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      onTap: widget.lectureSeule ? null : () => _ouvrirFormulaire(e),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_emojiRepas(e.repas), style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$repas · ${pcHeure(e.date)}',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700)),
                if ((e.aliments ?? '').isNotEmpty)
                  Text(e.aliments!,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 12.5)),
                if ((e.quantite ?? '').isNotEmpty)
                  Text('Quantité : ${e.quantite}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11.5)),
                if ((e.notes ?? '').isNotEmpty)
                  Text(e.notes!,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11.5)),
                for (final a in alertes)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(a.titre,
                        style: TextStyle(
                            color: color,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
          if (!widget.lectureSeule)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 19, color: AppColors.textSecondary),
              onPressed: () => _supprimer(e),
            ),
        ],
      ),
    );
  }
}
