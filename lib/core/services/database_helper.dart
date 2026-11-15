import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('datagroo.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE regions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        lat_min REAL,
        lat_max REAL,
        lon_min REAL,
        lon_max REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE crops (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        scientific_name TEXT,
        crop_type TEXT,
        botanical_family TEXT,
        cycle_days INTEGER,
        water_requirement TEXT,
        optimal_temperature TEXT,
        temp_min REAL,
        temp_max REAL,
        water_min_mm REAL,
        water_max_mm REAL,
        soil_type TEXT,
        description TEXT,
        rotation_recommendation TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE region_cultivo (
        region_id INTEGER NOT NULL,
        crop_id INTEGER NOT NULL,
        PRIMARY KEY (region_id, crop_id),
        FOREIGN KEY (region_id) REFERENCES regions (id) ON DELETE CASCADE,
        FOREIGN KEY (crop_id) REFERENCES crops (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE plots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        area_hectares REAL,
        current_crop TEXT,
        crop_id INTEGER,
        region_id INTEGER,
        latitude REAL,
        longitude REAL,
        location TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (crop_id) REFERENCES crops (id),
        FOREIGN KEY (region_id) REFERENCES regions (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE plot_crop_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plot_id INTEGER NOT NULL,
        crop_name TEXT NOT NULL,
        planting_date TEXT,
        harvest_yield TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (plot_id) REFERENCES plots (id) ON DELETE CASCADE
      )
    ''');

    await db.execute(_createUsersTable);

    await _seedRegionsAndCrops(db);
  }

  static const String _createUsersTable = '''
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      salt TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
  ''';

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS regions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          lat_min REAL,
          lat_max REAL,
          lon_min REAL,
          lon_max REAL
        )
      ''');
      await db.execute('ALTER TABLE crops ADD COLUMN temp_min REAL');
      await db.execute('ALTER TABLE crops ADD COLUMN temp_max REAL');
      await db.execute('ALTER TABLE crops ADD COLUMN water_min_mm REAL');
      await db.execute('ALTER TABLE crops ADD COLUMN water_max_mm REAL');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS region_cultivo (
          region_id INTEGER NOT NULL,
          crop_id INTEGER NOT NULL,
          PRIMARY KEY (region_id, crop_id),
          FOREIGN KEY (region_id) REFERENCES regions (id) ON DELETE CASCADE,
          FOREIGN KEY (crop_id) REFERENCES crops (id) ON DELETE CASCADE
        )
      ''');
      await db.execute('ALTER TABLE plots ADD COLUMN crop_id INTEGER');
      await db.execute('ALTER TABLE plots ADD COLUMN region_id INTEGER');
    }
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE regions ADD COLUMN lat_min REAL');
        await db.execute('ALTER TABLE regions ADD COLUMN lat_max REAL');
        await db.execute('ALTER TABLE regions ADD COLUMN lon_min REAL');
        await db.execute('ALTER TABLE regions ADD COLUMN lon_max REAL');
      } catch (_) {}
    }
    if (oldVersion < 5) {
      await db.execute(_createUsersTable);
    }
    await _seedRegionsAndCrops(db);
  }

  Future<void> _seedRegionsAndCrops(Database db) async {
    final regionDefs = [
      {'name': 'Veracruz Norte', 'lat_min': 20.5, 'lat_max': 22.5, 'lon_min': -98.6, 'lon_max': -97.0},
      {'name': 'Veracruz Centro', 'lat_min': 18.8, 'lat_max': 20.5, 'lon_min': -97.8, 'lon_max': -96.0},
      {'name': 'Veracruz Sur', 'lat_min': 17.0, 'lat_max': 18.8, 'lon_min': -96.5, 'lon_max': -94.0},
    ];

    for (final def in regionDefs) {
      final name = def['name'] as String;
      final found = await db.query('regions', where: 'name = ?', whereArgs: [name], limit: 1);
      if (found.isEmpty) {
        await db.insert('regions', def);
      } else {
        await db.update('regions', def, where: 'id = ?', whereArgs: [found.first['id']]);
      }
    }

    final regions = await db.query('regions');
    final regionId = <String, int>{
      for (final row in regions) row['name'] as String: row['id'] as int,
    };

    final centroYSur = [regionId['Veracruz Centro']!, regionId['Veracruz Sur']!];
    final centroOnly = [regionId['Veracruz Centro']!];

    final now = DateTime.now().toIso8601String();
    final documented = [
      {
        'name': 'Café',
        'scientific_name': 'Coffea arabica',
        'crop_type': 'Perenne',
        'botanical_family': 'Rubiaceae',
        'water_requirement': 'Entre 1,400 y 2,300 mm de lluvia al año',
        'optimal_temperature': '14°C a 28°C',
        'temp_min': 14.0,
        'temp_max': 28.0,
        'water_min_mm': 1400.0,
        'water_max_mm': 2300.0,
        'soil_type': 'Suelos volcánicos profundos, sueltos y con buen drenaje. pH 5.5 a 7',
        'description': 'Arbusto perenne. Empieza a producir a los 3 o 4 años y su vida útil suele ser de 20 a 30 años.',
        'rotation_recommendation': 'No se rota como cultivo anual. Evitar cultivos que agoten el potasio.',
        'created_at': now,
        'region_ids': centroYSur,
      },
      {
        'name': 'Maíz criollo',
        'scientific_name': 'Zea mays subsp. Mays',
        'crop_type': 'Anual',
        'botanical_family': 'Poaceae',
        'cycle_days': 150,
        'water_requirement': 'Humedad de temporal o tonamil',
        'optimal_temperature': '18°C a 33°C',
        'temp_min': 18.0,
        'temp_max': 33.0,
        'soil_type': 'Textura franca a franco-arcillosa. pH 5 a 7',
        'description': 'Maíz anual de 3 a 7 meses, adaptado al centro y sur de Veracruz.',
        'rotation_recommendation': 'Alternar con leguminosas o tubérculos. Evitar sembrar maíz tras maíz.',
        'created_at': now,
        'region_ids': centroYSur,
      },
      {
        'name': 'Frijol',
        'scientific_name': 'Phaseolus vulgaris L.',
        'crop_type': 'Anual de ciclo corto',
        'botanical_family': 'Fabaceae',
        'cycle_days': 85,
        'water_requirement': 'Humedad residual y temporal',
        'optimal_temperature': '16°C a 25°C',
        'temp_min': 16.0,
        'temp_max': 25.0,
        'soil_type': 'Suelos francos, franco-arcillosos o aluviales. pH 5.5 a 7.5',
        'description': 'Leguminosa de ciclo corto, de 70 a 95 días.',
        'rotation_recommendation': 'No repetir frijol ni otra leguminosa en 2 o 3 años. Rotar con maíz, sorgo, arroz o caña.',
        'created_at': now,
        'region_ids': centroYSur,
      },
      {
        'name': 'Calabaza o calabacita',
        'scientific_name': 'Cucurbita pepo',
        'crop_type': 'Anual',
        'botanical_family': 'Cucurbitaceae',
        'cycle_days': 65,
        'water_requirement': '350 a 500 mm acumulados por ciclo',
        'optimal_temperature': '17°C a 30°C',
        'temp_min': 17.0,
        'temp_max': 30.0,
        'water_min_mm': 350.0,
        'water_max_mm': 500.0,
        'soil_type': 'Abono y fertilizantes ricos en N, P, K. pH 5.5 a 6.8',
        'description': 'Cultivo anual de 45 a 90 días con alta compatibilidad con maíz y frijol.',
        'rotation_recommendation': 'Esperar entre 2 o 3 años antes de volver a sembrar calabaza.',
        'created_at': now,
        'region_ids': centroYSur,
      },
      {
        'name': 'Piña',
        'scientific_name': 'Ananas comosus',
        'crop_type': 'Semiperenne',
        'botanical_family': 'Bromeliaceae',
        'cycle_days': 480,
        'water_requirement': '1000 a 1500 mm al año',
        'optimal_temperature': '21°C a 30°C',
        'temp_min': 21.0,
        'temp_max': 30.0,
        'water_min_mm': 1000.0,
        'water_max_mm': 1500.0,
        'soil_type': 'Suelos francos o franco-arenosos profundos. pH 4.5 a 8',
        'description': 'Cultivo semiperenne de 14 a 18 meses para la primera cosecha.',
        'rotation_recommendation': 'Esperar al menos 1 o 2 años antes de volver a sembrar piña.',
        'created_at': now,
        'region_ids': centroYSur,
      },
      {
        'name': 'Chile jalapeño',
        'scientific_name': 'Capsicum annuum L.',
        'crop_type': 'Anual de ciclo medio',
        'botanical_family': 'Solanaceae',
        'cycle_days': 150,
        'water_requirement': '450 a 650 mm acumulados',
        'optimal_temperature': '17°C a 30°C',
        'temp_min': 17.0,
        'temp_max': 30.0,
        'water_min_mm': 450.0,
        'water_max_mm': 650.0,
        'soil_type': 'Suelos francos o franco-arenosos sueltos. pH 5.5 a 6.8',
        'description': 'Cultivo anual de 4 a 6 meses con excelente compatibilidad con maíz y sorgo.',
        'rotation_recommendation': 'Esperar un mínimo de 3 a 4 años para volver a sembrarlo.',
        'created_at': now,
        'region_ids': centroYSur,
      },
      {
        'name': 'Papa',
        'scientific_name': 'Solanum tuberosum',
        'crop_type': 'Herbáceo perenne',
        'botanical_family': 'Oxalidaceae',
        'cycle_days': 210,
        'water_requirement': '600 a 800 mm acumulados',
        'optimal_temperature': '12°C a 24°C',
        'temp_min': 12.0,
        'temp_max': 24.0,
        'water_min_mm': 600.0,
        'water_max_mm': 800.0,
        'soil_type': 'Suelos volcánicos andosoles de textura franca. pH 5.5 a 6.8',
        'description': 'Tubérculo de clima templado-frío en regiones de altura de Veracruz.',
        'rotation_recommendation': 'En zonas altas se rota cada 2 o 3 años para controlar plagas.',
        'created_at': now,
        'region_ids': centroOnly,
      },
      {
        'name': 'Avena forrajera',
        'scientific_name': 'Avena sativa L.',
        'crop_type': 'Anual de ciclo corto',
        'botanical_family': 'Poaceae',
        'cycle_days': 90,
        'water_requirement': '350 a 500 mm acumulados',
        'optimal_temperature': '15°C a 22°C',
        'temp_min': 15.0,
        'temp_max': 22.0,
        'water_min_mm': 350.0,
        'water_max_mm': 500.0,
        'soil_type': 'Suelos francos, profundos y bien drenados. pH 5.5 a 7',
        'description': 'Cereal forrajero anual de 80 a 100 días para zonas del centro de Veracruz.',
        'rotation_recommendation': 'Excelente cultivo limpiador y protector del suelo si se rota cada 1 o 2 años.',
        'created_at': now,
        'region_ids': centroOnly,
      },
    ];

    for (final crop in documented) {
      final regionIds = List<int>.from(crop['region_ids'] as List<int>);
      final data = Map<String, Object?>.from(crop)..remove('region_ids');
      final existing = await db.query(
        'crops',
        where: 'name = ?',
        whereArgs: [data['name']],
        limit: 1,
      );
      final int cropId;
      if (existing.isEmpty) {
        cropId = await db.insert('crops', data);
      } else {
        cropId = existing.first['id'] as int;
        await db.update(
          'crops',
          data,
          where: 'id = ?',
          whereArgs: [cropId],
        );
      }
      for (final regionId in regionIds) {
        await db.insert(
          'region_cultivo',
          {'region_id': regionId, 'crop_id': cropId},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
  }

  /// Compara la latitud y longitud GPS con los rangos (lat_min, lat_max, lon_min, lon_max) de cada región.
  Future<Map<String, dynamic>?> getRegionByCoordinates(double lat, double lon) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT * FROM regions
      WHERE ? >= lat_min AND ? <= lat_max AND ? >= lon_min AND ? <= lon_max
      LIMIT 1
    ''', [lat, lat, lon, lon]);

    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final rows = await db.query('users', where: 'email = ?', whereArgs: [email], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    final row = Map<String, dynamic>.from(user);
    row['created_at'] ??= DateTime.now().toIso8601String();
    return await db.insert('users', row);
  }

  Future<List<Map<String, dynamic>>> getPlots() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT plots.*, regions.name AS region_name
      FROM plots
      LEFT JOIN regions ON regions.id = plots.region_id
      ORDER BY plots.id DESC
    ''');
  }

  Future<Map<String, dynamic>?> getPlot(int id) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT plots.*, regions.name AS region_name
      FROM plots
      LEFT JOIN regions ON regions.id = plots.region_id
      WHERE plots.id = ?
      LIMIT 1
    ''', [id]);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<int> insertPlot(Map<String, dynamic> plot) async {
    final db = await database;
    final row = Map<String, dynamic>.from(plot);
    row['created_at'] ??= DateTime.now().toIso8601String();
    return await db.insert('plots', row);
  }

  Future<int> deletePlot(int id) async {
    final db = await database;
    return await db.delete('plots', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getRegions() async {
    final db = await database;
    return await db.query('regions', orderBy: 'id ASC');
  }

  Future<List<Map<String, dynamic>>> getCrops({String? query}) async {
    final db = await database;
    if (query != null && query.trim().isNotEmpty) {
      return await db.query(
        'crops',
        where: 'name LIKE ? OR scientific_name LIKE ? OR crop_type LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: 'name ASC',
      );
    }
    return await db.query('crops', orderBy: 'name ASC');
  }

  Future<List<Map<String, dynamic>>> getCropsByRegion(int regionId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT crops.*
      FROM crops
      INNER JOIN region_cultivo ON region_cultivo.crop_id = crops.id
      WHERE region_cultivo.region_id = ?
      ORDER BY crops.name ASC
    ''', [regionId]);
  }

  Future<int> insertCrop(Map<String, dynamic> crop) async {
    final db = await database;
    final row = Map<String, dynamic>.from(crop);
    row['created_at'] ??= DateTime.now().toIso8601String();
    return await db.insert('crops', row);
  }

  /// Cultivo a comparar en clima: el último del historial o, si no hay, el de la parcela más reciente.
  Future<Map<String, dynamic>?> getCropForCompatibility() async {
    final db = await database;
    final history = await db.rawQuery('''
      SELECT plot_crop_history.crop_name AS crop_name, plots.name AS plot_name
      FROM plot_crop_history
      INNER JOIN plots ON plots.id = plot_crop_history.plot_id
      ORDER BY plot_crop_history.id DESC
      LIMIT 1
    ''');

    String? cropName;
    String? plotName;
    if (history.isNotEmpty) {
      cropName = history.first['crop_name'] as String?;
      plotName = history.first['plot_name'] as String?;
    } else {
      final plots = await db.query(
        'plots',
        where: "current_crop IS NOT NULL AND TRIM(current_crop) != ''",
        orderBy: 'id DESC',
        limit: 1,
      );
      if (plots.isEmpty) return null;
      cropName = plots.first['current_crop'] as String?;
      plotName = plots.first['name'] as String?;
    }

    if (cropName == null || cropName.trim().isEmpty) return null;
    final crops = await db.query('crops', where: 'name = ?', whereArgs: [cropName.trim()], limit: 1);
    if (crops.isEmpty) {
      return {'name': cropName.trim(), 'plot_name': plotName};
    }
    return {...crops.first, 'plot_name': plotName};
  }

  Future<List<Map<String, dynamic>>> getPlotHistory(int plotId) async {
    final db = await database;
    return await db.query(
      'plot_crop_history',
      where: 'plot_id = ?',
      whereArgs: [plotId],
      orderBy: 'id DESC',
    );
  }

  Future<int> insertPlotHistory(Map<String, dynamic> history) async {
    final db = await database;
    final row = Map<String, dynamic>.from(history);
    row['created_at'] ??= DateTime.now().toIso8601String();
    return await db.insert('plot_crop_history', row);
  }
}
