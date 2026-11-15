import 'package:material_ui/material_ui.dart';
import 'package:datagroo/core/l10n/app_language.dart';
import 'package:datagroo/core/l10n/catalog_translations.dart';
import 'package:datagroo/core/services/database_helper.dart';
import 'package:datagroo/features/crops/screens/crop_detail_screen.dart';

class CropsListScreen extends StatefulWidget {
  const CropsListScreen({super.key});

  @override
  State<CropsListScreen> createState() => _CropsListScreenState();
}

class _CropsListScreenState extends State<CropsListScreen> {
  String _searchQuery = '';
  late Future<List<Map<String, dynamic>>> _cropsFuture;

  @override
  void initState() {
    super.initState();
    _loadCrops();
  }

  void _loadCrops() {
    setState(() {
      _cropsFuture = _searchCrops(_searchQuery);
    });
  }

  /// Busca en el texto original y en su traducción, para que la búsqueda
  /// funcione en el idioma en que el usuario ve el catálogo.
  Future<List<Map<String, dynamic>>> _searchCrops(String query) async {
    final all = await DatabaseHelper.instance.getCrops();
    if (query.isEmpty) return all;
    return all.where((crop) {
      return matchesCatalogText(crop['name'] as String?, query) ||
          matchesCatalogText(crop['scientific_name'] as String?, query) ||
          matchesCatalogText(crop['crop_type'] as String?, query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    AppLanguage.watch(context);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Catálogo de Cultivos', 'Crop Catalog')),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: tr('Actualizar cultivos', 'Refresh crops'),
            onPressed: _loadCrops,
          ),
        ],
      ),
      body: Column(
        children: [
          // Buscador sencillo
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              onChanged: (val) {
                _searchQuery = val.trim();
                _loadCrops();
              },
              decoration: InputDecoration(
                hintText: tr('Buscar cultivo...', 'Search crop...'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _searchQuery = '');
                          _loadCrops();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),

          // Lista de cultivos
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _cropsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text(tr('Cargando cultivos...', 'Loading crops...')),
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
                          Icon(Icons.error_outline, size: 54, color: Colors.orange.shade700),
                          const SizedBox(height: 12),
                          Text(
                            tr('Error al leer los cultivos', 'Error reading the crops'),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadCrops,
                            icon: const Icon(Icons.refresh),
                            label: Text(tr('Reintentar', 'Retry')),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final crops = snapshot.data ?? [];

                if (crops.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 54, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            tr('No se encontraron cultivos', 'No crops found'),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty
                                ? tr('No hay resultados para "$_searchQuery".', 'No results for "$_searchQuery".')
                                : tr('No hay cultivos registrados.', 'There are no registered crops.'),
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: crops.length,
                  itemBuilder: (context, index) {
                    final crop = crops[index];
                    final String name = trDbOrNull(crop['name']) ?? tr('Cultivo sin nombre', 'Unnamed crop');
                    final String cropType = trDbOrNull(crop['crop_type']) ?? 'General';
                    final String scientific = (crop['scientific_name'] as String?) ?? '';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primaryColor,
                          child: const Icon(Icons.eco, color: Colors.white),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          scientific.isNotEmpty ? '$scientific • $cropType' : '${tr('Tipo', 'Type')}: $cropType',
                          style: const TextStyle(fontSize: 13),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CropDetailScreen(crop: crop),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
