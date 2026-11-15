import 'package:material_ui/material_ui.dart';
import 'package:datagroo/core/l10n/app_language.dart';
import 'package:datagroo/core/services/auth_service.dart';
import 'package:datagroo/features/auth/screens/login_screen.dart';
import 'package:datagroo/features/navigation/main_navigation_screen.dart';
import 'package:datagroo/features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DatagrooApp());
}

class DatagrooApp extends StatelessWidget {
  const DatagrooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DATAGROO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
          surface: const Color(0xFFF5F5F5),
        ),
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      // LanguageScope va por encima del navegador para que todas las pantallas
      // (también las abiertas encima) cambien de idioma al instante.
      builder: (context, child) => LanguageScope(child: child ?? const SizedBox.shrink()),
      home: const AppRoot(),
    );
  }
}

/// Decide qué se muestra: la pantalla de carga al abrir la app y, después,
/// el inicio de sesión o la app según haya sesión activa.
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await Future.wait([
      _loadSavedState(),
      Future<void>.delayed(SplashScreen.minimumVisible),
    ]);
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _loadSavedState() async {
    // Si algo falla al leer lo guardado, la app abre igual: en español y sin sesión.
    try {
      await AppLanguage.load();
      await AuthService.restoreSession();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: !_ready
          ? const SplashScreen(key: ValueKey('splash'))
          : ValueListenableBuilder<AppUser?>(
              key: const ValueKey('app'),
              valueListenable: AuthService.currentUser,
              builder: (context, user, _) {
                if (user == null) return const LoginScreen();
                // La clave reinicia las pestañas al cambiar de usuario.
                return MainNavigationScreen(key: ValueKey('user-${user.id ?? 'guest'}'));
              },
            ),
    );
  }
}
