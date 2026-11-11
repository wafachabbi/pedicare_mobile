import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/ia_pharma_service.dart';
import '../../services/ocr_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pc_ui.dart';

/// Scan d'une ordonnance papier (OCR Tesseract) pour préremplir une
/// prescription PediPharma. Renvoie la [LigneOrdonnance] choisie (et le
/// médecin lu) via `Navigator.pop`.
class ScanOrdonnanceScreen extends StatefulWidget {
  const ScanOrdonnanceScreen({super.key});

  @override
  State<ScanOrdonnanceScreen> createState() => _ScanOrdonnanceScreenState();
}

/// Résultat renvoyé au formulaire de prescription.
class ResultatScan {
  final LigneOrdonnance ligne;
  final String medecin;
  const ResultatScan(this.ligne, this.medecin);
}

class _ScanOrdonnanceScreenState extends State<ScanOrdonnanceScreen> {
  static const _violet = Color(0xFF9B59B6);

  String? _image;
  final _texte = TextEditingController();
  OrdonnanceAnalysee? _analyse;
  String? _etape; // message de progression
  String? _erreur;

  @override
  void dispose() {
    _texte.dispose();
    super.dispose();
  }

  Future<void> _scanner({required bool camera}) async {
    setState(() => _erreur = null);
    final String? chemin;
    try {
      chemin = await OcrService.choisirImage(camera: camera);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erreur = camera
          ? 'Impossible d\'ouvrir l\'appareil photo. Si vous venez de mettre '
              'l\'application à jour, arrêtez-la puis relancez « flutter run ».'
          : 'Impossible d\'ouvrir la galerie. Si vous venez de mettre '
              'l\'application à jour, arrêtez-la puis relancez « flutter run ».');
      return;
    }
    if (chemin == null || !mounted) return;
    setState(() {
      _image = chemin;
      _analyse = null;
      _etape = 'Lecture de l\'ordonnance (Tesseract)…';
    });
    try {
      final texte = await OcrService.lireTexte(chemin);
      if (!mounted) return;
      _texte.text = texte;
      if (texte.isEmpty) {
        setState(() {
          _etape = null;
          _erreur = 'Aucun texte lu. Reprenez la photo bien à plat, '
              'nette et bien éclairée.';
        });
        return;
      }
      await _analyser();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _etape = null;
        _erreur = 'La lecture a échoué : $e';
      });
    }
  }

  Future<void> _analyser() async {
    setState(() => _etape = 'Analyse des médicaments…');
    final a = await IaPharmaService.analyserOrdonnance(_texte.text);
    if (!mounted) return;
    setState(() {
      _analyse = a;
      _etape = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PcPage(
      titre: 'Scanner une ordonnance',
      sousTitre: 'Lecture par Tesseract (hors ligne)',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Row(
            children: [
              Expanded(
                child: _bouton(Icons.photo_camera_outlined, 'Prendre une photo',
                    () => _scanner(camera: true)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _bouton(Icons.photo_library_outlined, 'Galerie',
                    () => _scanner(camera: false)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(File(_image!),
                  height: 180, width: double.infinity, fit: BoxFit.cover),
            ),
          if (_etape != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                children: [
                  const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _violet)),
                  const SizedBox(width: 12),
                  Text(_etape!,
                      style: const TextStyle(color: AppColors.textPrimary)),
                ],
              ),
            ),
          if (_erreur != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: PcCard(
                color: AppColors.danger,
                child: Text(_erreur!,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 12.5)),
              ),
            ),
          if (_analyse != null) ...[
            PcSectionTitle(
              'Médicaments détectés (${_analyse!.lignes.length})',
              trailing: Text(_analyse!.parIA ? 'Structuré par IA' : 'Analyse locale',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
            ),
            if (_analyse!.medecin.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Médecin lu : ${_analyse!.medecin}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ),
            if (_analyse!.lignes.isEmpty)
              const PcCard(
                color: Color(0xFFE67E22),
                child: Text(
                  'Aucun médicament reconnu. Corrigez le texte ci-dessous '
                  'puis relancez l\'analyse, ou saisissez la prescription à la main.',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 12.5),
                ),
              ),
            for (final l in _analyse!.lignes) _ligne(l),
          ],
          if (_texte.text.isNotEmpty || _analyse != null) ...[
            const PcSectionTitle('Texte lu (modifiable)'),
            PcTextField(
              controller: _texte,
              label: 'Texte de l\'ordonnance',
              maxLines: 8,
            ),
            PcPrimaryButton(
              label: 'Relancer l\'analyse',
              color: _violet,
              onPressed: _etape == null ? _analyser : null,
            ),
          ],
          const SizedBox(height: 12),
          const PcAvertissement(
            'La lecture automatique peut contenir des erreurs : vérifiez chaque '
            'champ avec l\'ordonnance originale avant de prescrire.',
          ),
        ],
      ),
    );
  }

  Widget _bouton(IconData icon, String label, VoidCallback onTap) {
    return PcCard(
      color: _violet,
      margin: EdgeInsets.zero,
      onTap: _etape == null ? onTap : null,
      child: Column(
        children: [
          Icon(icon, color: _violet, size: 26),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _ligne(LigneOrdonnance l) {
    final details = [
      if (l.posologie.isNotEmpty) l.posologie,
      if (l.prisesParJour > 0) '${l.prisesParJour}×/jour',
      if (l.dureeJours != null) '${l.dureeJours} jours',
    ].join(' · ');
    return PcCard(
      color: _violet,
      onTap: () => Navigator.pop(
          context, ResultatScan(l, _analyse?.medecin ?? '')),
      child: Row(
        children: [
          const Text('💊', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.nom,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700)),
                if (l.reference != null)
                  Text('Reconnu : ${l.reference!.dci}',
                      style: const TextStyle(
                          color: AppColors.accent, fontSize: 11.5)),
                if (details.isNotEmpty)
                  Text(details,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11.5)),
              ],
            ),
          ),
          const Text('Utiliser',
              style: TextStyle(
                  color: _violet, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}
