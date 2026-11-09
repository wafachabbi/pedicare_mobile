import 'package:flutter/material.dart';
import '../../models/activite_model.dart';
import '../../models/enfant_model.dart';
import '../../services/eveil_service.dart';
import '../../services/ia_eveil_service.dart';
import '../../theme/app_colors.dart';
import 'association_game_screen.dart';
import 'bilan_eveil_screen.dart';
import 'memory_game_screen.dart';

class EveilScreen extends StatefulWidget {
  final EnfantModel enfant;
  const EveilScreen({super.key, required this.enfant});

  @override
  State<EveilScreen> createState() => _EveilScreenState();
}

class _EveilScreenState extends State<EveilScreen> {
  static const Map<String?, String> _categories = {
    null: 'Tout',
    'langage': '🗣️ Langage',
    'memoire': '🧠 Mémoire',
    'logique': '🧩 Logique',
    'motricite': '✋ Motricité',
  };

  List<ActiviteModel> _activites = [];
  List<Recommandation> _recos = [];
  Set<int> _favoris = {};
  Set<String> _badges = {};
  String? _categorie;
  bool _loading = true;

  int get _ageMois => EveilService.ageEnMois(widget.enfant.dateNaissance);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final acts = await EveilService.getActivitesPourAge(_ageMois, categorie: _categorie);
    final favs = await EveilService.getFavoris(widget.enfant.id);
    final badges = await EveilService.getBadgesObtenus(widget.enfant.id);
    final recos = await IAEveilService.recommander(widget.enfant);
    if (!mounted) return;
    setState(() {
      _activites = acts;
      _favoris = favs;
      _badges = badges;
      _recos = recos;
      _loading = false;
    });
  }

  Future<void> _toggleFavori(ActiviteModel a) async {
    final estFavori = await EveilService.toggleFavori(widget.enfant.id, a.id);
    setState(() {
      if (estFavori) {
        _favoris.add(a.id);
      } else {
        _favoris.remove(a.id);
      }
    });
  }

  // ── Ouvrir une activité ───────────────────────────────────────────────────
  Future<void> _ouvrirActivite(ActiviteModel a) async {
    Widget? jeu;
    if (a.typeJeu == 'association') {
      jeu = AssociationGameScreen(enfant: widget.enfant, activite: a);
    } else if (a.typeJeu == 'memory') {
      jeu = MemoryGameScreen(enfant: widget.enfant, activite: a);
    }

    if (jeu != null) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => jeu!));
      _load(); // rafraîchir badges + recommandations après la partie
      return;
    }
    _ouvrirActiviteFamille(a);
  }

  // Activité à faire en famille (hors écran)
  void _ouvrirActiviteFamille(ActiviteModel a) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D2D5E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${a.emoji}  ${a.titre}',
                style: const TextStyle(color: AppColors.textPrimary,
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('${a.categorieLabel} · À faire en famille 👨‍👩‍👦',
                style: const TextStyle(color: AppColors.accent, fontSize: 12)),
            const SizedBox(height: 16),
            Text(a.description,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  Navigator.pop(sheetContext);
                  final nouveaux = await EveilService.enregistrerSeance(
                    enfantId: widget.enfant.id,
                    activiteId: a.id,
                    score: 100,
                    dureeSec: 0,
                  );
                  await _load();
                  _afficherNouveauxBadges(nouveaux);
                },
                child: const Text("C'est fait ! ✅",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _afficherNouveauxBadges(List<BadgeInfo> nouveaux) {
    if (nouveaux.isEmpty || !mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0D2D5E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Nouveau badge ! 🎉',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: nouveaux
              .map((b) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Text(b.emoji, style: const TextStyle(fontSize: 48)),
                Text(b.titre,
                    style: const TextStyle(color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700, fontSize: 16)),
                Text(b.description,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Super !', style: TextStyle(color: AppColors.secondary)),
          ),
        ],
      ),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Favoris en premier
    final liste = [..._activites]
      ..sort((a, b) => (_favoris.contains(b.id) ? 1 : 0) - (_favoris.contains(a.id) ? 1 : 0));

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.backgroundGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
              : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 30),
              children: [
                _buildHeader(),
                _buildBadges(),
                if (_categorie == null && _recos.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildRecommandations(),
                ],
                const SizedBox(height: 20),
                _buildCategories(),
                const SizedBox(height: 12),
                if (liste.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text('Aucune activité pour cet âge',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  )
                else
                  ...liste.map((a) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: _buildActiviteCard(a),
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Éveil & Jeux',
                    style: TextStyle(color: AppColors.textPrimary,
                        fontSize: 20, fontWeight: FontWeight.w700)),
                Text('${widget.enfant.prenom} · $_ageMois mois',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          // Bouton Bilan IA
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => BilanEveilScreen(enfant: widget.enfant),
            )),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.buttonGradient),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('📊 Bilan IA',
                  style: TextStyle(color: Colors.white,
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadges() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: EveilService.badges.map((b) {
          final obtenu = _badges.contains(b.code);
          return Opacity(
            opacity: obtenu ? 1 : 0.3,
            child: Column(
              children: [
                Text(b.emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 4),
                Text(b.titre,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 10)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ✨ Recommandations IA
  Widget _buildRecommandations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('✨ Recommandé pour ${widget.enfant.prenom}',
              style: const TextStyle(color: AppColors.textPrimary,
                  fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _recos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final r = _recos[i];
              return GestureDetector(
                onTap: () => _ouvrirActivite(r.activite),
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.35),
                        AppColors.accent.withOpacity(0.20),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(r.activite.emoji, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(r.activite.titre,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.textPrimary,
                                    fontSize: 13, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      Text(r.raison,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.accent, fontSize: 11)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: _categories.entries.map((e) {
          final selected = _categorie == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                _categorie = e.key;
                _load();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(colors: AppColors.buttonGradient)
                      : null,
                  color: selected ? null : AppColors.inputFill,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Text(e.value,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActiviteCard(ActiviteModel a) {
    final favori = _favoris.contains(a.id);
    return GestureDetector(
      onTap: () => _ouvrirActivite(a),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.glassWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Text(a.emoji, style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.titre,
                      style: const TextStyle(color: AppColors.textPrimary,
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text('${a.categorieLabel} · ${a.estJeu ? "🎮 Jeu" : "👨‍👩‍👦 En famille"}',
                      style: const TextStyle(color: AppColors.secondary, fontSize: 12)),
                  const SizedBox(height: 3),
                  Text(a.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _toggleFavori(a),
              icon: Icon(favori ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: favori ? AppColors.danger : AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}