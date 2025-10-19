// lib/database/db_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _db;
  DBHelper._init();

  // bumped DB version to include 'sound' column
  static const int _dbVersion = 7;
  static const String _defaultQuote =
      "Take care of your body. It’s the only place you have to live.";

  // -------------------- Init DB --------------------
  static Future<Database> initDb() async {
    if (_db != null) return _db!;
    String path = join(await getDatabasesPath(), 'caresync.db');
    _db = await openDatabase(
      path,
      version: _dbVersion,
      // enable foreign keys BEFORE onCreate/onUpgrade
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS medications(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            dosage TEXT,
            frequency TEXT,
            repeat TEXT,
            custom_days TEXT,
            time TEXT,
            sound TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS appointments(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            doctor_name TEXT NOT NULL,
            clinic_name TEXT NOT NULL,
            phone TEXT NOT NULL,
            date TEXT NOT NULL,
            time TEXT NOT NULL,
            notes TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS medication_times(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            medication_id INTEGER NOT NULL,
            time TEXT NOT NULL,
            FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS reminders(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            date TEXT,
            time TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS emergency_groups (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            group_name TEXT UNIQUE
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS emergency_contacts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            group_id INTEGER,
            contact_name TEXT,
            phone TEXT,
            isFavorite INTEGER DEFAULT 0,
            FOREIGN KEY (group_id) REFERENCES emergency_groups(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS vitals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            systolic INTEGER,
            diastolic INTEGER,
            sugar REAL,
            weight REAL,
            pulse INTEGER,
            created_at TEXT
          )
        ''');

        // Initialize quotes table and default quote
        await DBHelper.instance.initQuoteTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS medication_times(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              medication_id INTEGER NOT NULL,
              time TEXT NOT NULL,
              FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE
            )
          ''');
        }

        if (oldVersion < 6) {
          // Add isFavorite column if it doesn't exist
          await db.execute(
              "ALTER TABLE emergency_contacts ADD COLUMN isFavorite INTEGER DEFAULT 0");
        }

        if (oldVersion < 7) {
          // Add sound column for medication notification sound
          await db.execute("ALTER TABLE medications ADD COLUMN sound TEXT");
        }
      },
    );
    return _db!;
  }

  // -------------------- Quotes Helpers --------------------
  // NOTE: instance method — called above as DBHelper.instance.initQuoteTable(db)
  Future<void> initQuoteTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_quote (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quote TEXT
      )
    ''');

    final countRes = await db.rawQuery('SELECT COUNT(*) as c FROM user_quote');
    final count = Sqflite.firstIntValue(countRes) ?? 0;
    if (count == 0) {
      await db.insert(
        'user_quote',
        {'quote': _defaultQuote},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<String> getQuote() async {
    final db = await DBHelper.initDb();
    final res = await db.query('user_quote', limit: 1);
    if (res.isNotEmpty && res.first['quote'] != null) {
      return res.first['quote'] as String;
    }
    return _defaultQuote;
  }

  Future<void> updateQuote(String newQuote) async {
    final db = await DBHelper.initDb();
    final existing = await db.query('user_quote', limit: 1);
    if (existing.isNotEmpty) {
      final id = existing.first['id'] as int;
      await db.update('user_quote', {'quote': newQuote},
          where: 'id = ?', whereArgs: [id]);
    } else {
      await db.insert('user_quote', {'quote': newQuote});
    }
  }

  // -------------------- Medication CRUD --------------------
  Future<int> insertMedication(Map<String, dynamic> medication) async {
    final db = await initDb();
    return await db.insert('medications', medication);
  }

  static Future<int> updateMedication(int id, Map<String, dynamic> medication) async {
    final db = await initDb();
    return await db.update('medications', medication, where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> deleteMedication(int id) async {
    final db = await initDb();
    return await db.delete('medications', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Map<String, dynamic>>> getMedications() async {
    final db = await initDb();
    return await db.query('medications');
  }

  // -------------------- Medication Times CRUD --------------------
  static Future<int> insertMedicationTime(int medId, String time) async {
    final db = await initDb();
    return await db.insert('medication_times', {
      'medication_id': medId,
      'time': time,
    });
  }

  static Future<List<Map<String, dynamic>>> getMedicationTimes(int medId) async {
    final db = await initDb();
    return await db.query('medication_times',
        where: 'medication_id = ?', whereArgs: [medId]);
  }

  static Future<int> deleteMedicationTimes(int medId) async {
    final db = await initDb();
    return await db.delete('medication_times',
        where: 'medication_id = ?', whereArgs: [medId]);
  }

  // -------------------- Upcoming Medication FIXED --------------------
  Future<List<Map<String, dynamic>>> getUpcomingMedications() async {
    final db = await DBHelper.initDb();

    // Current time in HH:mm (24h)
    final now = DateFormat('HH:mm').format(DateTime.now());

    final result = await db.rawQuery('''
      SELECT m.id, m.name, mt.time
      FROM medications m
      JOIN medication_times mt ON m.id = mt.medication_id
      WHERE mt.time >= ?
      ORDER BY mt.time ASC
    ''', [now]);

    return result;
  }

  // -------------------- Appointments, Vitals, etc --------------------
  static Future<int> insertAppointment(Map<String, dynamic> appointment) async {
    final db = await initDb();
    return await db.insert('appointments', appointment);
  }

  static Future<int> updateAppointment(int id, Map<String, dynamic> appointment) async {
    final db = await initDb();
    return await db.update('appointments', appointment, where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> deleteAppointment(int id) async {
    final db = await initDb();
    return await db.delete('appointments', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Map<String, dynamic>>> getAppointments() async {
    final db = await initDb();
    return await db.query('appointments', orderBy: 'date, time');
  }

  // -------------------- Vitals CRUD --------------------
  static Future<int> insertVital(Map<String, dynamic> data) async {
    final db = await DBHelper.initDb();
    return await db.insert('vitals', data);
  }

  static Future<List<Map<String, dynamic>>> getVitals() async {
    final db = await DBHelper.initDb();
    return await db.query('vitals', orderBy: "created_at DESC");
  }

  static Future<int> deleteVital(int id) async {
    final db = await DBHelper.initDb();
    return await db.delete('vitals', where: 'id = ?', whereArgs: [id]);
  }

  static Future<Map<String, double>> getVitalAverages() async {
    final db = await DBHelper.initDb();
    final result = await db.rawQuery('''
      SELECT 
        AVG(systolic) as avg_systolic,
        AVG(diastolic) as avg_diastolic,
        AVG(sugar) as avg_sugar,
        AVG(weight) as avg_weight,
        AVG(pulse) as avg_pulse
      FROM vitals
    ''');

    return {
      'avg_systolic': (result[0]['avg_systolic'] as num?)?.toDouble() ?? 0,
      'avg_diastolic': (result[0]['avg_diastolic'] as num?)?.toDouble() ?? 0,
      'avg_sugar': (result[0]['avg_sugar'] as num?)?.toDouble() ?? 0,
      'avg_weight': (result[0]['avg_weight'] as num?)?.toDouble() ?? 0,
      'avg_pulse': (result[0]['avg_pulse'] as num?)?.toDouble() ?? 0,
    };
  }

  // -------------------- EmergencyContacts CRUD --------------------
  Future<int> insertEmergencyGroup(String groupName) async {
    final db = await initDb();
    return await db.insert(
      'emergency_groups',
      {'group_name': groupName},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getEmergencyGroups() async {
    final db = await initDb();
    return await db.query('emergency_groups', orderBy: 'group_name ASC');
  }

  Future<int> insertEmergencyContact(int groupId, String name, String phone) async {
    final db = await initDb();
    return await db.insert('emergency_contacts', {
      'group_id': groupId,
      'contact_name': name,
      'phone': phone,
    });
  }

  Future<int> deleteEmergencyGroup(int groupId) async {
    final db = await initDb();
    return await db.delete('emergency_groups', where: 'id = ?', whereArgs: [groupId]);
  }

  Future<int> deleteEmergencyContact(int id) async {
    final db = await initDb();
    return await db.delete('emergency_contacts', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<int, Map<String, dynamic>>> getAllEmergencyContacts() async {
    final db = await initDb();

    final groups = await db.query('emergency_groups', orderBy: 'group_name ASC');
    final contacts = await db.query('emergency_contacts');

    Map<int, Map<String, dynamic>> grouped = {};
    for (var g in groups) {
      grouped[g['id'] as int] = {
        "group_name": g['group_name'],
        "contacts": contacts.where((c) => c['group_id'] == g['id']).toList(),
      };
    }
    return grouped;
  }

  // -------- Favorite Emergency Contact Helpers --------
  // Toggle favorite contact (supports multiple favorites)
  Future<void> setFavoriteContact(int contactId, {bool unfavIfAlreadyFav = true}) async {
    final db = await initDb();

    // Check if this contact is already favorite
    final current = await db.query(
      'emergency_contacts',
      where: 'id = ? AND isFavorite = 1',
      whereArgs: [contactId],
    );

    if (current.isNotEmpty && unfavIfAlreadyFav) {
      // Contact is already favorite → unfavorite it
      await db.update(
        'emergency_contacts',
        {'isFavorite': 0},
        where: 'id = ?',
        whereArgs: [contactId],
      );
    } else {
      // Set favorite
      await db.update(
        'emergency_contacts',
        {'isFavorite': 1},
        where: 'id = ?',
        whereArgs: [contactId],
      );
    }
  }

  // Fetch all favorite contacts
  Future<List<Map<String, dynamic>>> getFavoriteContact() async {
    final db = await initDb();
    final res = await db.query(
      'emergency_contacts',
      where: 'isFavorite = ?',
      whereArgs: [1],
      orderBy: 'contact_name ASC',
    );
    return res;
  }

  // -------------------- Other Helpers --------------------
  Future<List<Map<String, dynamic>>> getNextMedication() async {
    final db = await initDb();
    return await db.query(
      'medications',
      orderBy: 'time ASC',
      limit: 1,
    );
  }

  Future<List<Map<String, dynamic>>> getNextAppointment() async {
    final db = await initDb();
    return await db.query(
      'appointments',
      orderBy: 'date ASC',
      limit: 1,
    );
  }

  Future<List<Map<String, dynamic>>> getRemindersForToday() async {
    final db = await initDb();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return await db.query(
      'reminders',
      where: 'date = ?',
      whereArgs: [today],
      orderBy: 'time ASC',
    );
  }

  Future<Map<String, dynamic>?> getNextMedicationWithTime() async {
    final db = await DBHelper.initDb();
    final result = await db.rawQuery('''
      SELECT m.id, m.name, mt.time
      FROM medications m
      JOIN medication_times mt ON m.id = mt.medication_id
      ORDER BY time ASC
      LIMIT 1
    ''');

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getLatestVitals() async {
    final db = await DBHelper.initDb();
    final result = await db.query(
      'vitals',
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }
}
