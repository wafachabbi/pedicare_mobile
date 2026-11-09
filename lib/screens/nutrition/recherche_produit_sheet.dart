import 'package:flutter/material.dart';
import '../../services/open_food_facts_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pc_ui.dart';

/// Recherche d'un produit sur Open Food Facts (nom ou code-barres).
/// Renvoie le [ProduitAlimentaire] choisi via `Navigator.pop`.
class RechercheProduitSheet extends StatefulWidget {
  /// Allergènes de l'enfant, pour signaler les produits à risque.
  final Set<String> allergenesEnfant;

  const RechercheProduitSheet({super.key, this.allergenesEnfant = const {}});

  @override
  State<RechercheProduitSheet> createState() => _RechercheProduitSheetState();
}

class _RechercheProduitSheetState extends State<RechercheProduitSheet> {
  static const _orange = Color(0xFFE67E22);

  final _terme = TextEditingController();
  List<ProduitAlimentaire> _resultats = [];
  bool _loading = false;
  String? _message;

  @override
  void dispose() {
    _terme.dispose();
    super.dispose();
  }

  Future<void> _rechercher() async {
    final t = _terme.text.trim();
    if (t.length < 2) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final r = await OpenFoodFactsService.rechercher(t);
      if (!mounted) return;
      setState(() {
        _resultats = r;
        _message = r.isEmpty ? 'Aucun produit trouvé.' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _message =
          'Recherche impossible : vérifiez la connexion Internet.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rechercher un produit',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const Text('Source : Open Food Facts (Internet requis)',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 11.5)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _terme,
                          autofocus: true,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _rechercher(),
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: pcInputDecoration(
                              'Nom (ex. yaourt fraise) ou code-barres',
                              icon: Icons.search_rounded),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _loading ? null : _rechercher,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _orange,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: _loading
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(_message!,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                children: [for (final p in _resultats) _produit(p)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _produit(ProduitAlimentaire p) {
    final risques =
        p.allergenes.where(widget.allergenesEnfant.contains).toList();
    final color = risques.isNotEmpty ? AppColors.danger : _orange;
    return PcCard(
      color: color,
      onTap: () => Navigator.pop(context, p),
      child: Row(
        children: [
          if (p.nutriscore.isNotEmpty) ...[
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _couleurNutriscore(p.nutriscore),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(p.nutriscore.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.nom,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700)),
                if (p.marque.isNotEmpty)
                  Text(p.marque,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11.5)),
                Text(
                  p.allergenes.isEmpty
                      ? 'Aucun allergène majeur déclaré'
                      : 'Allergènes : ${p.allergenesLibelles.join(', ')}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11.5),
                ),
                if (risques.isNotEmpty)
                  const Text('⛔ Contient un allergène de l\'enfant',
                      style: TextStyle(
                          color: AppColors.danger,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Color _couleurNutriscore(String s) => switch (s) {
        'a' => const Color(0xFF038141),
        'b' => const Color(0xFF85BB2F),
        'c' => const Color(0xFFFECB02),
        'd' => const Color(0xFFEE8100),
        _ => const Color(0xFFE63E11),
      };
}
