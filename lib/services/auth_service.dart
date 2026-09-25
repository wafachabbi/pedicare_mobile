import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AuthService {
  static Future<File> _getUsersFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/users.json');
  }

  static Future<File> _getSessionFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/session.json');
  }

  static Future<Map<String, dynamic>> _readUsers() async {
    try {
      final file = await _getUsersFile();
      if (!await file.exists()) return {};
      final content = await file.readAsString();
      return Map<String, dynamic>.from(jsonDecode(content));
    } catch (_) {
      return {};
    }
  }

  static Future<void> _writeUsers(Map<String, dynamic> users) async {
    final file = await _getUsersFile();
    await file.writeAsString(jsonEncode(users));
  }

  // role = 'parent' ou 'pediatre'
  static Future<String?> signup({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final users = await _readUsers();
    if (users.containsKey(email)) {
      return 'Un compte avec cet email existe déjà.';
    }
    users[email] = {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    };
    await _writeUsers(users);
    return null;
  }

  static Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    final users = await _readUsers();
    final user = users[email];
    if (user == null || user['password'] != password) return null;
    final sessionFile = await _getSessionFile();
    await sessionFile.writeAsString(jsonEncode(user));
    return Map<String, dynamic>.from(user);
  }

  static Future<void> logout() async {
    final file = await _getSessionFile();
    if (await file.exists()) await file.delete();
  }

  static Future<Map<String, dynamic>?> getLoggedInUser() async {
    try {
      final file = await _getSessionFile();
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      return Map<String, dynamic>.from(jsonDecode(content));
    } catch (_) {
      return null;
    }
  }
}
