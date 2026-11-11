import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/document_medical_model.dart';
import '../../models/enfant_model.dart';
import '../../services/document_service.dart';
import '../../services/ocr_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/gradient_button.dart';

class AddDocumentScreen extends StatefulWidget {
  final EnfantModel enfant;
  final Map<String, dynamic> user;

  const AddDocumentScreen({
    super.key,
    required this.enfant,
    required this.user,
  });

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  final _titreCtrl = TextEditingController();
  final _medecinCtrl = TextEditingController();
  final _etablissementCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _medicamentCtrl = TextEditingController();
  final _posologieCtrl = TextEditingController();
  final _prescripteurCtrl = TextEditingController();

  CategorieDocument _categorie = CategorieDocument.ordonnance;
  DateTime _dateDoc = DateTime.now();
  String? _cheminImage;
  String? _texteOcr;
  bool _loading = false;
  bool _ocrLoading = false;
  bool _partagePediatre = false;

  @override
  void dispose() {
    _titreCtrl.dispose();
    _medecinCtrl.dispose();
    _etablissementCtrl.dispose();
    _notesCtrl.dispose();
    _medicamentCtrl.dispose();
    _posologieCtrl.dispose();
    _prescripteurCtrl.dispose();
    super.dispose();
  }

  // ── OCR ───────────────────────────────────────────────────────────────────
  Future<void> _choisirImage(ImageSource source) async {
    final path = await OcrService.choisirImage(camera: source == ImageSource.camera);
    if (path == null || !mounted) return;
    setState(() { _cheminImage = path; _texteOcr = null; });

    // OCR automatique pour les ordonnances
    if (_categorie == CategorieDocument.ordonnance) {
      _lancerOcr(path);
    }
  }

  Future<void> _lancerOcr(String path) async {
    setState(() => _ocrLoading = true);
    try {
      final texte = await OcrService.lireTexte(path);
      if (!mounted) return;
      setState(() { _texteOcr = texte; });
      _extraireStructureOrdonnance(texte);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OCR indisponible : $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _ocrLoading = false);
    }
  }

  /// Heuristique simple pour pré-remplir médicament / posologie / prescripteur
  /// depuis le texte brut de l'ordonnance.
  void _extraireStructureOrdonnance(String texte) {
    final lignes = texte.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    // Prescripteur : première ligne contenant "Dr" ou "Docteur"
    for (final l in lignes) {
      if (RegExp(r'Dr\.?|Docteur', caseSensitive: false).hasMatch(l)) {
        if (_prescripteurCtrl.text.isEmpty) {
          _prescripteurCtrl.text = l.replaceAll(RegExp(r'\s+'), ' ').trim();
        }
        break;
      }
    }

    // Médicament : ligne contenant mg, ml, cp, gél, comprimé
    for (final l in lignes) {
      if (RegExp(r'\d+\s*(mg|ml|g|cp|gél|comprimé|gelule|suspension)',
              caseSensitive: false)
          .hasMatch(l)) {
        if (_medicamentCtrl.text.isEmpty) {
          _medicamentCtrl.text = l.replaceAll(RegExp(r'\s+'), ' ').trim();
        }
        break;
      }
    }

    // Posologie : ligne contenant x/jour, matin, soir, fois par jour
    for (final l in lignes) {
      if (RegExp(r'matin|soir|midi|jour|fois|prise|pendant|jours?',
              caseSensitive: false)
          .hasMatch(l)) {
        if (_posologieCtrl.text.isEmpty) {
          _posologieCtrl.text = l.replaceAll(RegExp(r'\s+'), ' ').trim();
        }
        break;
      }
    }

    // Titre automatique si vide
    if (_titreCtrl.text.isEmpty && lignes.isNotEmpty) {
      _titreCtrl.text = 'Ordonnance — ${widget.enfant.prenom}';
    }

    setState(() {});
  }

  // ── Sauvegarde ────────────────────────────────────────────────────────────
  Future<void> _sauvegarder() async {
    final titre = _titreCtrl.text.trim();
    if (titre.isEmpty) {
      _showError('Le titre est obligatoire.');
      return;
    }

    setState(() => _loading = true);

    final parentId =
        (widget.user['id'] ?? widget.user['uid'] ?? '1').toString();

    final doc = DocumentMedicalModel(
      id: '',
      enfantId: widget.enfant.id,
      parentId: parentId,
      titre: titre,
      categorie: _categorie,
      dateDocument: _dateDoc,
      medecin: _medecinCtrl.text.trim().isEmpty ? null : _medecinCtrl.text.trim(),
      etablissement: _etablissementCtrl.text.trim().isEmpty
          ? null
          : _etablissementCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      texteOcr: _texteOcr,
      medicament: _medicamentCtrl.text.trim().isEmpty
          ? null
          : _medicamentCtrl.text.trim(),
      posologie: _posologieCtrl.text.trim().isEmpty
          ? null
          : _posologieCtrl.text.trim(),
      prescripteur: _prescripteurCtrl.text.trim().isEmpty
          ? null
          : _prescripteurCtrl.text.trim(),
      partagePediatre: _partagePediatre,
    );

    final id = await DocumentService.ajouterDocument(
      doc,
      cheminSourceFichier: _cheminImage,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (id == null) {
      _showError('Erreur lors de l\'enregistrement.');
    } else {
      Navigator.pop(context);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _choisirDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dateDoc,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: Color(0xFF0D2D5E),
          ),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _dateDoc = d);
  }

  // ── Build ─────────────────────────────────────────────────────────────────
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
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCategorieSelector(),
                      const SizedBox(height: 20),
                      _buildImageSection(),
                      const SizedBox(height: 20),
                      _buildSection('Informations générales', [
                        _buildField('Titre du document *',
                            Icons.title_rounded, _titreCtrl),
                        const SizedBox(height: 12),
                        _buildDateField(),
                        const SizedBox(height: 12),
                        _buildField('Médecin / Spécialiste',
                            Icons.person_outline_rounded, _medecinCtrl),
                        const SizedBox(height: 12),
                        _buildField('Établissement / Clinique',
                            Icons.local_hospital_outlined,
                            _etablissementCtrl),
                      ]),
                      if (_categorie == CategorieDocument.ordonnance) ...[
                        const SizedBox(height: 20),
                        _buildSection('Données extraites (ordonnance)', [
                          if (_ocrLoading)
                            _buildOcrLoader()
                          else ...[
                            _buildField('Médicament prescrit',
                                Icons.medication_outlined, _medicamentCtrl),
                            const SizedBox(height: 12),
                            _buildField('Posologie',
                                Icons.schedule_outlined, _posologieCtrl),
                            const SizedBox(height: 12),
                            _buildField('Médecin prescripteur',
                                Icons.medical_services_outlined,
                                _prescripteurCtrl),
                            if (_texteOcr != null) ...[
                              const SizedBox(height: 12),
                              _buildOcrTexte(),
                            ],
                          ],
                        ]),
                      ],
                      const SizedBox(height: 20),
                      _buildSection('Notes & confidentialité', [
                        _buildField('Notes complémentaires',
                            Icons.notes_rounded, _notesCtrl,
                            maxLines: 3),
                        const SizedBox(height: 14),
                        _buildPartageSwitch(),
                      ]),
                      const SizedBox(height: 28),
                      GradientButton(
                        label: 'Enregistrer le document',
                        onTap: _sauvegarder,
                        loading: _loading,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nouveau document',
                  style: TextStyle(color: AppColors.textPrimary,
                      fontSize: 20, fontWeight: FontWeight.w700)),
              Text('Dossier médical numérique',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Sélecteur de catégorie ─────────────────────────────────────────────────
  Widget _buildCategorieSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Catégorie',
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        SizedBox(
          height: 70,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: CategorieDocument.values.map((cat) {
              final sel = _categorie == cat;
              final color = _colorPourCategorie(cat);
              return GestureDetector(
                onTap: () => setState(() => _categorie = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel
                        ? color.withValues(alpha: 0.2)
                        : AppColors.inputFill,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: sel
                            ? color
                            : AppColors.glassBorder,
                        width: sel ? 2 : 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(cat.emoji,
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 4),
                      Text(cat.label,
                          style: TextStyle(
                              color: sel ? color : AppColors.textSecondary,
                              fontSize: 9.5,
                              fontWeight: sel
                                  ? FontWeight.w700
                                  : FontWeight.w500)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Zone image ─────────────────────────────────────────────────────────────
  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Photo du document',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            if (_cheminImage != null &&
                _categorie == CategorieDocument.ordonnance)
              GestureDetector(
                onTap: () => _lancerOcr(_cheminImage!),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('✨', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 4),
                      Text('OCR',
                          style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (_cheminImage == null)
          Row(
            children: [
              Expanded(
                child: _buildImageBtn(
                    '📷', 'Appareil photo', ImageSource.camera),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildImageBtn(
                    '🖼️', 'Galerie', ImageSource.gallery),
              ),
            ],
          )
        else
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(_cheminImage!),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8, right: 8,
                child: GestureDetector(
                  onTap: () =>
                      setState(() { _cheminImage = null; _texteOcr = null; }),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildImageBtn(String emoji, String label, ImageSource source) {
    return GestureDetector(
      onTap: () => _choisirImage(source),
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.glassBorder,
              style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ── Loader OCR ─────────────────────────────────────────────────────────────
  Widget _buildOcrLoader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.accent)),
          SizedBox(width: 12),
          Text('Extraction du texte en cours…',
              style: TextStyle(
                  color: AppColors.accent, fontSize: 13)),
        ],
      ),
    );
  }

  // ── Texte OCR brut ─────────────────────────────────────────────────────────
  Widget _buildOcrTexte() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('✨',
                  style: TextStyle(fontSize: 13)),
              SizedBox(width: 6),
              Text('Texte extrait (OCR)',
                  style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _texteOcr!.length > 400
                ? '${_texteOcr!.substring(0, 400)}…'
                : _texteOcr!,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10.5,
                height: 1.5,
                fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  // ── Champ date ─────────────────────────────────────────────────────────────
  Widget _buildDateField() {
    final fmt = DateFormat('dd MMMM yyyy', 'fr_FR');
    return GestureDetector(
      onTap: _choisirDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(fmt.format(_dateDoc),
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 15)),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }

  // ── Champ texte générique ──────────────────────────────────────────────────
  Widget _buildField(String hint, IconData icon,
      TextEditingController ctrl, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(
            color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              color: AppColors.textSecondary, fontSize: 14),
          prefixIcon: maxLines == 1
              ? Icon(icon, color: AppColors.textSecondary, size: 20)
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
              horizontal: maxLines > 1 ? 16 : 0, vertical: 16),
        ),
      ),
    );
  }

  // ── Switch partage ─────────────────────────────────────────────────────────
  Widget _buildPartageSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _partagePediatre
            ? AppColors.accent.withValues(alpha: 0.08)
            : AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: _partagePediatre
                ? AppColors.accent.withValues(alpha: 0.4)
                : AppColors.glassBorder),
      ),
      child: Row(
        children: [
          const Text('🔒', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Partager avec le pédiatre',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const Text(
                    'Le pédiatre désigné pourra consulter ce document.',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11)),
              ],
            ),
          ),
          Switch.adaptive(
            value: _partagePediatre,
            onChanged: (v) => setState(() => _partagePediatre = v),
            activeColor: AppColors.accent,
          ),
        ],
      ),
    );
  }

  // ── Wrapper section ────────────────────────────────────────────────────────
  Widget _buildSection(String titre, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titre,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
        const SizedBox(height: 10),
        ...children,
      ],
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
