import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

class AuthService {
  static const _userKey = 'logged_user';

  // ── Inscription ──────────────────────────────────────────
  static Future<String?> signup({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final db = await DatabaseService.database;

      // Vérifier doublon email
      final existing = await db.query('users', where: 'email = ?', whereArgs: [email]);
      if (existing.isNotEmpty) return 'Un compte avec cet email existe déjà.';

      await db.insert('users', {
        'name': name,
        'email': email.trim(),
        'password': password, // En prod, utiliser un hash (bcrypt non dispo nativement)
        'role': role,
      });
      return null; // pas d'erreur
    } catch (_) {
      return 'Erreur lors de l\'inscription.';
    }
  }

  // ── Connexion ─────────────────────────────────────────────
  static Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    try {
      final db = await DatabaseService.database;
      final rows = await db.query(
        'users',
        where: 'email = ? AND password = ?',
        whereArgs: [email.trim(), password],
      );
      if (rows.isEmpty) return null;

      final user = Map<String, dynamic>.from(rows.first);
      user.remove('password'); // ne jamais stocker le mot de passe en session

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user));
      return user;
    } catch (_) {
      return null;
    }
  }

  // ── Déconnexion ───────────────────────────────────────────
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  // ── Utilisateur connecté ──────────────────────────────────
  static Future<Map<String, dynamic>?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // ── Mise à jour du profil ──────────────────────────────────────────────────
  /// Met à jour les informations du profil dans la base et rafraîchit la
  /// session stockée dans SharedPreferences.
  /// Retourne null si succès, ou un message d'erreur.
  static Future<String?> updateProfil({
    required String userId,
    required String name,
    String? telephone,
    String? adresse,
    String? specialite,
  }) async {
    try {
      final db = await DatabaseService.database;
      final updates = <String, dynamic>{
        'name': name.trim(),
        if (telephone != null) 'telephone': telephone.trim(),
        if (adresse != null) 'adresse': adresse.trim(),
        if (specialite != null) 'specialite': specialite.trim(),
      };
      await db.update('users', updates,
          where: 'id = ?', whereArgs: [int.parse(userId)]);

      // Rafraîchir la session locale
      final rows = await db.query('users',
          where: 'id = ?', whereArgs: [int.parse(userId)]);
      if (rows.isNotEmpty) {
        final user = Map<String, dynamic>.from(rows.first);
        user.remove('password');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(user));
      }
      return null;
    } catch (_) {
      return 'Erreur lors de la mise à jour du profil.';
    }
  }

  // ── Changement de mot de passe ────────────────────────────────────────────
  /// Vérifie l'ancien mot de passe puis le remplace.
  /// Retourne null si succès, ou un message d'erreur.
  static Future<String?> changerMotDePasse({
    required String userId,
    required String ancienMdp,
    required String nouveauMdp,
  }) async {
    try {
      final db = await DatabaseService.database;
      final rows = await db.query('users',
          where: 'id = ? AND password = ?',
          whereArgs: [int.parse(userId), ancienMdp]);
      if (rows.isEmpty) return 'Mot de passe actuel incorrect.';
      await db.update('users', {'password': nouveauMdp},
          where: 'id = ?', whereArgs: [int.parse(userId)]);
      return null;
    } catch (_) {
      return 'Erreur lors du changement de mot de passe.';
    }
  }
}
