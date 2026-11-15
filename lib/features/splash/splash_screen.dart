import 'package:material_ui/material_ui.dart';

/// Pantalla de carga que se muestra una sola vez, al abrir la aplicación.
///
/// Muestra una imagen centrada sobre fondo blanco que crece y se encoge
/// ligeramente ("latido") mientras la app termina de iniciar.
///
/// PARA CAMBIAR EL LOGO: reemplaza el archivo `assets/images/splash_logo.png`
/// por tu propio .png (mismo nombre). Si usas otro nombre, cambia [logoAsset].
/// Conviene un PNG cuadrado con fondo transparente, de 512 px o más.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Ruta de la imagen dentro del proyecto.
  static const String logoAsset = 'logoDatagroo.png';

  /// Ancho de la imagen en pantalla.
  static const double logoWidth = 180;

  /// Escala mínima y máxima del latido (1.0 = tamaño normal).
  static const double minScale = 0.92;
  static const double maxScale = 1.08;

  /// Tiempo que tarda en crecer (y lo mismo en encogerse).
  static const Duration pulseDuration = Duration(milliseconds: 900);

  /// Tiempo mínimo que la pantalla permanece visible.
  static const Duration minimumVisible = Duration(milliseconds: 2400);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: SplashScreen.pulseDuration)
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: SplashScreen.minScale, end: SplashScreen.maxScale)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ScaleTransition(
          scale: _scale,
          child: Image.asset(
            SplashScreen.logoAsset,
            width: SplashScreen.logoWidth,
            // Si falta el .png, se muestra un ícono para que la app no falle.
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.eco,
              size: SplashScreen.logoWidth * 0.7,
              color: Color(0xFF2E7D32),
            ),
          ),
        ),
      ),
    );
  }
}
