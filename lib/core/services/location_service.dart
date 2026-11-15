import 'package:geolocator/geolocator.dart';
import 'package:datagroo/core/l10n/app_language.dart';

class LocationService {
  /// Obtiene la posición actual por coordenadas GPS en tiempo real.
  /// Si los permisos no están otorgados, solicita el permiso al agricultor.
  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(tr(
        'El servicio de ubicación (GPS) está apagado. Por favor actívalo en tu teléfono.',
        'The location service (GPS) is turned off. Please turn it on in your phone.',
      ));
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(tr(
          'Permiso de ubicación denegado. DATAGROO necesita saber dónde está tu terreno.',
          'Location permission denied. DATAGROO needs to know where your plot is.',
        ));
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(tr(
        'Los permisos de ubicación están bloqueados permanentemente en tu teléfono. Actívalos en Ajustes.',
        'Location permissions are permanently blocked on your phone. Enable them in Settings.',
      ));
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }
}
