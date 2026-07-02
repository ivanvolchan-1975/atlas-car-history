import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/car.dart';
import '../models/service_record.dart';
import '../models/maintenance_item.dart';
import '../models/diagnostic.dart';
import '../models/spare_part.dart';
import '../models/document.dart';
import '../models/reminder.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('car_history.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cars (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        make TEXT NOT NULL,
        model TEXT NOT NULL,
        alt_model TEXT,
        country TEXT,
        year INTEGER,
        vin TEXT,
        engine TEXT,
        transmission TEXT,
        mileage INTEGER,
        photo_path TEXT,
        next_service_date TEXT,
        next_service_mileage INTEGER,
        last_service_mileage INTEGER,
        last_service_date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE service_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        mileage INTEGER,
        description TEXT,
        cost REAL,
        comment TEXT,
        photo_paths TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE maintenance_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        brand TEXT,
        last_changed_date TEXT,
        last_changed_mileage INTEGER,
        interval_km INTEGER,
        interval_months INTEGER,
        cost REAL,
        comment TEXT,
        photo_path TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE diagnostics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        status TEXT,
        created_at TEXT,
        resolved_at TEXT,
        cost REAL,
        photo_paths TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE spare_parts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT,
        oem_number TEXT,
        analogs TEXT,
        best_analog TEXT,
        manufacturer TEXT,
        price REAL,
        shop TEXT,
        shop_url TEXT,
        purchase_date TEXT,
        install_date TEXT,
        comment TEXT,
        photo_part_path TEXT,
        photo_box_path TEXT,
        status TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        type TEXT,
        file_path TEXT,
        added_at TEXT,
        expires_at TEXT,
        comment TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        due_date TEXT,
        due_mileage INTEGER,
        is_completed INTEGER DEFAULT 0,
        is_repeating INTEGER DEFAULT 0
      )
    ''');

    await _insertInitialData(db);
  }

  Future _insertInitialData(Database db) async {
    // Insert car
    await db.insert('cars', {
      'make': 'Geely',
      'model': 'Atlas',
      'alt_model': 'Geely Boyue NL-3',
      'country': 'BelGee (Беларусь)',
      'year': 2018,
      'vin': 'Y4K8752S7JB305112',
      'engine': '2.0 бензин',
      'transmission': 'Механическая',
      'mileage': 70000,
      'last_service_mileage': 60000,
      'last_service_date': DateTime(2023, 1, 1).toIso8601String(),
      'next_service_mileage': 70000,
    });

    // Insert last TO at 60000 km
    await db.insert('service_records', {
      'date': DateTime(2023, 1, 15).toIso8601String(),
      'mileage': 60000,
      'description': 'Плановое ТО 60 000 км',
      'cost': 0.0,
      'comment':
          'Замена масла, масляного фильтра, воздушного фильтра, салонного фильтра',
      'photo_paths': '',
    });

    // Maintenance items
    final items = [
      {
        'name': 'Масло двигателя',
        'last_changed_mileage': 60000,
        'last_changed_date': DateTime(2023, 1, 15).toIso8601String(),
        'interval_km': 10000,
        'interval_months': 12,
      },
      {
        'name': 'Масло МКПП',
        'last_changed_mileage': null,
        'last_changed_date': null,
        'interval_km': 60000,
        'interval_months': 48,
      },
      {
        'name': 'Воздушный фильтр',
        'last_changed_mileage': 60000,
        'last_changed_date': DateTime(2023, 1, 15).toIso8601String(),
        'interval_km': 15000,
        'interval_months': 12,
      },
      {
        'name': 'Салонный фильтр',
        'last_changed_mileage': 60000,
        'last_changed_date': DateTime(2023, 1, 15).toIso8601String(),
        'interval_km': 15000,
        'interval_months': 12,
      },
      {
        'name': 'Тормозная жидкость',
        'last_changed_mileage': null,
        'last_changed_date': null,
        'interval_km': 40000,
        'interval_months': 24,
      },
      {
        'name': 'Антифриз',
        'last_changed_mileage': null,
        'last_changed_date': null,
        'interval_km': 60000,
        'interval_months': 36,
      },
      {
        'name': 'Свечи зажигания',
        'last_changed_mileage': null,
        'last_changed_date': null,
        'interval_km': 30000,
        'interval_months': 24,
      },
      {
        'name': 'Топливный фильтр',
        'last_changed_mileage': null,
        'last_changed_date': null,
        'interval_km': 30000,
        'interval_months': 24,
      },
    ];

    for (final item in items) {
      await db.insert('maintenance_items', item);
    }

    // Diagnostics
    final diagnostics = [
      {
        'title': 'Полосы на дисплее приборной панели',
        'description': null,
        'status': 'searching',
        'created_at': DateTime.now().toIso8601String(),
        'photo_paths': '',
      },
      {
        'title': 'Правая шаровая',
        'description': null,
        'status': 'waitingReplacement',
        'created_at': DateTime.now().toIso8601String(),
        'photo_paths': '',
      },
      {
        'title': 'Правый рулевой наконечник',
        'description': null,
        'status': 'waitingReplacement',
        'created_at': DateTime.now().toIso8601String(),
        'photo_paths': '',
      },
      {
        'title': 'Задние тормозные колодки',
        'description': null,
        'status': 'waitingReplacement',
        'created_at': DateTime.now().toIso8601String(),
        'photo_paths': '',
      },
      {
        'title': 'Кнопка открытия багажника',
        'description': 'Иногда не открывает багажник.',
        'status': 'searching',
        'created_at': DateTime.now().toIso8601String(),
        'photo_paths': '',
      },
    ];

    for (final d in diagnostics) {
      await db.insert('diagnostics', d);
    }
  }

  // ─── CAR ────────────────────────────────────────────────────────────────────

  Future<Car?> getCar() async {
    final db = await database;
    final maps = await db.query('cars', limit: 1);
    if (maps.isEmpty) return null;
    return Car.fromMap(maps.first);
  }

  Future<int> insertCar(Car car) async {
    final db = await database;
    return db.insert('cars', car.toMap());
  }

  Future<void> updateCar(Car car) async {
    final db = await database;
    await db.update('cars', car.toMap(), where: 'id = ?', whereArgs: [car.id]);
  }

  // ─── SERVICE RECORDS ────────────────────────────────────────────────────────

  Future<List<ServiceRecord>> getServiceRecords() async {
    final db = await database;
    final maps = await db.query('service_records', orderBy: 'date DESC');
    return maps.map(ServiceRecord.fromMap).toList();
  }

  Future<int> insertServiceRecord(ServiceRecord record) async {
    final db = await database;
    return db.insert('service_records', record.toMap());
  }

  Future<void> updateServiceRecord(ServiceRecord record) async {
    final db = await database;
    await db.update('service_records', record.toMap(),
        where: 'id = ?', whereArgs: [record.id]);
  }

  Future<void> deleteServiceRecord(int id) async {
    final db = await database;
    await db.delete('service_records', where: 'id = ?', whereArgs: [id]);
  }

  // ─── MAINTENANCE ────────────────────────────────────────────────────────────

  Future<List<MaintenanceItem>> getMaintenanceItems() async {
    final db = await database;
    final maps = await db.query('maintenance_items');
    return maps.map(MaintenanceItem.fromMap).toList();
  }

  Future<int> insertMaintenanceItem(MaintenanceItem item) async {
    final db = await database;
    return db.insert('maintenance_items', item.toMap());
  }

  Future<void> updateMaintenanceItem(MaintenanceItem item) async {
    final db = await database;
    await db.update('maintenance_items', item.toMap(),
        where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> deleteMaintenanceItem(int id) async {
    final db = await database;
    await db.delete('maintenance_items', where: 'id = ?', whereArgs: [id]);
  }

  // ─── DIAGNOSTICS ────────────────────────────────────────────────────────────

  Future<List<Diagnostic>> getDiagnostics() async {
    final db = await database;
    final maps = await db.query('diagnostics', orderBy: 'created_at DESC');
    return maps.map(Diagnostic.fromMap).toList();
  }

  Future<int> insertDiagnostic(Diagnostic d) async {
    final db = await database;
    return db.insert('diagnostics', d.toMap());
  }

  Future<void> updateDiagnostic(Diagnostic d) async {
    final db = await database;
    await db.update('diagnostics', d.toMap(),
        where: 'id = ?', whereArgs: [d.id]);
  }

  Future<void> deleteDiagnostic(int id) async {
    final db = await database;
    await db.delete('diagnostics', where: 'id = ?', whereArgs: [id]);
  }

  // ─── SPARE PARTS ────────────────────────────────────────────────────────────

  Future<List<SparePart>> getSpareParts({String? query, String? category, String? status}) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    final conditions = <String>[];
    final args = <dynamic>[];

    if (query != null && query.isNotEmpty) {
      conditions.add(
          '(name LIKE ? OR oem_number LIKE ? OR analogs LIKE ? OR best_analog LIKE ?)');
      final q = '%$query%';
      args.addAll([q, q, q, q]);
    }
    if (category != null && category.isNotEmpty) {
      conditions.add('category = ?');
      args.add(category);
    }
    if (status != null && status.isNotEmpty) {
      conditions.add('status = ?');
      args.add(status);
    }

    if (conditions.isNotEmpty) {
      where = conditions.join(' AND ');
      whereArgs = args;
    }

    final maps = await db.query('spare_parts',
        where: where, whereArgs: whereArgs, orderBy: 'name ASC');
    return maps.map(SparePart.fromMap).toList();
  }

  Future<int> insertSparePart(SparePart part) async {
    final db = await database;
    return db.insert('spare_parts', part.toMap());
  }

  Future<void> updateSparePart(SparePart part) async {
    final db = await database;
    await db.update('spare_parts', part.toMap(),
        where: 'id = ?', whereArgs: [part.id]);
  }

  Future<void> deleteSparePart(int id) async {
    final db = await database;
    await db.delete('spare_parts', where: 'id = ?', whereArgs: [id]);
  }

  // ─── DOCUMENTS ──────────────────────────────────────────────────────────────

  Future<List<Document>> getDocuments() async {
    final db = await database;
    final maps = await db.query('documents', orderBy: 'added_at DESC');
    return maps.map(Document.fromMap).toList();
  }

  Future<int> insertDocument(Document doc) async {
    final db = await database;
    return db.insert('documents', doc.toMap());
  }

  Future<void> deleteDocument(int id) async {
    final db = await database;
    await db.delete('documents', where: 'id = ?', whereArgs: [id]);
  }

  // ─── REMINDERS ──────────────────────────────────────────────────────────────

  Future<List<Reminder>> getReminders() async {
    final db = await database;
    final maps = await db.query('reminders', orderBy: 'due_date ASC');
    return maps.map(Reminder.fromMap).toList();
  }

  Future<int> insertReminder(Reminder r) async {
    final db = await database;
    return db.insert('reminders', r.toMap());
  }

  Future<void> updateReminder(Reminder r) async {
    final db = await database;
    await db.update('reminders', r.toMap(),
        where: 'id = ?', whereArgs: [r.id]);
  }

  Future<void> deleteReminder(int id) async {
    final db = await database;
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  // ─── EXPENSES ───────────────────────────────────────────────────────────────

  Future<Map<String, double>> getExpenseSummary() async {
    final db = await database;

    final serviceResult = await db
        .rawQuery('SELECT COALESCE(SUM(cost), 0) as total FROM service_records');
    final partsResult = await db
        .rawQuery('SELECT COALESCE(SUM(price), 0) as total FROM spare_parts WHERE status = "installed"');
    final diagResult = await db
        .rawQuery('SELECT COALESCE(SUM(cost), 0) as total FROM diagnostics WHERE status = "resolved"');

    return {
      'service': (serviceResult.first['total'] as num?)?.toDouble() ?? 0,
      'parts': (partsResult.first['total'] as num?)?.toDouble() ?? 0,
      'diagnostics': (diagResult.first['total'] as num?)?.toDouble() ?? 0,
    };
  }

  Future<List<Map<String, dynamic>>> getMonthlyExpenses() async {
    final db = await database;
    return db.rawQuery('''
      SELECT
        strftime('%Y-%m', date) as month,
        SUM(cost) as total
      FROM service_records
      GROUP BY month
      ORDER BY month ASC
    ''');
  }

  // ─── BACKUP ─────────────────────────────────────────────────────────────────

  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'car_history.db');
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
