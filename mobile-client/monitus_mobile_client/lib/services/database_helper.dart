import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Initialiser (waits until actually need to save or read an alert)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('monitus_local.db');
    return _database!;
  }

  // TEMPORARILY CODE FOR LOCAL MOBILE DATA PERSISTENT (WILL REMOVE IT LATER)
  Future<void> testDatabase() async {
    final db = await instance.database;
    final result = await db.query('alerts');
    debugPrint('--- LOCAL DATABASE DUMP ---');
    for (var row in result) {
      debugPrint('Alert ID ${row['id']}: ${row['title']} | Type: ${row['alert_type']}');
    }
    debugPrint('--- END OF DUMP (Total: ${result.length}) ---');
  }

  // Handles the physical location of the database file
  Future<Database> _initDB(String filePath) async {
    // Asks Android to locate private DB folder
    final dbPath = await getDatabasesPath();

    // Joins the folder path with  specific filename
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
    );
  }

  // Define Alert History table schema
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE alerts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        alert_type TEXT,
        received_at TEXT NOT NULL,
        status TEXT DEFAULT 'active'
      )
    ''');
  }

  // Method to save an incoming notification
  Future<int> insertAlert(Map<String, dynamic> alert) async {
    final db = await instance.database;
    return await db.insert('alerts', alert);
  }

  // Method to fetch all alerts for your Alert List screen
  Future<List<Map<String, dynamic>>> getAllAlerts() async {
    final db = await instance.database;
    return await db.query('alerts', orderBy: 'received_at DESC');
  }

  // Method to delete old alerts (> 14 days)
  Future<int> deleteOldAlerts() async {
    final db = await instance.database;
    // This deletes any alert where the 'received_at' date is older than 14 days
    return await db.delete(
      'alerts',
      where: 'received_at < ?',
      whereArgs: [DateTime.now().subtract(const Duration(days: 14)).toString()],
    );
  }

  // Method to Filter Resolved Alerts
  Future<List<Map<String, dynamic>>> getActiveAlerts() async {
    final db = await instance.database;

    // We only want alerts where is_resolved is 0 (false)
    return await db.query(
      'alerts', 
      where: 'status != ? OR status IS NULL', 
      whereArgs: ['resolved'], 
      orderBy: 'received_at DESC'
    );
  }
}
