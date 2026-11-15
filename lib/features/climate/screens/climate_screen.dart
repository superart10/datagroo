import 'package:material_ui/material_ui.dart';
import 'package:datagroo/core/l10n/app_language.dart';
import 'package:datagroo/core/l10n/catalog_translations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:datagroo/core/services/database_helper.dart';
import 'package:datagroo/core/services/location_service.dart';
import 'package:datagroo/core/services/ieac.dart';
import 'package:datagroo/core/services/nasa_api_service.dart';

class ClimateScreen extends StatefulWidget {
  const ClimateScreen({super.key});

  @override
  State<ClimateScreen> createState() => _ClimateScreenState();
}

class _ClimateScreenState extends State<ClimateScreen> {
  double? _currentLat;
  double? _currentLon;
  bool _isGettingGps = false;
  _GpsStatus _gpsStatus = _GpsStatus.idle;
  String _gpsError = '';

  /// Mensaje de estado del GPS en el idioma activo.
  String get _locationStatus {
    switch (_gpsStatus) {
      case _GpsStatus.idle:
        return tr('Toca el botón para detectar tu ubicación con el GPS', 'Tap the button to detect your location with GPS');
      case _GpsStatus.connecting:
        return tr('Conectando con satélites GPS...', 'Connecting to GPS satellites...');
      case _GpsStatus.detected:
        return tr('Ubicación actual detectada en tiempo real', 'Current location detected in real time');
      case _GpsStatus.waiting:
        return tr('GPS en espera. Toca el botón para actualizar coordenadas.', 'GPS on standby. Tap the button to update coordinates.');
      case _GpsStatus.error:
        return '${tr('Aviso', 'Notice')}: $_gpsError';
    }
  }
  NasaWeatherData? _weatherData;
  bool _isLoadingWeather = false;
  late Future<Map<String, dynamic>?> _compatibilityCropFuture;

  @override
  void initState() {
    super.initState();
    _detectGpsLocation(silent: true);
    _compatibilityCropFuture = DatabaseHelper.instance.getCropForCompatibility();
  }

  Future<void> _detectGpsLocation({bool silent = false}) async {
    setState(() {
      _isGettingGps = true;
      _gpsStatus = _GpsStatus.connecting;
    });

    try {
      final Position pos = await LocationService.getCurrentLocation();
      setState(() {
        _currentLat = pos.latitude;
        _currentLon = pos.longitude;
        _gpsStatus = _GpsStatus.detected;
      });
      await _fetchNasaWeather(pos.latitude, pos.longitude);
    } catch (e) {
      setState(() {
        _gpsStatus = silent ? _GpsStatus.waiting : _GpsStatus.error;
        _gpsError = '$e';
      });
      // Fallback a coordenadas por defecto del Centro de Veracruz
      await _fetchNasaWeather(_currentLat ?? 19.5, _currentLon ?? -96.9);
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingGps = false);
      }
    }
  }

  Future<void> _fetchNasaWeather(double lat, double lon) async {
    setState(() => _isLoadingWeather = true);
    try {
      final data = await NasaApiService.fetchClimateByCoordinates(
        latitude: lat,
        longitude: lon,
      );
      if (mounted) {
        setState(() {
          _weatherData = data;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingWeather = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLanguage.watch(context);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final data = _weatherData;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Clima en tu Parcela', 'Weather on your Plot')),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: tr('Actualizar GPS', 'Update GPS'),
            onPressed: _isGettingGps ? null : () => _detectGpsLocation(silent: false),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de ubicación GPS en tiempo real
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: primaryColor.withValues(alpha: 0.12),
                          child: Icon(Icons.my_location, color: primaryColor, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            tr('Ubicación exacta de tu terreno', 'Exact location of your plot'),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_currentLat != null && _currentLon != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, size: 18, color: Color(0xFF2E7D32)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${tr('Coordenadas GPS', 'GPS coordinates')}:\n${tr('Latitud', 'Latitude')}: ${_currentLat!.toStringAsFixed(5)}° • ${tr('Longitud', 'Longitude')}: ${_currentLon!.toStringAsFixed(5)}°',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF2E7D32)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Text(
                        _locationStatus,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor),
                        ),
                        onPressed: _isGettingGps ? null : () => _detectGpsLocation(silent: false),
                        icon: _isGettingGps || _isLoadingWeather
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.gps_fixed, size: 18),
                        label: Text(_isGettingGps ? tr('Buscando satélites...', 'Searching for satellites...') : tr('Actualizar Coordenadas GPS', 'Update GPS Coordinates')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Petición POST a la API de la NASA
            /*
            Card(
              elevation: 1,
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.blue.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.send_rounded, size: 18, color: Color(0xFF1565C0)),
                        SizedBox(width: 8),
                        Text(
                          'Consulta POST a Servicios Satelitales NASA',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Payload POST: {"latitude": ${lat.toStringAsFixed(5)}, "longitude": ${lon.toStringAsFixed(5)}}',
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.black87),
                    ),
                    if (data != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Respuesta: ${data.responseStatus}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            */

            // 1. Temperatura del aire
            _buildClimateCard(
              title: tr('Temperatura del Aire', 'Air Temperature'),
              icon: Icons.wb_sunny,
              iconColor: Colors.orange,
              value: data != null ? '${data.temperature.toStringAsFixed(1)}°C' : '28.0°C',
              description: data?.tempDescription ?? NasaApiService.describeTemperature(28.0),
            ),
            const SizedBox(height: 16),

            // 2. Precipitación
            _buildClimateCard(
              title: tr('Precipitación (Lluvia)', 'Precipitation (Rain)'),
              icon: Icons.water_drop,
              iconColor: Colors.blue,
              value: '${(data?.precipitation ?? 3.5).toStringAsFixed(1)} ${tr('mm/día', 'mm/day')}',
              description: data?.precipDescription ?? NasaApiService.describePrecipitation(3.5),
            ),
            const SizedBox(height: 16),

            // 3. Humedad de la tierra
            _buildClimateCard(
              title: tr('Humedad de tu Tierra', 'Moisture of your Soil'),
              icon: Icons.grass,
              iconColor: const Color(0xFF2E7D32),
              value: data != null ? '${data.soilMoisture.toStringAsFixed(0)}%' : '45%',
              description: data?.moistureDescription ?? NasaApiService.describeSoilMoisture(45.0),
            ),
            const SizedBox(height: 16),

            // 4. Nueva Sección: Compatibilidad Agrícola
            FutureBuilder<Map<String, dynamic>?>(
              future: _compatibilityCropFuture,
              builder: (context, snapshot) {
                final cropData = snapshot.data;
                final String cropName = (cropData?['name'] as String?) ?? 'Café';
                final String? plotName = cropData?['plot_name'] as String?;
                final double tempMin = (cropData?['temp_min'] as num?)?.toDouble() ?? 14.0;
                final double tempMax = (cropData?['temp_max'] as num?)?.toDouble() ?? 28.0;
                final double tempActual = data?.temperature ?? 28.0;

                final compatibilidad = evaluarCompatibilidad(
                  temperaturaC: tempActual,
                  cultivo: trDb(cropName),
                  tempMin: tempMin,
                  tempMax: tempMax,
                );

                final isFavorable = compatibilidad.favorable;
                final badgeColor = isFavorable ? const Color(0xFF2E7D32) : Colors.orange.shade800;
                final badgeBg = isFavorable ? Colors.green.shade50 : Colors.orange.shade50;

                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: badgeColor.withValues(alpha: 0.5), width: 1.2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: badgeColor.withValues(alpha: 0.12),
                              child: Icon(
                                isFavorable ? Icons.check_circle : Icons.warning,
                                color: badgeColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr('Compatibilidad Agrícola', 'Crop Compatibility'),
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    plotName != null
                                        ? '${tr('Cultivo', 'Crop')}: ${trDb(cropName)} ($plotName)'
                                        : '${tr('Cultivo registrado', 'Registered crop')}: ${trDb(cropName)}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: badgeColor),
                              ),
                              child: Text(
                                compatibilidad.estado,
                                style: TextStyle(
                                  color: badgeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isFavorable ? Icons.thumb_up_alt_outlined : Icons.info_outline,
                              color: badgeColor,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                compatibilidad.recomendacion,
                                style: const TextStyle(fontSize: 13, height: 1.35, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildClimateCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String description,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: iconColor.withValues(alpha: 0.12),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: iconColor),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.analytics_outlined, size: 18, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    description,
                    style: TextStyle(fontSize: 13, height: 1.35, color: Colors.grey.shade900),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _GpsStatus { idle, connecting, detected, waiting, error }
