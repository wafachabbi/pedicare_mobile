import 'dart:developer' as dev;
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/document_medical_model.dart';
import 'database_service.dart';

/// Service CRUD pour les documents médicaux.
///
/// Chaque fichier est copié dans un sous-dossier de l'espace privé de
/// l'application (`documents_medicaux/<enfant_id>/`) pour être accessible
/// hors connexion même si l'image source est supprimée de la galerie.
class DocumentService {
  DocumentService._();

  // ── Dossier de stockage ───────────────────────────────────────────────────

  /// Répertoire de destination pour les fichiers d'un enfant.
  static Future<Directory> _dirEnfant(String enfantId) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'documents_medicaux', enfantId));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Copie [sourcePath] dans le répertoire privé de l'enfant et retourne
  /// le nouveau chemin. Retourne null si la source n'existe pas.
  static Future<String?> copierFichier(
      String sourcePath, String enfantId) async {
    try {
      final source = File(sourcePath);
      if (!await source.exists()) return null;
      final dir = await _dirEnfant(enfantId);
      final ext = p.extension(sourcePath);
      final nom =
          '${DateTime.now().millisecondsSinceEpoch}$ext';
      final dest = File(p.join(dir.path, nom));
      await source.copy(dest.path);
      return dest.path;
    } catch (e) {
      dev.log('DocumentService.copierFichier error: $e');
      return null;
    }
  }

  /// Supprime le fichier local associé à un document (silencieux si absent).
  static Future<void> supprimerFichier(String? chemin) async {
    if (chemin == null || chemin.isEmpty) return;
    try {
      final f = File(chemin);
      if (await f.exists()) await f.delete();
    } catch (e) {
      dev.log('DocumentService.supprimerFichier error: $e');
    }
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  /// Récupère tous les documents d'un enfant, triés par date décroissante.
  static Future<List<DocumentMedicalModel>> getDocuments(
      String enfantId) async {
    try {
      final db = await DatabaseService.database;
      final rows = await db.query(
        'documents_medicaux',
        where: 'enfant_id = ?',
        whereArgs: [int.parse(enfantId)],
        orderBy: 'date_document DESC, created_at DESC',
      );
      return rows.map(DocumentMedicalModel.fromMap).toList();
    } catch (e) {
      dev.log('DocumentService.getDocuments error: $e');
      return [];
    }
  }

  /// Récupère les documents d'un enfant filtrés par catégorie.
  static Future<List<DocumentMedicalModel>> getDocumentsParCategorie(
      String enfantId, CategorieDocument categorie) async {
    try {
      final db = await DatabaseService.database;
      final rows = await db.query(
        'documents_medicaux',
        where: 'enfant_id = ? AND categorie = ?',
        whereArgs: [int.parse(enfantId), categorie.code],
        orderBy: 'date_document DESC',
      );
      return rows.map(DocumentMedicalModel.fromMap).toList();
    } catch (e) {
      dev.log('DocumentService.getDocumentsParCategorie error: $e');
      return [];
    }
  }

  /// Récupère les documents partagés avec le pédiatre pour un enfant.
  static Future<List<DocumentMedicalModel>> getDocumentsPartages(
      String enfantId) async {
    try {
      final db = await DatabaseService.database;
      final rows = await db.query(
        'documents_medicaux',
        where: 'enfant_id = ? AND partage_pediatre = 1',
        whereArgs: [int.parse(enfantId)],
        orderBy: 'date_document DESC',
      );
      return rows.map(DocumentMedicalModel.fromMap).toList();
    } catch (e) {
      dev.log('DocumentService.getDocumentsPartages error: $e');
      return [];
    }
  }

  /// Ajoute un document. Si [cheminSourceFichier] est fourni, il est copié
  /// dans l'espace privé de l'app avant l'insertion en base.
  /// Retourne l'ID généré (String) ou null en cas d'erreur.
  static Future<String?> ajouterDocument(
    DocumentMedicalModel doc, {
    String? cheminSourceFichier,
  }) async {
    try {
      String? cheminDest;
      if (cheminSourceFichier != null && cheminSourceFichier.isNotEmpty) {
        cheminDest = await copierFichier(cheminSourceFichier, doc.enfantId);
      }

      final map = doc.toMap();
      map.remove('id'); // AUTOINCREMENT
      if (cheminDest != null) map['chemin_fichier'] = cheminDest;

      final db = await DatabaseService.database;
      final id = await db.insert('documents_medicaux', map);
      return id.toString();
    } catch (e) {
      dev.log('DocumentService.ajouterDocument error: $e');
      return null;
    }
  }

  /// Met à jour les métadonnées d'un document existant.
  /// Le fichier local n'est pas modifié.
  static Future<void> mettreAJour(DocumentMedicalModel doc) async {
    try {
      final db = await DatabaseService.database;
      final map = doc.toMap();
      map.remove('id');
      map.remove('created_at');
      await db.update(
        'documents_medicaux',
        map,
        where: 'id = ?',
        whereArgs: [int.parse(doc.id)],
      );
    } catch (e) {
      dev.log('DocumentService.mettreAJour error: $e');
    }
  }

  /// Active ou désactive le partage d'un document avec le pédiatre.
  static Future<void> togglePartage(String docId, bool partage) async {
    try {
      final db = await DatabaseService.database;
      await db.update(
        'documents_medicaux',
        {'partage_pediatre': partage ? 1 : 0},
        where: 'id = ?',
        whereArgs: [int.parse(docId)],
      );
    } catch (e) {
      dev.log('DocumentService.togglePartage error: $e');
    }
  }

  /// Supprime un document et son fichier local associé.
  static Future<void> supprimerDocument(DocumentMedicalModel doc) async {
    try {
      await supprimerFichier(doc.cheminFichier);
      final db = await DatabaseService.database;
      await db.delete(
        'documents_medicaux',
        where: 'id = ?',
        whereArgs: [int.parse(doc.id)],
      );
    } catch (e) {
      dev.log('DocumentService.supprimerDocument error: $e');
    }
  }

  /// Nombre total de documents pour un enfant.
  static Future<int> compterDocuments(String enfantId) async {
    try {
      final db = await DatabaseService.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) FROM documents_medicaux WHERE enfant_id = ?',
        [int.parse(enfantId)],
      );
      return (result.first.values.first as int?) ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
