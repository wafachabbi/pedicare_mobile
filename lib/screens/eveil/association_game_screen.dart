import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/activite_model.dart';
import '../../models/enfant_model.dart';
import '../../services/eveil_service.dart';
import '../../theme/app_colors.dart';
import 'eveil_widgets.dart';

class AssociationGameScreen extends StatefulWidget {
  final EnfantModel enfant;
  final ActiviteModel activite;
  const AssociationGameScreen({super.key, required this.enfant, required this.activite});

  @override
  State<AssociationGameScreen> createState() => _AssociationGameScreenState();
}

class _AssociationGameScreenState extends State<AssociationGameScreen> {
  // [emoji, mot]
  static const List<List<String>> _animaux = [
    ['🐱', 'Chat'], ['🐶', 'Chien'], ['🐮', 'Vache'], ['🐑', 'Mouton'],
    ['🐔', 'Poule'], ['🐟', 'Poisson'], ['🦁', 'Lion'], ['🐘', 'Éléphant'],
  ];
  static const List<List<String>> _fruits = [
    ['🍎', 'Pomme'], ['🍌', 'Banane'], ['🍇', 'Raisin'], ['🍓', 'Fraise'],
    ['🍊', 'Orange'], ['🍉', 'Pastèque'], ['🍐', 'Poire'], ['🍒', 'Cerise'],
  ];
  static const List<List<String>> _couleurs = [
    ['🍎', 'Rouge'], ['🍌', 'Jaune'], ['🥦', 'Vert'],
    ['🫐', 'Bleu'], ['🍊', 'Orange'], ['🍆', 'Violet'],
  ];

  static const int _nbQuestions = 5;
  final _random = Random();

  late final List<List<String>> _items;
  late final List<List<String>> _questions;
  late final DateTime _debut;
  late final bool _modeCouleur;

  int _index = 0;
  int _bonnes = 0;
  List<String> _choix = [];
  String? _reponseChoisie;

  @override
  void initState() {
    super.initState();
    final titre = widget.activite.titre.toLowerCase();
    _modeCouleur = titre.contains('couleur');
    _items = titre.contains('fruit')
        ? _fruits
        : _modeCouleur
        ? _couleurs
        : _animaux;
    _questions = ([..._items]..shuffle(_random)).take(_nbQuestions).toList();
    _debut = DateTime.now();
    _preparerChoix();
  }

  void _preparerChoix() {
    final bonne = _questions[_index][1];
    final autres = _items.map((e) => e[1]).where((m) => m != bonne).toList()
      ..shuffle(_random);
    _choix = [bonne, ...autres.take(2)]..shuffle(_random);
    _reponseChoisie = null;
  }

  Future<void> _repondre(String mot) async {
    if (_reponseChoisie != null) return; // déjà répondu
    final correct = mot == _questions[_index][1];
    setState(() {
      _reponseChoisie = mot;
      if (correct) _bonnes++;
    });

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    if (_index < _questions.length - 1) {
      setState(() {
        _index++;
        _preparerChoix();
      });
    } else {
      await _terminer();
    }
  }

  Future<void> _terminer() async {
    final score = (_bonnes * 100 / _questions.length).round();
    final duree = DateTime.now().difference(_debut).inSeconds;
    final nouveaux = await EveilService.enregistrerSeance(
      enfantId: widget.enfant.id,
      activiteId: widget.activite.id,
      score: score,
      dureeSec: duree,
    );
    if (!mounted) return;
    await afficherResultat(context, score: score, nouveauxBadges: nouveaux);
    if (mounted) Navigator.pop(context);
  }

  Color _couleurBouton(String mot) {
    if (_reponseChoisie == null) return AppColors.glassWhite;
    if (mot == _questions[_index][1]) return AppColors.accent.withOpacity(0.35);
    if (mot == _reponseChoisie) return AppColors.danger.withOpacity(0.35);
    return AppColors.glassWhite;
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_index];

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
                    Text('${_index + 1} / ${_questions.length}',
                        style: const TextStyle(color: AppColors.secondary,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (_index + 1) / _questions.length,
                    minHeight: 8,
                    backgroundColor: AppColors.inputFill,
                    color: AppColors.accent,
                  ),
                ),

                const Spacer(),

                // Image
                Container(
                  width: 180, height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.glassWhite,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.glassBorder, width: 2),
                  ),
                  child: Center(
                    child: Text(question[0], style: const TextStyle(fontSize: 96)),
                  ),
                ),
                const SizedBox(height: 24),
                Text(_modeCouleur ? 'Quelle est sa couleur ?' : "Qu'est-ce que c'est ?",
                    style: const TextStyle(color: AppColors.textPrimary,
                        fontSize: 20, fontWeight: FontWeight.w600)),

                const Spacer(),

                // Choix
                ..._choix.map((mot) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => _repondre(mot),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: _couleurBouton(mot),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Text(mot,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white,
                              fontSize: 22, fontWeight: FontWeight.w700)),
                    ),
                  ),
                )),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}