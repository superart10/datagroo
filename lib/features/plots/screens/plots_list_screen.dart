import 'package:material_ui/material_ui.dart';
import 'package:datagroo/core/l10n/app_language.dart';
import 'package:datagroo/core/l10n/catalog_translations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:datagroo/core/services/database_helper.dart';
import 'package:datagroo/core/services/location_service.dart';
import 'package:datagroo/features/plots/screens/plots_detail_screen.dart';

class PlotsListScreen extends StatefulWidget {
  const PlotsListScreen({super.key});

  @override
  State<PlotsListScreen> createState() => _PlotsListScreenState();
}

class _PlotsListScreenState extends State<PlotsListScreen> {
  late Future<List<Map<String, dynamic>>> _plotsFuture;

  @override
  void initState() {
    super.initState();
    _loadPlots();
  }

  void _loadPlots() {
    setState(() {
      _plotsFuture = DatabaseHelper.instance.getPlots();
    });
  }

  @override
  Widget build(BuildContext context) {
    AppLanguage.watch(context);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Mis Terrenos', 'My Plots')),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: tr('Actualizar terrenos', 'Refresh plots'),
            onPressed: _loadPlots,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _plotsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text(tr('Cargando tus parcelas...', 'Loading your plots...')),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 52, color: Colors.orange.shade700),
                    const SizedBox(height: 12),
                    Text(
                      tr('No se pudieron cargar los terrenos', 'The plots could not be loaded'),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadPlots,
                      icon: const Icon(Icons.refresh),
                      label: Text(tr('Reintentar', 'Retry')),
                    ),
                  ],
                ),
              ),
            );
          }

          final plots = snapshot.data ?? [];

          if (plots.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.landscape_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      tr('No tienes terrenos registrados', 'You have no registered plots'),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr('Toca el botón "+ Nuevo Terreno" para guardar tu primera parcela.', 'Tap the "+ New Plot" button to save your first plot.'),
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showAddPlotDialog(context),
                      icon: const Icon(Icons.add_location_alt),
                      label: Text(tr('Registrar Terreno', 'Register Plot')),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: plots.length,
            itemBuilder: (context, index) {
              final plot = plots[index];
              final id = plot['id'] as int?;
              final name = plot['name'] ?? tr('Terreno sin nombre', 'Unnamed plot');
              final areaVal = plot['area_hectares'];
              final area = areaVal != null ? '$areaVal ${tr('Hectáreas', 'Hectares')}' : tr('Superficie no indicada', 'Area not specified');
              final currentCrop = trDbOrNull(plot['current_crop']) ?? tr('Sin cultivo asignado', 'No crop assigned');
              final regionName = trDbOrNull(plot['region_name']) ?? tr('Sin región', 'No region');
              final lat = plot['latitude'] as num?;
              final lon = plot['longitude'] as num?;

              String locationText = plot['location'] ?? '';
              if (lat != null && lon != null) {
                locationText = 'GPS: ${lat.toStringAsFixed(4)}°, ${lon.toStringAsFixed(4)}°';
              }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.landscape, color: Color(0xFF2E7D32), size: 40),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text('$area • ${tr('Cultivo', 'Crop')}: $currentCrop\n${tr('Región', 'Region')}: $regionName${locationText.isNotEmpty ? ' • $locationText' : ''}'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlotDetailScreen(
                          plotName: name,
                          plotId: id,
                          latitude: lat?.toDouble(),
                          longitude: lon?.toDouble(),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPlotDialog(context),
        icon: const Icon(Icons.add_location_alt, color: Colors.white),
        label: Text(tr('Nuevo Terreno', 'New Plot'), style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
      ),
    );
  }

  void _showAddPlotDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    final latCtrl = TextEditingController();
    final lonCtrl = TextEditingController();

    int? selectedRegionId;
    int? selectedCropId;
    String? selectedCropName;
    String regionMessage = '';

    List<Map<String, dynamic>> regionsList = [];
    List<Map<String, dynamic>> cropsList = [];
    bool isLocating = false;
    bool isLoadingRegions = true;
    bool isLoadingCrops = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (isLoadingRegions && regionsList.isEmpty) {
            DatabaseHelper.instance.getRegions().then((regions) {
              setDialogState(() {
                regionsList = regions;
                isLoadingRegions = false;
              });
            });
          }

          Future<void> updateRegionFromCoordinates(double lat, double lon) async {
            final region = await DatabaseHelper.instance.getRegionByCoordinates(lat, lon);
            if (region != null) {
              final regId = region['id'] as int;
              final crops = await DatabaseHelper.instance.getCropsByRegion(regId);
              setDialogState(() {
                selectedRegionId = regId;
                selectedCropId = null;
                selectedCropName = null;
                cropsList = crops;
                regionMessage = '✓ ${tr('Región detectada por GPS', 'Region detected by GPS')}: ${trDb(region['name'] as String?)}';
              });
            } else {
              final defaultRegion = regionsList.firstWhere(
                (r) => r['name'] == 'Veracruz Centro',
                orElse: () => regionsList.isNotEmpty ? regionsList.first : {'id': 3, 'name': 'Veracruz Centro'},
              );
              final regId = defaultRegion['id'] as int;
              final crops = await DatabaseHelper.instance.getCropsByRegion(regId);
              setDialogState(() {
                selectedRegionId = regId;
                selectedCropId = null;
                selectedCropName = null;
                cropsList = crops;
                regionMessage = '${tr('Región asignada por defecto', 'Region assigned by default')}: ${trDb(defaultRegion['name'] as String?)}';
              });
            }
          }

          return AlertDialog(
            title: Text(tr('Registrar Terreno', 'Register Plot')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: tr('Nombre del terreno o parcela *', 'Name of the plot *'),
                      hintText: tr('Ej. Parcela La Esperanza', 'E.g. La Esperanza plot'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: areaCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: tr('Superficie (en Hectáreas)', 'Area (in hectares)'),
                      hintText: tr('Ej. 3.5', 'E.g. 3.5'),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Botón para capturar coordenadas GPS en tiempo real
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.my_location, size: 18, color: Color(0xFF2E7D32)),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                tr('Ubicación GPS y Región Automática', 'GPS Location and Automatic Region'),
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2E7D32)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tr('Toma tus coordenadas GPS para determinar automáticamente la región geográfica correspondiente.', 'Capture your GPS coordinates to automatically determine the matching geographic region.'),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            ),
                            onPressed: isLocating
                                ? null
                                : () async {
                                    setDialogState(() => isLocating = true);
                                    try {
                                      final Position pos = await LocationService.getCurrentLocation();
                                      latCtrl.text = pos.latitude.toStringAsFixed(6);
                                      lonCtrl.text = pos.longitude.toStringAsFixed(6);
                                      await updateRegionFromCoordinates(pos.latitude, pos.longitude);
                                    } catch (e) {
                                      if (ctx.mounted) {
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          SnackBar(content: Text('$e')),
                                        );
                                      }
                                    } finally {
                                      setDialogState(() => isLocating = false);
                                    }
                                  },
                            icon: isLocating
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.gps_fixed, size: 18),
                            label: Text(
                              isLocating ? tr('Detectando satélites...', 'Detecting satellites...') : tr('Capturar Coordenadas GPS', 'Capture GPS Coordinates'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: latCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                decoration: InputDecoration(
                                  labelText: tr('Latitud', 'Latitude'),
                                  isDense: true,
                                ),
                                onChanged: (val) {
                                  final lat = double.tryParse(val);
                                  final lon = double.tryParse(lonCtrl.text);
                                  if (lat != null && lon != null) {
                                    updateRegionFromCoordinates(lat, lon);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: lonCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                decoration: InputDecoration(
                                  labelText: tr('Longitud', 'Longitude'),
                                  isDense: true,
                                ),
                                onChanged: (val) {
                                  final lat = double.tryParse(latCtrl.text);
                                  final lon = double.tryParse(val);
                                  if (lat != null && lon != null) {
                                    updateRegionFromCoordinates(lat, lon);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        if (regionMessage.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            regionMessage,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Dropdown de Región (se selecciona automáticamente según coordenadas GPS)
                  DropdownButtonFormField<int>(
                    initialValue: selectedRegionId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: tr('Región *', 'Region *'),
                    ),
                    hint: Text(
                      isLoadingRegions
                          ? tr('Cargando regiones...', 'Loading regions...')
                          : tr('Selecciona una región', 'Select a region'),
                      overflow: TextOverflow.ellipsis,
                    ),
                    items: regionsList.map((region) {
                      return DropdownMenuItem<int>(
                        value: region['id'] as int,
                        child: Text(
                          trDb(region['name'] as String?),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: isLoadingRegions
                        ? null
                        : (regionId) async {
                            if (regionId == null) return;
                            setDialogState(() {
                              selectedRegionId = regionId;
                              selectedCropId = null;
                              selectedCropName = null;
                              isLoadingCrops = true;
                            });
                            final crops = await DatabaseHelper.instance.getCropsByRegion(regionId);
                            setDialogState(() {
                              cropsList = crops;
                              isLoadingCrops = false;
                            });
                          },
                  ),
                  const SizedBox(height: 10),

                  // Dropdown de Cultivo filtrado por región
                  DropdownButtonFormField<int>(
                    initialValue: selectedCropId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: tr('Cultivo que tiene sembrado *', 'Crop currently planted *'),
                    ),
                    hint: Text(
                      selectedRegionId == null
                          ? tr('Primero selecciona una región', 'First select a region')
                          : (isLoadingCrops
                              ? tr('Cargando cultivos...', 'Loading crops...')
                              : tr('Selecciona un cultivo', 'Select a crop')),
                      overflow: TextOverflow.ellipsis,
                    ),
                    items: cropsList.map((crop) {
                      return DropdownMenuItem<int>(
                        value: crop['id'] as int,
                        child: Text(
                          trDb(crop['name'] as String?),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (selectedRegionId == null || isLoadingCrops)
                        ? null
                        : (cropId) {
                            if (cropId == null) return;
                            final cropMap = cropsList.firstWhere((c) => c['id'] == cropId);
                            setDialogState(() {
                              selectedCropId = cropId;
                              selectedCropName = cropMap['name'] as String;
                            });
                          },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(tr('Cancelar', 'Cancel')),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(tr('Por favor escribe el nombre de tu terreno.', 'Please enter the name of your plot.'))),
                    );
                    return;
                  }
                  if (selectedRegionId == null) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(tr('Por favor selecciona o detecta la región de tu terreno.', 'Please select or detect the region of your plot.'))),
                    );
                    return;
                  }
                  if (selectedCropId == null) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(tr('Por favor selecciona el cultivo sembrado.', 'Please select the planted crop.'))),
                    );
                    return;
                  }

                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(ctx);

                  final double? areaHectares = double.tryParse(areaCtrl.text.trim());
                  final double? lat = double.tryParse(latCtrl.text.trim());
                  final double? lon = double.tryParse(lonCtrl.text.trim());

                  final Map<String, dynamic> newPlot = {
                    'name': name,
                    'region_id': selectedRegionId,
                    'crop_id': selectedCropId,
                    'current_crop': selectedCropName,
                    ...?areaHectares == null ? null : {'area_hectares': areaHectares},
                    ...?lat == null ? null : {'latitude': lat},
                    ...?lon == null ? null : {'longitude': lon},
                  };

                  try {
                    await DatabaseHelper.instance.insertPlot(newPlot);
                    messenger.showSnackBar(
                      SnackBar(content: Text(tr('Terreno "$name" guardado con éxito.', 'Plot "$name" saved successfully.'))),
                    );
                    navigator.pop();
                    _loadPlots();
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('${tr('Error al guardar el terreno', 'Error saving the plot')}: $e'),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                },
                child: Text(tr('Guardar', 'Save')),
              ),
            ],
          );
        },
      ),
    );
  }
}
