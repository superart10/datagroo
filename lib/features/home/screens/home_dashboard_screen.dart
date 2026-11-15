import 'package:material_ui/material_ui.dart';
import 'package:datagroo/core/l10n/app_language.dart';
import 'package:datagroo/core/services/database_helper.dart';
import 'package:datagroo/features/plots/screens/plots_detail_screen.dart';

class HomeDashboardScreen extends StatelessWidget {
  final Function(int)? onNavigateToTab;

  const HomeDashboardScreen({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    AppLanguage.watch(context);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.eco, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'DATAGROO',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ],
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saludo de bienvenida
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: const Color(0xFF2E7D32),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('¡Bienvenido al campo!', 'Welcome to the field!'),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tr('Consulta tus parcelas, el clima en tu zona y recomendaciones para tu cosecha.', 'Check your plots, the weather in your area and recommendations for your harvest.'),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: const Icon(Icons.agriculture, color: Colors.white, size: 30),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Contadores reales desde SQLite
            Row(
              children: [
                // Mis Terrenos contador real
                Expanded(
                  child: InkWell(
                    onTap: () => onNavigateToTab?.call(1),
                    borderRadius: BorderRadius.circular(12),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    tr('Mis Terrenos', 'My Plots'),
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.landscape_outlined, color: primaryColor, size: 20),
                              ],
                            ),
                            const SizedBox(height: 8),
                            FutureBuilder<List<Map<String, dynamic>>>(
                              future: DatabaseHelper.instance.getPlots(),
                              builder: (context, snapshot) {
                                final count = snapshot.data?.length ?? 0;
                                return Text(
                                  count < 10 ? '0$count' : '$count',
                                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: primaryColor),
                                );
                              },
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tr('Parcelas registradas', 'Registered plots'),
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Cultivos contador real
                Expanded(
                  child: InkWell(
                    onTap: () => onNavigateToTab?.call(3),
                    borderRadius: BorderRadius.circular(12),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    tr('Cultivos', 'Crops'),
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.eco_outlined, color: Color(0xFF2E7D32), size: 20),
                              ],
                            ),
                            const SizedBox(height: 8),
                            FutureBuilder<List<Map<String, dynamic>>>(
                              future: DatabaseHelper.instance.getCrops(),
                              builder: (context, snapshot) {
                                final count = snapshot.data?.length ?? 0;
                                return Text(
                                  count < 10 ? '0$count' : '$count',
                                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: primaryColor),
                                );
                              },
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tr('En catálogo de la BD', 'In the database catalog'),
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tarjeta: Rotación de siembra
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: const Color(0xFFE8F5E9),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: primaryColor,
                          radius: 18,
                          child: const Icon(Icons.autorenew, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            tr('¿Qué sembrar en la próxima temporada?', 'What to plant next season?'),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tr('Turnar tus siembras evita plagas y mantiene la tierra con fuerza. Conoce qué planta le conviene a tu terreno.', 'Rotating your crops prevents pests and keeps the soil strong. Find out which plant suits your plot.'),
                      style: TextStyle(fontSize: 13, height: 1.35, color: Colors.black87),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => onNavigateToTab?.call(1),
                        icon: const Icon(Icons.arrow_forward, size: 20),
                        label: Text(tr('Ver mis terrenos y recomendaciones', 'See my plots and recommendations')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Resumen de Clima
            InkWell(
              onTap: () => onNavigateToTab?.call(2),
              borderRadius: BorderRadius.circular(12),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.wb_sunny_outlined, color: Colors.orange, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    tr('Clima y Lluvias en tu Zona', 'Weather and Rain in your Area'),
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            tr('Ver con GPS >', 'View with GPS >'),
                            style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _MiniClimateItem(
                            icon: Icons.wb_sunny,
                            iconColor: Colors.orange,
                            label: tr('Temperatura', 'Temperature'),
                            value: '28°C',
                          ),
                          _MiniClimateItem(
                            icon: Icons.water_drop,
                            iconColor: Colors.blue,
                            label: tr('Lluvia', 'Rain'),
                            value: tr('Favorable', 'Favorable'),
                          ),
                          _MiniClimateItem(
                            icon: Icons.grass,
                            iconColor: Color(0xFF2E7D32),
                            label: tr('Humedad Suelo', 'Soil Moisture'),
                            value: tr('Buena', 'Good'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Terrenos registrados reales
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    tr('Tus Terrenos Registrados', 'Your Registered Plots'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () => onNavigateToTab?.call(1),
                  child: Text(tr('Ver todos', 'See all')),
                ),
              ],
            ),
            const SizedBox(height: 6),

            FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseHelper.instance.getPlots(),
              builder: (context, snapshot) {
                final plots = snapshot.data ?? [];
                if (plots.isEmpty) {
                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.grey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tr('Aún no has registrado ningún terreno en tu base de datos.', 'You have not registered any plot in your database yet.'),
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ),
                          TextButton(
                            onPressed: () => onNavigateToTab?.call(1),
                            child: Text(tr('Registrar', 'Register')),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: plots.take(2).map((plot) {
                    final id = plot['id'] as int?;
                    final name = plot['name'] ?? tr('Terreno', 'Plot');
                    final areaVal = plot['area_hectares'];
                    final area = areaVal != null ? '$areaVal ha' : tr('Sin superficie', 'No area');

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primaryColor.withValues(alpha: 0.12),
                          child: Icon(Icons.landscape, color: primaryColor),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(area),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlotDetailScreen(
                                plotName: name,
                                plotId: id,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _MiniClimateItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _MiniClimateItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    AppLanguage.watch(context);
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
