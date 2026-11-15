import 'package:material_ui/material_ui.dart';
import 'package:datagroo/core/l10n/app_language.dart';
import 'package:datagroo/core/services/auth_service.dart';
import 'package:datagroo/features/profile/screens/settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  final Function(int)? onNavigateToTab;

  const ProfileScreen({super.key, this.onNavigateToTab});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Cerrar sesión', 'Sign out')),
        content: Text(tr('¿Quieres cerrar tu sesión?', 'Do you want to sign out?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('Cancelar', 'Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('Cerrar sesión', 'Sign out')),
          ),
        ],
      ),
    );
    if (confirmed == true) await AuthService.logout();
  }

  @override
  Widget build(BuildContext context) {
    AppLanguage.watch(context);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Mi Perfil', 'My Profile')),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de información del usuario
            ValueListenableBuilder<AppUser?>(
              valueListenable: AuthService.currentUser,
              builder: (context, user, _) {
                final isGuest = user == null || user.isGuest;
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: primaryColor.withValues(alpha: 0.15),
                          child: Icon(Icons.person, size: 42, color: primaryColor),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isGuest ? tr('Invitado', 'Guest') : user.username,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isGuest ? tr('Entraste sin cuenta', 'You are browsing without an account') : user.email,
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Accesos directos
            Text(
              tr('Opciones de la Aplicación', 'App Options'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: const Icon(Icons.landscape_outlined, color: Colors.blue),
                    ),
                    title: Text(tr('Mis Terrenos', 'My Plots')),
                    subtitle: Text(tr('Registra o revisa tus parcelas', 'Register or review your plots')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onNavigateToTab?.call(1),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.shade50,
                      child: const Icon(Icons.wb_sunny_outlined, color: Colors.orange),
                    ),
                    title: Text(tr('Clima y Lluvias', 'Weather and Rain')),
                    subtitle: Text(tr('Revisa tu ubicación GPS', 'Check your GPS location')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onNavigateToTab?.call(2),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade50,
                      child: const Icon(Icons.eco_outlined, color: Color(0xFF2E7D32)),
                    ),
                    title: Text(tr('Lista de Cultivos', 'Crop List')),
                    subtitle: Text(tr('Catálogo de cultivos disponibles', 'Catalog of available crops')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onNavigateToTab?.call(3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Cuenta y configuración
            Text(
              tr('Cuenta', 'Account'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade200,
                      child: Icon(Icons.settings_outlined, color: Colors.grey.shade800),
                    ),
                    title: Text(tr('Configuración', 'Settings')),
                    subtitle: Text(tr('Idioma de la aplicación', 'App language')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    ),
                  ),
                  const Divider(height: 1),
                  ValueListenableBuilder<AppUser?>(
                    valueListenable: AuthService.currentUser,
                    builder: (context, user, _) {
                      final isGuest = user == null || user.isGuest;
                      if (isGuest) {
                        // Un invitado no tiene sesión que cerrar: se le lleva
                        // a la pantalla de inicio de sesión / registro.
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.shade50,
                            child: const Icon(Icons.login, color: Color(0xFF2E7D32)),
                          ),
                          title: Text(tr('Iniciar sesión o crear cuenta', 'Sign in or create an account')),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: AuthService.logout,
                        );
                      }
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.shade50,
                          child: Icon(Icons.logout, color: Colors.red.shade700),
                        ),
                        title: Text(
                          tr('Cerrar sesión', 'Sign out'),
                          style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600),
                        ),
                        onTap: () => _confirmLogout(context),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Footer de Créditos
            Center(
              child: Text(
                tr('Desarrollado con datos satelitales de la NASA', 'Built with NASA satellite data'),
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600) ??
                    TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
