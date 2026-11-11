import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/document_medical_model.dart';
import '../../models/enfant_model.dart';
import '../../services/document_service.dart';
import '../../theme/app_colors.dart';
import 'add_document_screen.dart';

class DocumentsScreen extends StatefulWidget {
  final EnfantModel enfant;
  final Map<String, dynamic> user;

  const DocumentsScreen({
    super.key,
    required this.enfant,
    required this.user,
  });

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  List<DocumentMedicalModel> _docs = [];
  bool _loading = true;
  CategorieDocument? _filtre; // null = tout afficher

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final docs = _filtre == null
        ? await DocumentService.getDocuments(widget.enfant.id)
        : await DocumentService.getDocumentsParCategorie(
            widget.enfant.id, _filtre!);
    if (mounted) setState(() { _docs = docs; _loading = false; });
  }

  Future<void> _supprimer(DocumentMedicalModel doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D2D5E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer le document',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Supprimer « ${doc.titre} » ? Cette action est définitive.',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer',
                style: TextStyle(color: AppColors.danger,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DocumentService.supprimerDocument(doc);
      _load();
    }
  }

  Future<void> _togglePartage(DocumentMedicalModel doc) async {
    await DocumentService.togglePartage(doc.id, !doc.partagePediatre);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.backgroundGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildFiltres(),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.secondary))
                    : _docs.isEmpty
                        ? _buildEmpty()
                        : _buildListe(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddDocumentScreen(
                enfant: widget.enfant,
                user: widget.user,
              ),
            ),
          );
          _load();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Ajouter',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
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
                const Text('Documents médicaux',
                    style: TextStyle(color: AppColors.textPrimary,
                        fontSize: 20, fontWeight: FontWeight.w700)),
                Text(widget.enfant.nomComplet,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          // Compteur
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Text('${_docs.length}',
                style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Filtres par catégorie ─────────────────────────────────────────────────
  Widget _buildFiltres() {
    final filtres = [null, ...CategorieDocument.values];
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filtres.length,
        itemBuilder: (context, i) {
          final cat = filtres[i];
          final selected = _filtre == cat;
          final label = cat == null ? 'Tous' : cat.label;
          final emoji = cat == null ? '📂' : cat.emoji;
          return GestureDetector(
            onTap: () {
              setState(() => _filtre = cat);
              _load();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(colors: AppColors.buttonGradient)
                    : null,
                color: selected ? null : AppColors.inputFill,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: selected
                        ? Colors.transparent
                        : AppColors.glassBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text(label,
                      style: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Liste ─────────────────────────────────────────────────────────────────
  Widget _buildListe() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: _docs.length,
      itemBuilder: (context, i) => _DocCard(
        doc: _docs[i],
        onSupprimer: () => _supprimer(_docs[i]),
        onTogglePartage: () => _togglePartage(_docs[i]),
      ),
    );
  }

  // ── Vide ──────────────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📋', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              _filtre == null
                  ? 'Aucun document médical'
                  : 'Aucun document dans cette catégorie',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Ajoutez ordonnances, résultats d\'analyses,\ncomptes-rendus ou carnet vaccinal.',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Carte document ────────────────────────────────────────────────────────────
class _DocCard extends StatelessWidget {
  final DocumentMedicalModel doc;
  final VoidCallback onSupprimer;
  final VoidCallback onTogglePartage;

  const _DocCard({
    required this.doc,
    required this.onSupprimer,
    required this.onTogglePartage,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy', 'fr_FR');
    final color = _colorPourCategorie(doc.categorie);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // ── Ligne principale ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icône catégorie
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Center(
                    child: Text(doc.categorie.emoji,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doc.titre,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          _chip(doc.categorie.label, color),
                          const SizedBox(width: 6),
                          Text(fmt.format(doc.dateDocument),
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11)),
                        ],
                      ),
                      if (doc.medecin != null &&
                          doc.medecin!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text('Dr. ${doc.medecin}',
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11)),
                      ],
                      if (doc.aStructureOrdonnance) ...[
                        const SizedBox(height: 4),
                        Text('💊 ${doc.medicament}',
                            style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                        if (doc.posologie != null &&
                            doc.posologie!.isNotEmpty)
                          Text('  ${doc.posologie}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10.5)),
                      ],
                    ],
                  ),
                ),
                // Aperçu miniature si fichier présent
                if (doc.aFichier) _buildThumbnail(doc.cheminFichier!),
              ],
            ),
          ),

          // ── Pied de carte : actions ───────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(color: AppColors.glassBorder)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                // OCR badge
                if (doc.aOcr)
                  _badgeAction('✨ OCR', AppColors.accent),
                const Spacer(),
                // Partage
                GestureDetector(
                  onTap: onTogglePartage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: doc.partagePediatre
                          ? AppColors.accent.withValues(alpha: 0.15)
                          : AppColors.inputFill,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: doc.partagePediatre
                              ? AppColors.accent.withValues(alpha: 0.5)
                              : AppColors.glassBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          doc.partagePediatre
                              ? Icons.share_rounded
                              : Icons.share_outlined,
                          color: doc.partagePediatre
                              ? AppColors.accent
                              : AppColors.textSecondary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          doc.partagePediatre ? 'Partagé' : 'Partager',
                          style: TextStyle(
                              color: doc.partagePediatre
                                  ? AppColors.accent
                                  : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Supprimer
                GestureDetector(
                  onTap: onSupprimer,
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color:
                              AppColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.danger, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 9.5, fontWeight: FontWeight.w600)),
    );
  }

  Widget _badgeAction(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildThumbnail(String path) {
    final file = File(path);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: file.existsSync()
          ? Image.file(file, width: 52, height: 52, fit: BoxFit.cover)
          : Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.insert_drive_file_outlined,
                  color: AppColors.textSecondary, size: 24),
            ),
    );
  }

  Color _colorPourCategorie(CategorieDocument cat) {
    switch (cat) {
      case CategorieDocument.ordonnance:
        return const Color(0xFF9B59B6);
      case CategorieDocument.resultat:
        return const Color(0xFF00C9A7);
      case CategorieDocument.compteRendu:
        return const Color(0xFF1E6FDB);
      case CategorieDocument.radio:
        return const Color(0xFF4DAAFF);
      case CategorieDocument.vaccin:
        return const Color(0xFFE67E22);
      case CategorieDocument.autre:
        return AppColors.textSecondary;
    }
  }
}
