import 'package:flutter/foundation.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:image_picker/image_picker.dart';

/// OCR des ordonnances avec Tesseract (Module 5 — PediPharma).
///
/// Le modèle français `assets/tessdata/fra.traineddata` est embarqué dans
/// l'application : la lecture fonctionne hors ligne.
class OcrService {
  OcrService._();

  static final _picker = ImagePicker();

  /// Ouvre l'appareil photo ou la galerie. Null si l'utilisateur annule.
  static Future<String?> choisirImage({required bool camera}) async {
    final image = await _picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      // Une résolution modérée suffit à Tesseract et accélère la lecture.
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 90,
    );
    return image?.path;
  }

  /// Extrait le texte de l'image. Lève une exception si Tesseract échoue.
  static Future<String> lireTexte(String cheminImage) async {
    final texte = await FlutterTesseractOcr.extractText(
      cheminImage,
      language: 'fra',
      args: {
        // psm 4 : texte en une colonne de lignes de tailles variables,
        // adapté à la mise en page d'une ordonnance.
        'psm': '4',
        'preserve_interword_spaces': '1',
      },
    );
    debugPrint('[OCR] ${texte.length} caractères lus');
    return texte.trim();
  }
}
