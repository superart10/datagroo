import 'package:material_ui/material_ui.dart';
import 'package:datagroo/core/l10n/app_language.dart';
import 'package:datagroo/core/l10n/catalog_translations.dart';

class CropDetailScreen extends StatelessWidget {
  final Map<String, dynamic> crop;

  const CropDetailScreen({super.key, required this.crop});

  @override
  Widget build(BuildContext context) {
    AppLanguage.watch(context);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final String name = trDbOrNull(crop['name']) ?? tr('Cultivo', 'Crop');
    final String scientificName = crop['scientific_name'] ?? '';
    final String cropType = trDbOrNull(crop['crop_type']) ?? 'General';
    final String cycle = crop['cycle_days'] != null
        ? tr('${crop['cycle_days']} días para cosechar', '${crop['cycle_days']} days to harvest')
        : tr('Aproximadamente 3 a 4 meses', 'About 3 to 4 months');
    final String waterReq = trDbOrNull(crop['water_requirement']) ?? tr('Riego o lluvia moderada', 'Irrigation or moderate rain');
    final String tempReq = trDbOrNull(crop['optimal_temperature']) ?? tr('Clima cálido a templado (20°C a 30°C)', 'Warm to temperate climate (20°C to 30°C)');
    final String soilType = trDbOrNull(crop['soil_type']) ?? tr('Tierra fértil que no se encharque', 'Fertile soil that does not get waterlogged');
    final String rotationNote = trDbOrNull(crop['rotation_recommendation']) ??
        tr('Conviene sembrarlo después de frijol u otra leguminosa para que la tierra esté descansada y con nutrientes.', 'It is best planted after beans or another legume, so the soil is rested and rich in nutrients.');
    final String description = trDbOrNull(crop['description']) ??
        tr('Cultivo recomendado para la región agrícola. Muy noble y adecuado para alternar siembras.', 'Recommended crop for the farming region. Very hardy and suitable for alternating plantings.');

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera del cultivo
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: primaryColor.withValues(alpha: 0.15),
                      child: Icon(Icons.eco, color: primaryColor, size: 40),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          if (scientificName.isNotEmpty)
                            Text(
                              scientificName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.black54,
                              ),
                            ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              cropType,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ¿De qué trata este cultivo?
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
                        Icon(Icons.info_outline, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          tr('Sobre este cultivo', 'About this crop'),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 14, height: 1.45, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ¿Qué necesita para crecer bien?
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
                        Icon(Icons.spa_outlined, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          tr('¿Qué necesita la planta?', 'What does the plant need?'),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildNeedItem(
                      icon: Icons.timer_outlined,
                      label: tr('Tiempo de crecimiento', 'Growing time'),
                      value: cycle,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(height: 12),
                    _buildNeedItem(
                      icon: Icons.water_drop_outlined,
                      label: tr('Agua y lluvia necesaria', 'Water and rain needed'),
                      value: waterReq,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildNeedItem(
                      icon: Icons.wb_sunny_outlined,
                      label: tr('Clima y temperatura', 'Climate and temperature'),
                      value: tempReq,
                      color: Colors.deepOrange,
                    ),
                    const SizedBox(height: 12),
                    _buildNeedItem(
                      icon: Icons.landscape_outlined,
                      label: tr('Tipo de tierra que le gusta', 'Type of soil it likes'),
                      value: soilType,
                      color: Colors.brown,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Consejo de siembra y rotación
            Card(
              elevation: 2,
              color: const Color(0xFFE8F5E9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.autorenew, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          tr('Consejo para rotar y cuidar tu suelo', 'Advice to rotate and care for your soil'),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      rotationNote,
                      style: const TextStyle(fontSize: 14, height: 1.45, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNeedItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}
