import 'package:flutter/material.dart';
import '../../data/nutrition_catalogue.dart';
import '../../models/enfant_model.dart';
import '../../services/nutrition_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pc_ui.dart';

/// Recettes adaptées à l'âge et aux allergies de l'enfant (Module 9).
class RecettesScreen extends StatefulWidget {
  final EnfantModel enfant;
  const RecettesScreen({super.key, required this.enfant});

  @override
  State<RecettesScreen> createState() => _RecettesScreenState();
}

class _RecettesScreenState extends State<RecettesScreen> {
  static const _orange = Color(0xFFE67E22);

  List<Recette> _recettes = [];
  int _masquees = 0;
  Set<String> _allergenes = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final allergies = await NutritionService.getAllergies(widget.enfant.id);
    final ids = NutritionService.allergenesEnfant(allergies,
        allergiesProfil: widget.enfant.allergies);
    final (recettes, masquees) = NutritionService.recettesAdaptees(
      ageMois: NutritionService.ageEnMois(widget.enfant.dateNaissance),
      allergenesConnus: ids,
    );
    if (!mounted) return;
    setState(() {
      _allergenes = ids;
      _recettes = recettes;
      _masquees = masquees;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PcPage(
      titre: 'Recettes',
      sousTitre: 'Adaptées à ${widget.enfant.prenom}',
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                if (_allergenes.isNotEmpty || _masquees > 0)
                  PcCard(
                    color: AppColors.danger,
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Sans : ${_allergenes.map(libelleAllergene).join(', ')}'
                      '${_masquees > 0 ? '\n$_masquees recette(s) masquée(s) car elles contiennent un allergène.' : ''}',
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 12),
                    ),
                  ),
                if (_recettes.isEmpty)
                  const PcEmpty(
                    emoji: '🍼',
                    titre: 'Pas encore de recette',
                    sousTitre:
                        'Avant 4 mois, l\'alimentation est uniquement lactée.',
                  )
                else
                  ..._recettes.map(_recette),
                const SizedBox(height: 6),
                const PcAvertissement(avertissementNutrition),
              ],
            ),
    );
  }

  Widget _recette(Recette r) {
    return PcCard(
      color: _orange,
      padding: EdgeInsets.zero,
      child: Theme(
        data: ThemeData.dark().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.textSecondary,
          collapsedIconColor: AppColors.textSecondary,
          leading: Text(r.emoji, style: const TextStyle(fontSize: 26)),
          title: Text(r.titre,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          subtitle: Text(
            'Dès ${r.ageMinMois < 24 ? '${r.ageMinMois} mois' : '${r.ageMinMois ~/ 12} ans'}'
            ' · ${r.dureeMinutes} min'
            '${r.allergenes.isEmpty ? '' : ' · contient : ${r.allergenes.map(libelleAllergene).join(', ')}'}',
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ingrédients',
                style: TextStyle(
                    color: _orange, fontWeight: FontWeight.w700, fontSize: 12.5)),
            const SizedBox(height: 4),
            for (final i in r.ingredients)
              Text('•  $i',
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 12.5)),
            const SizedBox(height: 10),
            const Text('Préparation',
                style: TextStyle(
                    color: _orange, fontWeight: FontWeight.w700, fontSize: 12.5)),
            const SizedBox(height: 4),
            for (var i = 0; i < r.etapes.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('${i + 1}. ${r.etapes[i]}',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12.5,
                        height: 1.35)),
              ),
          ],
        ),
      ),
    );
  }
}
