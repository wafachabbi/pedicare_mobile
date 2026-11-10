import 'package:flutter/material.dart';
import '../../services/rag/base_connaissances.dart';
import '../../services/rag/rag_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pc_ui.dart';

/// Affiche un passage cité par l'assistant, avec sa source.
void ouvrirPassage(BuildContext context, String passageId) {
  final base = BaseConnaissances.instance;
  final p = base.passages.where((x) => x.id == passageId).firstOrNull;
  if (p == null) {
    pcSnack(context, 'Cette source n\'existe plus dans la base.', erreur: true);
    return;
  }
  final fiche = base.passages.where((x) => x.ficheId == p.ficheId).toList();
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
      builder: (_, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        children: [
          Text('${p.emoji} ${p.ficheTitre}',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Source : ${p.source}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 14),
          for (final s in fiche)
            PcCard(
              color: s.id == p.id ? AppColors.secondary : AppColors.textSecondary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.section,
                      style: TextStyle(
                          color: s.id == p.id
                              ? AppColors.secondary
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(s.texte,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 13, height: 1.4)),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

/// Base de connaissances de l'assistant : fiches par catégorie + recherche.
class BaseConnaissancesScreen extends StatefulWidget {
  const BaseConnaissancesScreen({super.key});

  @override
  State<BaseConnaissancesScreen> createState() =>
      _BaseConnaissancesScreenState();
}

class _BaseConnaissancesScreenState extends State<BaseConnaissancesScreen> {
  final _recherche = TextEditingController();
  List<PassageTrouve>? _resultats;

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  void _chercher(String t) {
    setState(() => _resultats =
        t.trim().length < 3 ? null : RagService.rechercherBm25(t, k: 8));
  }

  @override
  Widget build(BuildContext context) {
    final base = BaseConnaissances.instance;
    // Une entrée par fiche (premier passage), groupée par catégorie.
    final fiches = <String, Passage>{};
    for (final p in base.passages) {
      fiches.putIfAbsent(p.ficheId, () => p);
    }
    final parCategorie = <String, List<Passage>>{};
    for (final p in fiches.values) {
      parCategorie.putIfAbsent(p.categorie, () => []).add(p);
    }

    return PcPage(
      titre: 'Base de connaissances',
      sousTitre: '${base.nombreFiches} fiches · ${base.passages.length} passages',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          TextField(
            controller: _recherche,
            onChanged: _chercher,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: pcInputDecoration('Rechercher (ex. fièvre, dents, gastro)',
                icon: Icons.search_rounded),
          ),
          const SizedBox(height: 12),
          if (_resultats != null) ...[
            PcSectionTitle('Résultats (${_resultats!.length})'),
            if (_resultats!.isEmpty)
              const Text('Aucun passage pertinent.',
                  style: TextStyle(color: AppColors.textSecondary)),
            for (final r in _resultats!) _ligne(r.passage, score: r.score),
          ] else
            for (final e in parCategorie.entries) ...[
              PcSectionTitle('${e.key} (${e.value.length})'),
              for (final p in e.value) _ligne(p),
            ],
          const SizedBox(height: 8),
          const PcAvertissement(
            'Fiches rédigées à partir de recommandations publiques (Assurance '
            'Maladie, Santé publique France, HAS, OMS, Société française de '
            'pédiatrie). Informations générales qui ne remplacent pas un avis médical.',
          ),
        ],
      ),
    );
  }

  Widget _ligne(Passage p, {double? score}) {
    return PcCard(
      color: AppColors.secondary,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.only(bottom: 6),
      onTap: () => ouvrirPassage(context, p.id),
      child: Row(
        children: [
          Text(p.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(score == null ? p.ficheTitre : p.titreComplet,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(p.source,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          if (score != null)
            Text(score.toStringAsFixed(1),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
