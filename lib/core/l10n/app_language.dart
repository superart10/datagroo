import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Idioma de la aplicación (español o inglés), guardado en el dispositivo.
class AppLanguage {
  static const String _prefsKey = 'app_language';

  /// 'es' o 'en'.
  static final ValueNotifier<String> code = ValueNotifier<String>('es');

  static bool get isEnglish => code.value == 'en';

  /// Lee el idioma guardado. Se llama una vez al iniciar la app.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == 'es' || saved == 'en') code.value = saved!;
  }

  static Future<void> set(String newCode) async {
    if (newCode != 'es' && newCode != 'en') return;
    code.value = newCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, newCode);
  }

  /// Hace que el widget se reconstruya cuando cambia el idioma.
  /// Se llama al inicio del `build` de cada pantalla.
  static void watch(BuildContext context) {
    context.dependOnInheritedWidgetOfExactType<LanguageScope>();
  }
}

/// Texto en el idioma activo: `tr('Guardar', 'Save')`.
String tr(String es, String en) => AppLanguage.isEnglish ? en : es;

/// Se coloca por encima del navegador (en `MaterialApp.builder`) para que todas
/// las pantallas que llaman a [AppLanguage.watch] se actualicen al cambiar el idioma.
class LanguageScope extends InheritedNotifier<ValueNotifier<String>> {
  LanguageScope({super.key, required super.child}) : super(notifier: AppLanguage.code);
}
