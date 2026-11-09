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
}
