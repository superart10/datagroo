import 'package:material_ui/material_ui.dart';
import 'package:datagroo/core/l10n/app_language.dart';
import 'package:datagroo/core/services/auth_service.dart';
import 'package:datagroo/features/auth/screens/register_screen.dart';

/// Inicio de sesión: pide solo correo y contraseña.
/// También permite crear una cuenta o entrar como invitado.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _hidePassword = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      // Al iniciar sesión, la raíz de la app cambia sola a la pantalla principal.
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = tr('No se pudo iniciar sesión: $e', 'Could not sign in: $e'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLanguage.watch(context);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => AppLanguage.set(AppLanguage.isEnglish ? 'es' : 'en'),
                      icon: const Icon(Icons.language, size: 18),
                      label: Text(AppLanguage.isEnglish ? 'Español' : 'English'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: primaryColor.withValues(alpha: 0.12),
                    child: Icon(Icons.eco, size: 46, color: primaryColor),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'DATAGROO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr('Inicia sesión para continuar', 'Sign in to continue'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: tr('Correo', 'Email'),
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _hidePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _busy ? null : _submitLogin(),
                    decoration: InputDecoration(
                      labelText: tr('Contraseña', 'Password'),
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        tooltip: _hidePassword
                            ? tr('Mostrar contraseña', 'Show password')
                            : tr('Ocultar contraseña', 'Hide password'),
                        onPressed: () => setState(() => _hidePassword = !_hidePassword),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _busy ? null : _submitLogin,
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : Text(tr('Iniciar sesión', 'Sign in')),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterScreen()),
                            ),
                    child: Text(tr('¿No tienes cuenta? Regístrate', "Don't have an account? Sign up")),
                  ),
                  const Divider(height: 28),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor),
                    ),
                    onPressed: _busy ? null : () => _run(AuthService.enterAsGuest),
                    icon: const Icon(Icons.person_outline),
                    label: Text(tr('Entrar como invitado', 'Continue as guest')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitLogin() {
    _run(() => AuthService.login(email: _emailCtrl.text, password: _passwordCtrl.text));
  }
}
