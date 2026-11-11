import 'package:flutter/material.dart';
import '../../models/activite_model.dart';
import '../../models/enfant_model.dart';
import '../../services/eveil_service.dart';
import '../../theme/app_colors.dart';
import 'eveil_widgets.dart';

class MemoryGameScreen extends StatefulWidget {
  final EnfantModel enfant;
  final ActiviteModel activite;
  const MemoryGameScreen({super.key, required this.enfant, required this.activite});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _CarteMemory {
  final String emoji;
  bool retournee = false;
  bool trouvee = false;
  _CarteMemory(this.emoji);
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  static const List<String> _animaux = ['🐱', '🐶', '🐮', '🐷', '🐸', '🐵'];
  static const List<String> _formes  = ['🔴', '🟦', '🔺', '⭐', '💜', '🟢'];

  late final List<_CarteMemory> _cartes;
  late final int _nbPaires;
  late final DateTime _debut;

  int _tentatives = 0;
  int _pairesTrouvees = 0;
  _CarteMemory? _premiere;
  bool _bloque = false;

  @override
  void initState() {
    super.initState();
    final formes = widget.activite.titre.toLowerCase().contains('forme');
    _nbPaires = formes ? 6 : 3;                     // 12 cartes ou 6 cartes
    final emojis = (formes ? _formes : _animaux).take(_nbPaires).toList();
    _cartes = [...emojis, ...emojis].map((e) => _CarteMemory(e)).toList()..shuffle();
    _debut = DateTime.now();
  }

  Future<void> _retourner(_CarteMemory carte) async {
    if (_bloque || carte.retournee || carte.trouvee) return;
    setState(() => carte.retournee = true);

    // 1ère carte de la paire
    if (_premiere == null) {
      _premiere = carte;
      return;
    }

    // 2ème carte : on compare
    _tentatives++;
    final premiere = _premiere!;
    _premiere = null;

    if (premiere.emoji == carte.emoji) {
      setState(() {
        premiere.trouvee = true;
        carte.trouvee = true;
        _pairesTrouvees++;
      });
      if (_pairesTrouvees == _nbPaires) await _terminer();
    } else {
      _bloque = true;
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() {
        premiere.retournee = false;
        carte.retournee = false;
      });
      _bloque = false;
    }
  }

  Future<void> _terminer() async {
    // 100 % si toutes les paires sont trouvées sans erreur
    final score = (_nbPaires * 100 / _tentatives).round();
    final duree = DateTime.now().difference(_debut).inSeconds;
    final nouveaux = await EveilService.enregistrerSeance(
      enfantId: widget.enfant.id,
      activiteId: widget.activite.id,
      score: score,
      dureeSec: duree,
    );
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    await afficherResultat(context, score: score, nouveauxBadges: nouveaux);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header
                Row(
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
                        child: const Icon(Icons.close_rounded,
                            color: AppColors.textPrimary, size: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(widget.activite.titre,
                          style: const TextStyle(color: AppColors.textPrimary,
                              fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _stat('Paires', '$_pairesTrouvees / $_nbPaires'),
                    _stat('Essais', '$_tentatives'),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Retrouve les cartes identiques !',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),

                // Grille de cartes
                Expanded(
                  child: Center(
                    child: GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: _nbPaires == 3 ? 3 : 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      children: _cartes.map(_buildCarte).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String valeur) {
    return Column(
      children: [
        Text(valeur,
            style: const TextStyle(color: AppColors.textPrimary,
                fontSize: 22, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(color: AppColors.secondary, fontSize: 12)),
      ],
    );
  }

  Widget _buildCarte(_CarteMemory carte) {
    final visible = carte.retournee || carte.trouvee;
    return GestureDetector(
      onTap: () => _retourner(carte),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          gradient: visible ? null : const LinearGradient(colors: AppColors.buttonGradient),
          color: visible ? AppColors.glassWhite : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: carte.trouvee ? AppColors.accent : AppColors.glassBorder,
            width: carte.trouvee ? 3 : 1,
          ),
        ),
        child: Center(
          child: Text(visible ? carte.emoji : '❓',
              style: TextStyle(fontSize: visible ? 40 : 28)),
        ),
      ),
    );
  }
}