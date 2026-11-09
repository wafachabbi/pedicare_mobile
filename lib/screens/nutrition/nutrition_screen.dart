import 'package:flutter/material.dart';
import '../../data/nutrition_catalogue.dart';
import '../../models/acteur.dart';
import '../../models/enfant_model.dart';
import '../../models/nutrition_models.dart';
import '../../services/ia_nutrition_service.dart';
import '../../services/nutrition_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pc_ui.dart';
import '../journal/journal_alimentaire_screen.dart';
import 'allaitement_screen.dart';
import 'allergies_screen.dart';
import 'recettes_screen.dart';
import 'recommandations_screen.dart';

/// Module 9 — Nutrition & Alimentation : point d'entrée.
///
/// Pédiatre : allergies, consignes alimentaires et journal alimentaire.
/// Parent : allaitement ; le reste en lecture seule.
class NutritionScreen extends StatefulWidget {
  final EnfantModel enfant;
  final Acteur acteur;

  const NutritionScreen(
      {super.key, required this.enfant, this.acteur = const Acteur.parent()});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  static const _vert = Color(0xFF2ECC71);

  List<AllergieAlimentaireModel> _allergies = [];
  List<ConseilNutritionModel> _conseils = [];

  bool get _pediatre => widget.acteur.estPediatre;
  int get _ageMois => NutritionService.ageEnMois(widget.enfant.dateNaissance);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final a = await NutritionService.getAllergies(widget.enfant.id);
    final c = await NutritionService.getConseils(widget.enfant.id);
    if (!mounted) return;
    setState(() {
      _allergies = a;
      _conseils = c;
    });
  }

  Future<void> _ouvrir(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    _load();
  }

  String get _ageLabel {
    final m = _ageMois;
    if (m < 24) return '$m mois';
    return '${m ~/ 12} ans';
  }

  Future<void> _ajouterConseil() async {
    final controller = TextEditingController();
    final texte = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D2D5E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nouvelle consigne alimentaire',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Visible par le parent de ${widget.enfant.prenom}.',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 14),
            PcTextField(
              controller: controller,
              label: 'Ex. éviter les produits laitiers 15 jours',
              icon: Icons.edit_note_rounded,
              maxLines: 4,
            ),
            PcPrimaryButton(
              label: 'Publier',
              color: _vert,
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (texte == null || texte.isEmpty) return;
    final ok = await NutritionService.addConseil(ConseilNutritionModel(
      id: '',
      enfantId: widget.enfant.id,
      pediatreId: widget.acteur.id,
      auteur: widget.acteur.signature,
      texte: texte,
      date: DateTime.now(),
    ));
    if (!mounted) return;
    if (!ok) pcSnack(context, 'Publication impossible.', erreur: true);
    _load();
  }

  Future<void> _supprimerConseil(ConseilNutritionModel c) async {
    final ok = await pcConfirmer(context,
        titre: 'Supprimer la consigne', message: 'Supprimer cette consigne ?');
    if (!ok) return;
    await NutritionService.deleteConseil(c.id);
    _load();
  }

  /// Conseils personnalisés (IA Gemini ou règles locales).
  void _conseilsIA() {
    final future = IaNutritionService.conseils(widget.enfant);
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
        builder: (_, scroll) => FutureBuilder<ConseilsNutritionIA>(
          future: future,
          builder: (_, snap) {
            if (!snap.hasData) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.secondary));
            }
            final c = snap.data!;
            return ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              children: [
                Text('Conseils pour ${widget.enfant.prenom}',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                    c.parIA
                        ? '✨ Générés par IA (profil, allergies, repas, consignes)'
                        : '📚 Générés par PediCare (profil, allergies, repas, consignes)',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11.5)),
                const SizedBox(height: 14),
                for (final p in c.points)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  ', style: TextStyle(color: _vert)),
                        Expanded(
                          child: Text(p,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13.5,
                                  height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                const PcAvertissement(avertissementNutrition),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tranche = trancheDeAge(_ageMois);
    final enfant = widget.enfant;

    return PcPage(
      titre: 'Nutrition',
      sousTitre: '${enfant.prenom} · $_ageLabel'
          '${_pediatre ? ' · espace pédiatre' : ''}',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          PcCard(
            color: AppColors.accent,
            onTap: () => _ouvrir(RecommandationsScreen(enfant: enfant)),
            child: Row(
              children: [
                Text(tranche.emoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Repères ${tranche.titre}',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(tranche.conseils.first,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textSecondary),
              ],
            ),
          ),
          PcCard(
            color: const Color(0xFF4285F4),
            onTap: _conseilsIA,
            child: Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Conseils personnalisés pour ${enfant.prenom}',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600)),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textSecondary),
              ],
            ),
          ),
          if (_allergies.isNotEmpty)
            PcCard(
              color: AppColors.danger,
              onTap: () => _ouvrir(
                  AllergiesScreen(enfant: enfant, acteur: widget.acteur)),
              child: Text(
                '⚠️ Allergies : ${_allergies.map((a) => libelleAllergene(a.allergene)).join(', ')}',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600),
              ),
            ),

          // ── Consignes du pédiatre ──
          PcSectionTitle(
            'Consignes du pédiatre',
            trailing: _pediatre
                ? GestureDetector(
                    onTap: _ajouterConseil,
                    child: const Text('+ Ajouter',
                        style: TextStyle(
                            color: _vert,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  )
                : null,
          ),
          if (_conseils.isEmpty)
            PcCard(
              color: _vert,
              child: Text(
                _pediatre
                    ? 'Aucune consigne. Ajoutez des recommandations propres à cet enfant.'
                    : 'Aucune consigne particulière de votre pédiatre pour le moment.',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12.5),
              ),
            )
          else
            for (final c in _conseils)
              PcCard(
                color: _vert,
                padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🩺', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.texte,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  height: 1.35)),
                          const SizedBox(height: 4),
                          Text(
                              '${c.auteur.isEmpty ? 'Pédiatre' : c.auteur} · ${pcDate(c.date)}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                    if (_pediatre)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 19, color: AppColors.textSecondary),
                        onPressed: () => _supprimerConseil(c),
                      )
                    else
                      const SizedBox(width: 10),
                  ],
                ),
              ),

          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              _tuile(
                  '📒',
                  'Journal alimentaire',
                  _pediatre ? 'Saisie des repas' : 'Tenu par le pédiatre',
                  const Color(0xFF00C9A7),
                  () => _ouvrir(JournalAlimentaireScreen(
                      enfant: enfant, lectureSeule: !_pediatre))),
              _tuile('🚫', 'Allergies', '${_allergies.length} enregistrée(s)',
                  AppColors.danger,
                  () => _ouvrir(
                      AllergiesScreen(enfant: enfant, acteur: widget.acteur))),
              _tuile('🥗', 'Recommandations', 'Selon l\'âge',
                  const Color(0xFF4DAAFF),
                  () => _ouvrir(RecommandationsScreen(enfant: enfant))),
              _tuile('👩‍🍳', 'Recettes', 'Adaptées à l\'enfant',
                  const Color(0xFFE67E22),
                  () => _ouvrir(RecettesScreen(enfant: enfant))),
              _tuile(
                  '🍼',
                  'Allaitement',
                  _pediatre ? 'Saisi par le parent' : 'Tétées & biberons',
                  const Color(0xFFE91E63),
                  () => _ouvrir(AllaitementScreen(
                      enfant: enfant, lectureSeule: _pediatre))),
            ],
          ),
          const SizedBox(height: 14),
          const PcAvertissement(avertissementNutrition),
        ],
      ),
    );
  }

  Widget _tuile(String emoji, String titre, String sousTitre, Color color,
      VoidCallback onTap) {
    return PcCard(
      color: color,
      margin: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titre,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700)),
              Text(sousTitre,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
