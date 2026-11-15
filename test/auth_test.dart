import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:datagroo/core/l10n/app_language.dart';
import 'package:datagroo/core/l10n/catalog_translations.dart';
import 'package:datagroo/core/services/auth_service.dart';

// Pruebas de cuentas e idioma sin interfaz. Van en un archivo aparte de las
// pruebas de pantallas porque usan la base de datos real (sqflite ffi).
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AuthService.currentUser.value = null;
    AppLanguage.code.value = 'es';
  });

  test('Registro, inicio de sesión y errores de autenticación', () async {
    final email = 'prueba${DateTime.now().microsecondsSinceEpoch}@datagroo.test';

    await AuthService.register(username: 'Agricultor', email: email, password: 'secreto123');
    expect(AuthService.currentUser.value?.username, 'Agricultor');
    expect(AuthService.currentUser.value?.email, email);
    expect(AuthService.currentUser.value?.isGuest, isFalse);

    // El correo no se puede registrar dos veces.
    await expectLater(
      AuthService.register(username: 'Otro', email: email.toUpperCase(), password: 'secreto123'),
      throwsA(isA<AuthException>()),
    );

    await AuthService.logout();
    expect(AuthService.currentUser.value, isNull);

    await expectLater(
      AuthService.login(email: email, password: 'incorrecta'),
      throwsA(isA<AuthException>()),
    );
    await expectLater(
      AuthService.login(email: 'nadie@datagroo.test', password: 'secreto123'),
      throwsA(isA<AuthException>()),
    );
    expect(AuthService.currentUser.value, isNull);

    await AuthService.login(email: email, password: 'secreto123');
    expect(AuthService.currentUser.value?.username, 'Agricultor');

    // La sesión se recupera al reabrir la app.
    AuthService.currentUser.value = null;
    await AuthService.restoreSession();
    expect(AuthService.currentUser.value?.email, email);

    // La contraseña no se guarda en claro.
    final db = await databaseFactory.openDatabase(
      '${await databaseFactory.getDatabasesPath()}/datagroo.db',
    );
    final rows = await db.query('users', where: 'email = ?', whereArgs: [email]);
    expect(rows.single['password_hash'], isNot(contains('secreto123')));
    expect(rows.single['salt'], isNotEmpty);
  });

  test('Validaciones del registro', () async {
    Future<void> invalid(String user, String mail, String pass) => expectLater(
          AuthService.register(username: user, email: mail, password: pass),
          throwsA(isA<AuthException>()),
        );
    await invalid('ab', 'a@b.co', 'secreto123');
    await invalid('Agricultor', 'no-es-correo', 'secreto123');
    await invalid('Agricultor', 'a@b.co', '123');
  });

  test('El catálogo de la base de datos se traduce al mostrarlo', () {
    expect(trDb('Maíz criollo'), 'Maíz criollo');
    AppLanguage.code.value = 'en';
    expect(trDb('Maíz criollo'), 'Native corn');
    expect(trDb('14°C a 28°C'), '14°C to 28°C');
    expect(trDb('Mi cultivo propio'), 'Mi cultivo propio');
    expect(matchesCatalogText('Maíz criollo', 'corn'), isTrue);
  });
}
