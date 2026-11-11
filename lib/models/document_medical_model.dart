/// Catégories de documents médicaux.
enum CategorieDocument {
  ordonnance('ordonnance', '📋', 'Ordonnance'),
  resultat('resultat', '🔬', 'Résultat d\'analyse'),
  compteRendu('compte_rendu', '📄', 'Compte-rendu'),
  radio('radio', '🩻', 'Radiologie / Imagerie'),
  vaccin('vaccin', '💉', 'Carnet vaccinal'),
  autre('autre', '📎', 'Autre');

  final String code;
  final String emoji;
  final String label;
  const CategorieDocument(this.code, this.emoji, this.label);

  static CategorieDocument fromCode(String? code) {
    return CategorieDocument.values.firstWhere(
      (c) => c.code == code,
      orElse: () => CategorieDocument.autre,
    );
  }
}

class DocumentMedicalModel {
  final String id;
  final String enfantId;
  final String parentId;
  final String titre;
  final CategorieDocument categorie;
  final DateTime dateDocument;
  final String? medecin;
  final String? etablissement;
  final String? notes;

  /// Chemin local vers le fichier copié dans le répertoire de l'app.
  final String? cheminFichier;

  /// Texte extrait par OCR (ordonnances).
  final String? texteOcr;

  /// Données structurées extraites de l'ordonnance via OCR.
  final String? medicament;
  final String? posologie;
  final String? prescripteur;

  /// Le document est-il accessible par le pédiatre désigné ?
  final bool partagePediatre;

  final DateTime createdAt;

  DocumentMedicalModel({
    required this.id,
    required this.enfantId,
    required this.parentId,
    required this.titre,
    required this.categorie,
    required this.dateDocument,
    this.medecin,
    this.etablissement,
    this.notes,
    this.cheminFichier,
    this.texteOcr,
    this.medicament,
    this.posologie,
    this.prescripteur,
    this.partagePediatre = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // ── Sérialisation ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'id': id,
        'enfant_id': enfantId,
        'parent_id': parentId,
        'titre': titre,
        'categorie': categorie.code,
        'date_document': dateDocument.toIso8601String().split('T')[0],
        'medecin': medecin,
        'etablissement': etablissement,
        'notes': notes,
        'chemin_fichier': cheminFichier,
        'texte_ocr': texteOcr,
        'medicament': medicament,
        'posologie': posologie,
        'prescripteur': prescripteur,
        'partage_pediatre': partagePediatre ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory DocumentMedicalModel.fromMap(Map<String, dynamic> map) {
    return DocumentMedicalModel(
      id: map['id']?.toString() ?? '',
      enfantId: map['enfant_id']?.toString() ?? '',
      parentId: map['parent_id']?.toString() ?? '',
      titre: map['titre'] ?? '',
      categorie: CategorieDocument.fromCode(map['categorie']),
      dateDocument: _parseDate(map['date_document']),
      medecin: map['medecin'],
      etablissement: map['etablissement'],
      notes: map['notes'],
      cheminFichier: map['chemin_fichier'],
      texteOcr: map['texte_ocr'],
      medicament: map['medicament'],
      posologie: map['posologie'],
      prescripteur: map['prescripteur'],
      partagePediatre: _bool(map['partage_pediatre']),
      createdAt: _parseDate(map['created_at']),
    );
  }

  DocumentMedicalModel copyWith({
    String? titre,
    CategorieDocument? categorie,
    DateTime? dateDocument,
    String? medecin,
    String? etablissement,
    String? notes,
    String? cheminFichier,
    String? texteOcr,
    String? medicament,
    String? posologie,
    String? prescripteur,
    bool? partagePediatre,
  }) =>
      DocumentMedicalModel(
        id: id,
        enfantId: enfantId,
        parentId: parentId,
        titre: titre ?? this.titre,
        categorie: categorie ?? this.categorie,
        dateDocument: dateDocument ?? this.dateDocument,
        medecin: medecin ?? this.medecin,
        etablissement: etablissement ?? this.etablissement,
        notes: notes ?? this.notes,
        cheminFichier: cheminFichier ?? this.cheminFichier,
        texteOcr: texteOcr ?? this.texteOcr,
        medicament: medicament ?? this.medicament,
        posologie: posologie ?? this.posologie,
        prescripteur: prescripteur ?? this.prescripteur,
        partagePediatre: partagePediatre ?? this.partagePediatre,
        createdAt: createdAt,
      );

  // ── Helpers ───────────────────────────────────────────────────────────────

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  static bool _bool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    return v?.toString() == '1' || v?.toString().toLowerCase() == 'true';
  }

  /// Vrai si le document possède un fichier local accessible.
  bool get aFichier => cheminFichier != null && cheminFichier!.isNotEmpty;

  /// Vrai si l'OCR a produit du texte.
  bool get aOcr => texteOcr != null && texteOcr!.trim().isNotEmpty;

  /// Vrai si les données structurées de l'ordonnance sont présentes.
  bool get aStructureOrdonnance =>
      medicament != null && medicament!.trim().isNotEmpty;
}
