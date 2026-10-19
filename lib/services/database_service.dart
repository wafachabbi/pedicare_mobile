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
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

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
  }
}
