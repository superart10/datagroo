import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:datagroo/core/l10n/app_language.dart';
import 'package:datagroo/core/services/auth_service.dart';
import 'package:datagroo/features/auth/screens/login_screen.dart';
import 'package:datagroo/features/splash/splash_screen.dart';
import 'package:datagroo/main.dart';

/// Abre la app y avanza hasta que termina la pantalla de carga.
Future<void> pumpPastSplash(WidgetTester tester) async {
  await tester.pumpWidget(const DatagrooApp());
  expect(find.byType(SplashScreen), findsOneWidget);
  await tester.pump(SplashScreen.minimumVisible);
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
}

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

  testWidgets('Pantalla de carga, luego inicio de sesión; invitado entra a la app', (tester) async {
    await pumpPastSplash(tester);

    // Sin sesión guardada: se muestra el inicio de sesión con correo y contraseña.
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Correo'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Nombre de usuario'), findsNothing);

    await tester.tap(find.text('Entrar como invitado'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Pantalla principal con la barra de navegación.
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Clima'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    expect(AuthService.currentUser.value?.isGuest, isTrue);

    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pump();
    expect(find.text('Mis Terrenos'), findsWidgets);
    expect(find.byIcon(Icons.add_location_alt), findsWidgets);
  });

  testWidgets('El formulario de registro pide usuario, correo y contraseña', (tester) async {
    await pumpPastSplash(tester);

    await tester.tap(find.text('¿No tienes cuenta? Regístrate'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Nombre de usuario'), findsOneWidget);
    expect(find.text('Correo'), findsWidgets);
    expect(find.text('Contraseña'), findsWidgets);
    expect(find.text('Registrarme'), findsOneWidget);
  });

  testWidgets('Cambiar el idioma traduce la app completa y cerrar sesión vuelve al inicio de sesión', (tester) async {
    await pumpPastSplash(tester);
    await tester.tap(find.text('Entrar como invitado'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Inicio'), findsOneWidget);

    await AppLanguage.set('en');
    await tester.pump();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Inicio'), findsNothing);
    expect(find.text('Weather'), findsOneWidget);
    expect(find.text('Welcome to the field!'), findsOneWidget);

    // El idioma queda guardado para la próxima vez que se abra la app.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_language'), 'en');

    await AuthService.logout();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Continue as guest'), findsOneWidget);

    await AppLanguage.set('es');
    await tester.pump();
    expect(find.text('Entrar como invitado'), findsOneWidget);
  });
}
