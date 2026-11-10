import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _db;

  /// Version 4 : partage du journal des symptômes avec le pédiatre.
  /// Version 2 : ajout du journal des symptômes, des résumés de consultation
  /// et des traitements (Module 3 & Module 10).
  /// Version 4 : nouvelle colonne pediatre_id dans la table enfants
  /// Version 5 : table journal_alimentaire pour Module 9
  /// Version 6 : Module 5 (PediPharma) et Module 9 (Nutrition) :
  ///   traitements.medecin / heures / rappels, journal_alimentaire.aliments,
  ///   tables prises_medicament, allergies_alimentaires, allaitements.
  /// Version 7 : table conseils_nutrition (consignes rédigées par le pédiatre).
  /// Version 8 : assistant IA (tables conversations_ia, messages_ia).
  /// Version 9 : RAG de l'assistant (cache rag_embeddings, sources citées).
  /// Version 10 : Module 3 — observations saisies par le pédiatre pendant la
  ///   consultation (table observations_consultation) et lien
  ///   consultations.observation_id vers le résumé IA généré par le parent.
  /// Version 11 : Module Éveil & Jeux (activites, seances_jeu, favoris,
  ///   badges_enfant) et Module Communication (messages parent ↔ pédiatre).
  static const int _version = 11;

  static Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pedicare.db');
    return openDatabase(
      path,
      version: _version,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// SQLite désactive les clés étrangères par défaut : sans ce PRAGMA,
  /// les « ON DELETE CASCADE » sont ignorés et supprimer un enfant laisse
  /// son journal, ses consultations, etc. orphelins.
  static Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Création de la base de données (première installation).
  static Future<void> _onCreate(Database db, int version) async {
    await _createBaseTables(db);
    await _createModuleTables(db);
    await _createEveilCommunicationTables(db);
  }

  /// Migration non destructive pour les installations existantes.
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // On ajoute toujours les colonnes nécessaires, même si la version semble à jour
    try {
      await db.execute(
        'ALTER TABLE enfants ADD COLUMN partage_journal INTEGER NOT NULL DEFAULT 0',
      );
    } catch (_) {
      // Colonne déjà existante, c'est normal
    }
    try {
      await db.execute(
        'ALTER TABLE enfants ADD COLUMN pediatre_id TEXT',
      );
    } catch (_) {
      // Colonne déjà existante, c'est normal
    }
    try {
      await db.execute(
        'ALTER TABLE enfants ADD COLUMN allergies TEXT',
      );
    } catch (_) {
      // Colonne déjà existante, c'est normal
    }
    // Colonnes ajoutées en v6 (Modules 5 et 9).
    for (final sql in const [
      'ALTER TABLE traitements ADD COLUMN medecin TEXT',
      'ALTER TABLE traitements ADD COLUMN heures TEXT',
      'ALTER TABLE traitements ADD COLUMN rappels INTEGER NOT NULL DEFAULT 1',
      'ALTER TABLE journal_alimentaire ADD COLUMN aliments TEXT',
      'ALTER TABLE messages_ia ADD COLUMN sources TEXT',
    ]) {
      try {
        await db.execute(sql);
      } catch (_) {
        // Colonne déjà existante ou table créée juste après : normal.
      }
    }
    // Tables des modules 3, 5, 9 et 10 (journal_symptomes, consultations,
    // traitements, journal_alimentaire) : toutes en IF NOT EXISTS, donc sans
    // effet si elles existent déjà.
    await _createModuleTables(db);
    // v10 : lien entre un résumé IA et la consultation du pédiatre.
    try {
      await db.execute(
          'ALTER TABLE consultations ADD COLUMN observation_id INTEGER');
    } catch (_) {
      // Colonne déjà existante : normal.
    }
    // v11 : Éveil & Jeux + Messagerie (IF NOT EXISTS → sans effet si déjà là).
    await _createEveilCommunicationTables(db);
  }

  // ── Tables des modules existants ───────────────────────────────────────────
  static Future<void> _createBaseTables(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        name      TEXT NOT NULL,
        email     TEXT NOT NULL UNIQUE,
        password  TEXT NOT NULL,
        role      TEXT NOT NULL DEFAULT 'parent',
        specialite TEXT,
        telephone  TEXT,
        adresse    TEXT,
        created_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE enfants (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        parent_id      INTEGER NOT NULL,
        nom            TEXT NOT NULL,
        prenom         TEXT NOT NULL,
        date_naissance TEXT NOT NULL,
        sexe           TEXT NOT NULL,
        groupe_sanguin TEXT,
        allergies      TEXT,
        partage_journal INTEGER NOT NULL DEFAULT 0,
        created_at     TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (parent_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE vaccins (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        enfant_id       INTEGER NOT NULL,
        nom             TEXT NOT NULL,
        maladie         TEXT NOT NULL,
        date_administre TEXT NOT NULL,
        medecin         TEXT,
        lieu            TEXT,
        lot_numero      TEXT,
        prochaine_date  TEXT,
        notes           TEXT,
        created_at      TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (enfant_id) REFERENCES enfants(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE rendezvous (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        enfant_id    INTEGER NOT NULL,
        pediatre_id  INTEGER,
        titre        TEXT NOT NULL,
        medecin      TEXT,
        specialite   TEXT,
        lieu         TEXT,
        date_heure   TEXT NOT NULL,
        statut       TEXT DEFAULT 'enAttente',
        type         TEXT DEFAULT 'presentiel',
        notes        TEXT,
        created_at   TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (enfant_id)  REFERENCES enfants(id) ON DELETE CASCADE,
        FOREIGN KEY (pediatre_id) REFERENCES users(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE croissance (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        enfant_id         INTEGER NOT NULL,
        date_mesure       TEXT NOT NULL,
        poids             REAL NOT NULL,
        taille            REAL NOT NULL,
        perimetre_cranien REAL,
        notes             TEXT,
        created_at        TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (enfant_id) REFERENCES enfants(id) ON DELETE CASCADE
      )
    ''');
  }

  // ── Tables Module 3 (dashboard / consultation) & Module 9 (nutrition) ───────
  static Future<void> _createModuleTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS journal_symptomes (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        enfant_id    INTEGER NOT NULL,
        date         TEXT NOT NULL,
        temperature  REAL,
        toux         TEXT DEFAULT 'aucune',
        comportement TEXT DEFAULT 'normal',
        sommeil      TEXT DEFAULT 'bon',
        appetit      TEXT DEFAULT 'normal',
        symptomes    TEXT,
        notes        TEXT,
        created_at   TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (enfant_id) REFERENCES enfants(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS consultations (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        enfant_id     INTEGER NOT NULL,
        titre         TEXT NOT NULL,
        resume        TEXT NOT NULL,
        points_cles   TEXT,
        suggestions   TEXT,
        periode_debut TEXT,
        periode_fin   TEXT,
        nb_entrees    INTEGER DEFAULT 0,
        generee_ia    INTEGER DEFAULT 0,
        observation_id INTEGER,
        created_at    TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (enfant_id) REFERENCES enfants(id) ON DELETE CASCADE
      )
    ''');

    // Module 3 : données saisies par le pédiatre pendant la consultation.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS observations_consultation (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        enfant_id         INTEGER NOT NULL,
        pediatre_id       TEXT,
        pediatre_nom      TEXT,
        date_consultation TEXT NOT NULL,
        motif             TEXT NOT NULL,
        poids             REAL,
        taille            REAL,
        temperature       REAL,
        observations      TEXT,
        diagnostic        TEXT,
        traitement        TEXT,
        recommandations   TEXT,
        created_at        TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (enfant_id) REFERENCES enfants(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS traitements (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        enfant_id   INTEGER NOT NULL,
        nom         TEXT NOT NULL,
        posologie   TEXT,
        frequence   TEXT,
        date_debut  TEXT NOT NULL,
        date_fin    TEXT,
        notes       TEXT,
        medecin     TEXT,
        heures      TEXT,
        rappels     INTEGER NOT NULL DEFAULT 1,
        created_at  TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (enfant_id) REFERENCES enfants(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS journal_alimentaire (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        enfant_id       INTEGER NOT NULL,
        date            TEXT NOT NULL,
        repas           TEXT,
        quantite        TEXT,
        heure           TEXT,
        notes           TEXT,
        age_mois        INTEGER,
        aliments        TEXT,
        created_at      TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (enfant_id) REFERENCES enfants(id) ON DELETE CASCADE
      )
    ''');

    // ── Module 5 : historique des prises de médicaments ──
    await db.execute('''
      CREATE TABLE IF NOT EXISTS prises_medicament (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        traitement_id INTEGER NOT NULL,
        enfant_id     INTEGER NOT NULL,
        date_prevue   TEXT NOT NULL,
        statut        TEXT NOT NULL,
        date_action   TEXT NOT NULL,
        UNIQUE (traitement_id, date_prevue),
        FOREIGN KEY (traitement_id) REFERENCES traitements(id) ON DELETE CASCADE,
        FOREIGN KEY (enfant_id) REFERENCES enfants(id) ON DELETE CASCADE
      )
    ''');

    // ── Module 9 : allergies alimentaires ──
    await db.execute('''
      CREATE TABLE IF NOT EXISTS allergies_alimentaires (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        enfant_id  INTEGER NOT NULL,
        allergene  TEXT NOT NULL,
        severite   TEXT NOT NULL DEFAULT 'moderee',
        reaction   TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (enfant_id) REFERENCES enfants(id) ON DELETE CASCADE
      )
    ''');

    // ── IA globale (Molka) : conversations avec l'assistant pédiatrique ──
    await db.execute('''
      CREATE TABLE IF NOT EXISTS conversations_ia (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        enfant_id  INTEGER NOT NULL,
        titre      TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (enfant_id) REFERENCES enfants(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS messages_ia (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        conversation_id INTEGER NOT NULL,
        auteur          TEXT NOT NULL,
        texte           TEXT NOT NULL,
        urgent          INTEGER NOT NULL DEFAULT 0,
        par_ia          INTEGER NOT NULL DEFAULT 0,
        sources         TEXT,
        created_at      TEXT NOT NULL,
        FOREIGN KEY (conversation_id) REFERENCES conversations_ia(id) ON DELETE CASCADE
      )
    ''');

    // ── RAG : cache des vecteurs (embeddings) des passages ──
    await db.execute('''
      CREATE TABLE IF NOT EXISTS rag_embeddings (
        passage_id TEXT PRIMARY KEY,
        modele     TEXT,
        empreinte  TEXT NOT NULL,
        vecteur    TEXT NOT NULL
      )
    ''');

    // ── Module 9 : consignes alimentaires rédigées par le pédiatre ──
    await db.execute('''
      CREATE TABLE IF NOT EXISTS conseils_nutrition (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        enfant_id   INTEGER NOT NULL,
        pediatre_id INTEGER,
        auteur      TEXT,
        texte       TEXT NOT NULL,
        created_at  TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (enfant_id) REFERENCES enfants(id) ON DELETE CASCADE,
        FOREIGN KEY (pediatre_id) REFERENCES users(id) ON DELETE SET NULL
      )
    ''');

    // ── Module 9 : suivi de l'allaitement ──
    await db.execute('''
      CREATE TABLE IF NOT EXISTS allaitements (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        enfant_id     INTEGER NOT NULL,
        date          TEXT NOT NULL,
        type          TEXT NOT NULL,
        duree_minutes INTEGER,
        quantite_ml   INTEGER,
        notes         TEXT,
        created_at    TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (enfant_id) REFERENCES enfants(id) ON DELETE CASCADE
      )
    ''');
  }

  // ── v11 : Module Éveil & Jeux + Module Communication (Arij) ────────────────
  static Future<void> _createEveilCommunicationTables(Database db) async {
    // Catalogue des activités éducatives
    await db.execute('''
      CREATE TABLE IF NOT EXISTS activites (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        titre         TEXT NOT NULL,
        categorie     TEXT NOT NULL,      -- memoire | langage | motricite | logique
        age_min_mois  INTEGER NOT NULL,
        age_max_mois  INTEGER NOT NULL,
        type_jeu      TEXT NOT NULL,      -- association | memory | activite
        description   TEXT,
        en_famille    INTEGER DEFAULT 0
      )
    ''');

    // Séances de jeu réalisées par un enfant
    await db.execute('''
      CREATE TABLE IF NOT EXISTS seances_jeu (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        enfant_id    INTEGER NOT NULL,
        activite_id  INTEGER NOT NULL,
        score        INTEGER DEFAULT 0,
        duree_sec    INTEGER DEFAULT 0,
        created_at   TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (enfant_id)   REFERENCES enfants(id)   ON DELETE CASCADE,
        FOREIGN KEY (activite_id) REFERENCES activites(id) ON DELETE CASCADE
      )
    ''');

    // Activités favorites
    await db.execute('''
      CREATE TABLE IF NOT EXISTS favoris (
        enfant_id    INTEGER NOT NULL,
        activite_id  INTEGER NOT NULL,
        PRIMARY KEY (enfant_id, activite_id),
        FOREIGN KEY (enfant_id)   REFERENCES enfants(id)   ON DELETE CASCADE,
        FOREIGN KEY (activite_id) REFERENCES activites(id) ON DELETE CASCADE
      )
    ''');

    // Badges obtenus
    await db.execute('''
      CREATE TABLE IF NOT EXISTS badges_enfant (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        enfant_id   INTEGER NOT NULL,
        code_badge  TEXT NOT NULL,
        obtenu_le   TEXT DEFAULT (datetime('now')),
        UNIQUE (enfant_id, code_badge),
        FOREIGN KEY (enfant_id) REFERENCES enfants(id) ON DELETE CASCADE
      )
    ''');

    // Messagerie parent ↔ pédiatre
    await db.execute('''
      CREATE TABLE IF NOT EXISTS messages (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        sender_id    INTEGER NOT NULL,
        receiver_id  INTEGER NOT NULL,
        enfant_id    INTEGER,
        content      TEXT NOT NULL,
        type         TEXT DEFAULT 'texte',  -- texte | bilan
        lu           INTEGER DEFAULT 0,
        created_at   TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (sender_id)   REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Catalogue initial : seulement si la table est vide
    final n = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM activites'));
    if ((n ?? 0) == 0) await _seedActivites(db);
  }

  static Future<void> _seedActivites(Database db) async {
    final activites = [
      // Langage
      {'titre': 'Associe l\'image au mot', 'categorie': 'langage', 'age_min_mois': 24, 'age_max_mois': 48, 'type_jeu': 'association', 'description': 'Relie chaque image (animaux) au bon mot.', 'en_famille': 0},
      {'titre': 'Les fruits et leurs noms', 'categorie': 'langage', 'age_min_mois': 36, 'age_max_mois': 72, 'type_jeu': 'association', 'description': 'Associe chaque fruit à son nom.', 'en_famille': 0},
      {'titre': 'Raconte ta journée', 'categorie': 'langage', 'age_min_mois': 24, 'age_max_mois': 72, 'type_jeu': 'activite', 'description': 'Le soir, demandez à l\'enfant de raconter 3 moments de sa journée.', 'en_famille': 1},
      // Mémoire
      {'titre': 'Memory des animaux', 'categorie': 'memoire', 'age_min_mois': 30, 'age_max_mois': 60, 'type_jeu': 'memory', 'description': 'Retrouve les paires de cartes identiques (6 cartes).', 'en_famille': 0},
      {'titre': 'Memory des formes', 'categorie': 'memoire', 'age_min_mois': 48, 'age_max_mois': 84, 'type_jeu': 'memory', 'description': 'Retrouve les paires de formes (12 cartes).', 'en_famille': 0},
      {'titre': 'Qu\'est-ce qui a disparu ?', 'categorie': 'memoire', 'age_min_mois': 36, 'age_max_mois': 72, 'type_jeu': 'activite', 'description': 'Posez 4 objets, cachez-en un : l\'enfant devine lequel.', 'en_famille': 1},
      // Logique
      {'titre': 'Les couleurs', 'categorie': 'logique', 'age_min_mois': 18, 'age_max_mois': 48, 'type_jeu': 'association', 'description': 'Associe chaque objet à sa couleur.', 'en_famille': 0},
      {'titre': 'Trier les jouets', 'categorie': 'logique', 'age_min_mois': 24, 'age_max_mois': 60, 'type_jeu': 'activite', 'description': 'Triez ensemble les jouets par couleur, puis par taille.', 'en_famille': 1},
      // Motricité
      {'titre': 'Pâte à modeler', 'categorie': 'motricite', 'age_min_mois': 24, 'age_max_mois': 72, 'type_jeu': 'activite', 'description': 'Faire des boules et des serpents pour muscler les doigts.', 'en_famille': 1},
      {'titre': 'Parcours de coussins', 'categorie': 'motricite', 'age_min_mois': 18, 'age_max_mois': 60, 'type_jeu': 'activite', 'description': 'Créez un petit parcours à enjamber dans le salon.', 'en_famille': 1},
    ];
    for (final a in activites) {
      await db.insert('activites', a);
    }
  }
}