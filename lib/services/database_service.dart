import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pedicare.db');
    return openDatabase(
      path,
      version: 2, // v2 : ajout module Éveil + Messagerie (Arij)
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ── Création complète (nouvelle installation) ─────────────────────────────
  static Future<void> _onCreate(Database db, int version) async {
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

    // Tables ajoutées en v2
    await _createTablesV2(db);
  }

  // ── Mise à jour d'une base existante ──────────────────────────────────────
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createTablesV2(db);
    }
  }

  // ── v2 : module Éveil & Jeux + Messagerie ─────────────────────────────────
  static Future<void> _createTablesV2(Database db) async {
    // Catalogue des activités éducatives
    await db.execute('''
      CREATE TABLE activites (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        titre         TEXT NOT NULL,
        categorie     TEXT NOT NULL,      -- memoire | langage | motricite | logique
        age_min_mois  INTEGER NOT NULL,
        age_max_mois  INTEGER NOT NULL,
        type_jeu      TEXT NOT NULL,      -- association | memory | activite
        description   TEXT,
        en_famille    INTEGER DEFAULT 0   -- 1 = activité à faire en famille
      )
    ''');

    // Séances de jeu réalisées par un enfant
    await db.execute('''
      CREATE TABLE seances_jeu (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        enfant_id    INTEGER NOT NULL,
        activite_id  INTEGER NOT NULL,
        score        INTEGER DEFAULT 0,   -- en %
        duree_sec    INTEGER DEFAULT 0,
        created_at   TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (enfant_id)   REFERENCES enfants(id)   ON DELETE CASCADE,
        FOREIGN KEY (activite_id) REFERENCES activites(id) ON DELETE CASCADE
      )
    ''');

    // Activités favorites
    await db.execute('''
      CREATE TABLE favoris (
        enfant_id    INTEGER NOT NULL,
        activite_id  INTEGER NOT NULL,
        PRIMARY KEY (enfant_id, activite_id),
        FOREIGN KEY (enfant_id)   REFERENCES enfants(id)   ON DELETE CASCADE,
        FOREIGN KEY (activite_id) REFERENCES activites(id) ON DELETE CASCADE
      )
    ''');

    // Badges obtenus
    await db.execute('''
      CREATE TABLE badges_enfant (
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
      CREATE TABLE messages (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        sender_id    INTEGER NOT NULL,
        receiver_id  INTEGER NOT NULL,
        enfant_id    INTEGER,
        content      TEXT NOT NULL,
        type         TEXT DEFAULT 'texte', -- texte | bilan
        lu           INTEGER DEFAULT 0,
        created_at   TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (sender_id)   REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await _seedActivites(db);
  }

  // ── Catalogue initial d'activités ─────────────────────────────────────────
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