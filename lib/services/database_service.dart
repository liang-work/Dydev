import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/store_app.dart';
import '../models/dashboard_stats.dart';

/// SQLite database service for local data persistence.
///
/// Caches dashboard stats, user profile, and app list so the UI
/// can render immediately even when offline.
class DatabaseService {
  static Database? _db;

  /// Open (or create) the local database.
  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'dydev.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY,
            username TEXT NOT NULL,
            nickname TEXT,
            avatar TEXT,
            bio TEXT,
            email TEXT,
            phone TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS store_apps (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            slug TEXT,
            icon_url TEXT,
            current_version TEXT,
            status TEXT,
            download_count INTEGER DEFAULT 0,
            view_count INTEGER DEFAULT 0,
            rating_average REAL DEFAULT 0,
            rating_count INTEGER DEFAULT 0,
            review_count INTEGER DEFAULT 0,
            short_description TEXT,
            created_at TEXT,
            updated_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS dashboard_stats (
            id INTEGER PRIMARY KEY DEFAULT 1,
            my_app_count INTEGER DEFAULT 0,
            total_downloads INTEGER DEFAULT 0,
            review_count INTEGER DEFAULT 0,
            platform_app_count INTEGER DEFAULT 0,
            category_count INTEGER DEFAULT 0,
            developer_count INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  // ---- User ----

  /// Persist the current user profile.
  static Future<void> saveUser(User user) async {
    final db = await database;
    await db.insert('users', user.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Load the cached user profile, or null if none.
  static Future<User?> getUser() async {
    final db = await database;
    final rows = await db.query('users', limit: 1);
    if (rows.isEmpty) return null;
    return User.fromJson(rows.first);
  }

  /// Remove the cached user (used on logout).
  static Future<void> clearUser() async {
    final db = await database;
    await db.delete('users');
  }

  // ---- Store Apps ----

  /// Persist a list of store apps (replaces all existing rows).
  static Future<void> saveStoreApps(List<StoreApp> apps) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('store_apps');
      for (final app in apps) {
        await txn.insert('store_apps', app.toJson(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  /// Load all cached store apps.
  static Future<List<StoreApp>> getStoreApps() async {
    final db = await database;
    final rows = await db.query('store_apps', orderBy: 'id DESC');
    return rows.map((r) => StoreApp.fromJson(r)).toList();
  }

  // ---- Dashboard Stats ----

  /// Persist dashboard stats (single row, id=1).
  static Future<void> saveStats(DashboardStats stats) async {
    final db = await database;
    await db.insert('dashboard_stats', stats.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Load cached dashboard stats, or default zeroed instance.
  static Future<DashboardStats> getStats() async {
    final db = await database;
    final rows = await db.query('dashboard_stats', where: 'id = 1');
    if (rows.isEmpty) return DashboardStats();
    return DashboardStats.fromJson(rows.first);
  }

  /// Clear all cached data.
  static Future<void> clearAll() async {
    final db = await database;
    await db.delete('users');
    await db.delete('store_apps');
    await db.delete('dashboard_stats');
  }
}
