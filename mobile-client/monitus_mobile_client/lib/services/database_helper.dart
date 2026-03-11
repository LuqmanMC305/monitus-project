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

  // Method to handle the physical location of the database file
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
        translated_body TEXT, 
        language_code TEXT,
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

    // Calculate cutoff date ()
    final DateTime cutOffDate = DateTime.now().subtract(const Duration(seconds: 50));

    // Use ISO8601 date & time format for reliable SQL comparison
    final String cutoff = cutOffDate.toIso8601String();

    debugPrint("CHECK: Deleting alerts where received_at < $cutoff");

    // This deletes any alert where the 'received_at' date is older than cutoff date
    int deletedCount = await db.delete(
      'alerts',
      where: 'received_at < ?',
      whereArgs: [cutoff],
    );

    debugPrint("Cleanup Handshake: Deleted $deletedCount old alerts.");
    return deletedCount;
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

  // Method to Update Alert Status
  Future<int> updateAlertStatusByTitle(String title, String status) async {
  final db = await instance.database;

  return await db.update(
    'alerts',
    {'status': status}, // Set status to 'resolved'
    where: 'title = ?',  // Find the row where the title matches
    whereArgs: [title],
  );
 }

  // Method to save new translation into SQLite
  Future<int> updateAlertTranslation(int id, String translatedBody, String langCode) async {
    final db = await instance.database;
    return await db.update(
      'alerts',
      {
        'translated_body': translatedBody,
        'language_code': langCode,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

}
