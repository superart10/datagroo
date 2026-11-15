import 'package:material_ui/material_ui.dart';
import 'package:datagroo/core/l10n/app_language.dart';
import 'package:datagroo/core/l10n/catalog_translations.dart';
import 'package:datagroo/core/services/database_helper.dart';
import 'package:datagroo/core/services/ieac.dart';

class PlotDetailScreen extends StatelessWidget {
  final String plotName;
  final int? plotId;
  final double? latitude;
  final double? longitude;

  const PlotDetailScreen({
    super.key,
    required this.plotName,
    this.plotId,
    this.latitude,
    this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    AppLanguage.watch(context);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(plotName),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.history), text: tr('Historial de siembras', 'Planting history')),
              Tab(icon: Icon(Icons.autorenew), text: tr('Planes de rotación', 'Rotation plans')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Pestaña 1: Historial de siembras
            _buildHistoryTab(context, primaryColor),

            // Pestaña 2: Planes de Rotación dinámicos según IEAC
            _buildRotationTab(context, primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context, Color primaryColor) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final historyList = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (latitude != null && longitude != null)
              Card(
                elevation: 1,
                color: Colors.green.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.satellite_alt, color: Color(0xFF2E7D32), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${tr('Ubicación GPS', 'GPS location')}: ${latitude!.toStringAsFixed(4)}°, ${longitude!.toStringAsFixed(4)}°',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr('Siembras en este terreno', 'Plantings on this plot'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => _showAddHistoryDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(tr('Añadir siembra', 'Add planting')),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (historyList.isEmpty)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(Icons.history_toggle_off, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        tr('Sin historial registrado aún', 'No history recorded yet'),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr('Registra qué sembraste antes para que el sistema te recomiende qué sembrar después.', 'Record what you planted before so the system can recommend what to plant next.'),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...historyList.map((item) {
                final crop = trDbOrNull(item['crop_name']) ?? tr('Cultivo', 'Crop');
                final date = item['planting_date'] ?? tr('Fecha no registrada', 'Date not recorded');
                final harvest = item['harvest_yield'] ?? tr('Rendimiento no indicado', 'Yield not specified');

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: primaryColor.withValues(alpha: 0.15),
                              child: Icon(Icons.eco, color: primaryColor, size: 18),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              crop.toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        const Divider(height: 18),
                        Text('${tr('Fecha de siembra', 'Planting date')}: $date', style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 2),
                        Text('${tr('Cosecha lograda', 'Harvest obtained')}: $harvest', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchHistory() async {
    if (plotId == null) return [];
    try {
      return await DatabaseHelper.instance.getPlotHistory(plotId!);
    } catch (_) {
      return [];
    }
  }

  Widget _buildRotationTab(BuildContext context, Color primaryColor) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: plotId != null ? DatabaseHelper.instance.getPlot(plotId!) : Future.value(null),
      builder: (context, plotSnapshot) {
        if (plotSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final plotData = plotSnapshot.data;
        final int? regionId = plotData?['region_id'] as int?;
        final String currentCrop = (plotData?['current_crop'] as String?) ?? 'Maíz criollo';
        final String regionName = (plotData?['region_name'] as String?) ?? 'Veracruz Centro';

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: regionId != null
              ? DatabaseHelper.instance.getCropsByRegion(regionId)
              : DatabaseHelper.instance.getCrops(),
          builder: (context, cropsSnapshot) {
            if (cropsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final crops = cropsSnapshot.data ?? [];

            // ==========================================
            // PREPARACIÓN PARA APIS DE LA NASA
            // ==========================================
            // TODO: Inyectar datos en tiempo real desde la respuesta JSON de las APIs de la NASA (POWER/GPM/SMAP)
            // final jsonResponse = await nasaApiService.getWeatherData(latitude, longitude);
            // double p = jsonResponse['precipitation_score'];
            // double t = jsonResponse['temperature_score'];
            // double a = jsonResponse['agronomic_score'];
            double p = 85.0; // Precipitación
            double t = 80.0; // Temperatura
            double a = 75.0; // Variable agronómica / suelo

            // Lógica matemática: Índice Específico de Aptitud de Cultivo (IEAC)
            double calcularIEAC(double p, double t, double a) {
              return (0.35 * p) + (0.35 * t) + (0.30 * a);
            }

            // Filtrar cultivos para buscar la mejor opción de rotación (diferente al cultivo actual o mejor puntaje)
            Map<String, dynamic>? bestCrop;
            double bestScore = -1.0;

            for (final crop in crops) {
              final cropName = crop['name'] as String? ?? '';
              final tempMin = (crop['temp_min'] as num?)?.toDouble();
              final tempMax = (crop['temp_max'] as num?)?.toDouble();

              // Puntaje ajustado según la temperatura de referencia actual (28°C)
              final tScore = componenteAptitud(28.0, tempMin, tempMax);
              final score = calcularIEAC(p, tScore, a);

              // Priorizar cambiar de cultivo para rotación adecuada
              final esDiferente = cropName.toLowerCase() != currentCrop.toLowerCase();
              final adjustedScore = esDiferente ? score + 5.0 : score;

              if (adjustedScore > bestScore) {
                bestScore = adjustedScore;
                bestCrop = crop;
              }
            }

            if (bestCrop == null && crops.isNotEmpty) {
              bestCrop = crops.first;
              bestScore = calcularIEAC(p, t, a);
            }

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: Color(0xFF2E7D32), size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('Plan de Rotación Sugerido para $regionName', 'Suggested Rotation Plan for ${trDb(regionName)}'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2E7D32)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tr('Cálculo basado en el Índice Específico de Aptitud de Cultivo (IEAC).', 'Calculation based on the Specific Crop Suitability Index (IEAC).'),
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (bestCrop != null) ...[
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${tr('Opción Recomendada: Sembrar', 'Recommended Option: Plant')} ${trDb(bestCrop['name'] as String?)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E7D32),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'IEAC: ${bestScore.clamp(0, 100).toStringAsFixed(1)} / 100',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          if (bestCrop['scientific_name'] != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              bestCrop['scientific_name'] as String,
                              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                            ),
                          ],
                          const SizedBox(height: 12),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.arrow_forward, size: 18, color: Colors.blueGrey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${tr('Secuencia: Turnar', 'Sequence: Rotate')} ${trDb(currentCrop)} ➔ ${trDb(bestCrop['name'] as String?)}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          Text(
                            tr('¿Por qué es la mejor opción?:', 'Why is it the best option?'),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  trDbOrNull(bestCrop['rotation_recommendation']) ??
                                      trDbOrNull(bestCrop['description']) ??
                                      tr('Excelente compatibilidad con el suelo y el clima de la región.', 'Excellent compatibility with the soil and climate of the region.'),
                                  style: const TextStyle(fontSize: 13, height: 1.35),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.thermostat, color: Colors.orange, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${tr('Temperatura requerida', 'Required temperature')}: ${trDb((bestCrop['optimal_temperature'] as String?) ?? '18°C a 30°C')}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.landscape, color: Colors.brown, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${tr('Tipo de suelo', 'Soil type')}: ${trDbOrNull(bestCrop['soil_type']) ?? tr('Suelo franco con buen drenaje.', 'Loam soil with good drainage.')}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else
                  Center(
                    child: Text(tr('No hay cultivos disponibles para evaluar en esta región.', 'There are no crops available to evaluate in this region.')),
                  ),
                const SizedBox(height: 24),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddHistoryDialog(BuildContext context) {
    final cropCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: '${DateTime.now().year}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Registrar siembra anterior', 'Record a previous planting')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cropCtrl,
              decoration: InputDecoration(labelText: tr('¿Qué cultivo sembraste? (ej. Maíz)', 'Which crop did you plant? (e.g. Corn)')),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: dateCtrl,
              decoration: InputDecoration(labelText: tr('Año o temporada', 'Year or season')),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Cancelar', 'Cancel'))),
          ElevatedButton(
            onPressed: () async {
              final cropName = cropCtrl.text.trim();
              if (cropName.isEmpty) return;

              if (plotId != null) {
                try {
                  await DatabaseHelper.instance.insertPlotHistory({
                    'plot_id': plotId!,
                    'crop_name': cropName,
                    'planting_date': dateCtrl.text.trim(),
                  });
                } catch (_) {}
              }

              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr('Siembra registrada con éxito.', 'Planting recorded successfully.'))),
                );
              }
            },
            child: Text(tr('Guardar', 'Save')),
          ),
        ],
      ),
    );
  }
}
