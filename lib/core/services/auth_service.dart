import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:datagroo/core/l10n/app_language.dart';
import 'package:datagroo/core/services/database_helper.dart';

/// Usuario con sesión activa. Un invitado no tiene `id` ni correo.
class AppUser {
  final int? id;
  final String username;
  final String email;
  final bool isGuest;

  const AppUser({required this.id, required this.username, required this.email}) : isGuest = false;

  const AppUser.guest()
      : id = null,
        username = '',
        email = '',
        isGuest = true;
}

/// Error de registro o inicio de sesión con un mensaje listo para mostrar.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Registro, inicio y cierre de sesión.
///
/// Las cuentas se guardan en el SQLite local (tabla `users`), igual que el resto
/// de los datos de la app. La contraseña nunca se guarda en claro: se guarda su
/// derivación PBKDF2-HMAC-SHA256 con una sal aleatoria por usuario.
class AuthService {
  static const String _sessionUserIdKey = 'session_user_id';
  static const String _sessionGuestKey = 'session_guest';
  static const int _pbkdf2Iterations = 20000;

  /// `null` = sin sesión (se muestra la pantalla de inicio de sesión).
  static final ValueNotifier<AppUser?> currentUser = ValueNotifier<AppUser?>(null);

  /// Recupera la sesión guardada al abrir la app.
  static Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_sessionUserIdKey);
    if (userId != null) {
      final row = await DatabaseHelper.instance.getUserById(userId);
      if (row != null) {
        currentUser.value = _fromRow(row);
        return;
      }
      await prefs.remove(_sessionUserIdKey);
    }
    if (prefs.getBool(_sessionGuestKey) ?? false) {
      currentUser.value = const AppUser.guest();
    }
  }

  static Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final name = username.trim();
    final mail = email.trim().toLowerCase();

    if (name.length < 3) {
      throw AuthException(tr(
        'El nombre de usuario debe tener al menos 3 caracteres.',
        'The username must be at least 3 characters long.',
      ));
    }
    if (!_emailPattern.hasMatch(mail)) {
      throw AuthException(tr('Escribe un correo válido.', 'Enter a valid email address.'));
    }
    if (password.length < 6) {
      throw AuthException(tr(
        'La contraseña debe tener al menos 6 caracteres.',
        'The password must be at least 6 characters long.',
      ));
    }
    if (await DatabaseHelper.instance.getUserByEmail(mail) != null) {
      throw AuthException(tr(
        'Ya existe una cuenta con ese correo.',
        'An account with that email already exists.',
      ));
    }

    final salt = _newSalt();
    final id = await DatabaseHelper.instance.insertUser({
      'username': name,
      'email': mail,
      'password_hash': await _hashPassword(password, salt),
      'salt': salt,
    });
    await _saveSession(userId: id);
    currentUser.value = AppUser(id: id, username: name, email: mail);
  }

  static Future<void> login({required String email, required String password}) async {
    final mail = email.trim().toLowerCase();
    if (mail.isEmpty || password.isEmpty) {
      throw AuthException(tr('Escribe tu correo y tu contraseña.', 'Enter your email and password.'));
    }

    final row = await DatabaseHelper.instance.getUserByEmail(mail);
    // El mismo mensaje si falla el correo o la contraseña, para no revelar
    // qué correos tienen cuenta.
    final invalid = AuthException(tr('Correo o contraseña incorrectos.', 'Incorrect email or password.'));
    if (row == null) throw invalid;

    final expected = row['password_hash'] as String;
    final actual = await _hashPassword(password, row['salt'] as String);
    if (actual != expected) throw invalid;

    await _saveSession(userId: row['id'] as int);
    currentUser.value = _fromRow(row);
  }

  static Future<void> enterAsGuest() async {
    await _saveSession(guest: true);
    currentUser.value = const AppUser.guest();
  }

  static Future<void> logout() async {
    await _saveSession();
    currentUser.value = null;
  }

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static AppUser _fromRow(Map<String, dynamic> row) => AppUser(
        id: row['id'] as int,
        username: row['username'] as String,
        email: row['email'] as String,
      );

  static Future<void> _saveSession({int? userId, bool guest = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId != null) {
      await prefs.setInt(_sessionUserIdKey, userId);
    } else {
      await prefs.remove(_sessionUserIdKey);
    }
    await prefs.setBool(_sessionGuestKey, guest);
  }

  static String _newSalt() {
    final random = Random.secure();
    return base64Encode(List<int>.generate(16, (_) => random.nextInt(256)));
  }

  static Future<String> _hashPassword(String password, String salt) {
    // `compute` saca el cálculo del hilo de la interfaz (en web corre en el mismo hilo).
    return compute(_pbkdf2, [password, salt, _pbkdf2Iterations]);
  }
}

/// PBKDF2-HMAC-SHA256 de un bloque (32 bytes), en base64.
String _pbkdf2(List<Object> args) {
  final password = args[0] as String;
  final salt = base64Decode(args[1] as String);
  final iterations = args[2] as int;

  final hmac = Hmac(sha256, utf8.encode(password));
  var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
  final result = Uint8List.fromList(u);
  for (var i = 1; i < iterations; i++) {
    u = hmac.convert(u).bytes;
    for (var j = 0; j < result.length; j++) {
      result[j] ^= u[j];
    }
  }
  return base64Encode(result);
}
