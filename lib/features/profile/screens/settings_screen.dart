import 'package:material_ui/material_ui.dart';
import 'package:datagroo/core/l10n/app_language.dart';

/// Configuración de la app. Por ahora: idioma (español / inglés).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppLanguage.watch(context);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Configuración', 'Settings')),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            tr('Idioma', 'Language'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _languageTile(code: 'es', name: 'Español', primaryColor: primaryColor),
                const Divider(height: 1),
                _languageTile(code: 'en', name: 'English', primaryColor: primaryColor),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr(
              'El cambio se aplica de inmediato a toda la aplicación.',
              'The change applies immediately to the whole app.',
            ),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _languageTile({required String code, required String name, required Color primaryColor}) {
    final selected = AppLanguage.code.value == code;
    return ListTile(
      leading: Icon(Icons.language, color: selected ? primaryColor : Colors.grey),
      title: Text(name, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      trailing: selected ? Icon(Icons.check_circle, color: primaryColor) : const Icon(Icons.circle_outlined, color: Colors.grey),
      onTap: () => AppLanguage.set(code),
    );
  }
}
