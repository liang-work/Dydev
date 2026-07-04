import 'dart:io' as io;

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/store_app.dart';
import '../models/dashboard_stats.dart';
import 'logger_service.dart';

/// SQLite database service for local data persistence.
///
/// Caches dashboard stats, user profile, and app list so the UI
/// can render immediately even when offline.
///
/// IMPORTANT: On desktop platforms (Windows / Linux / macOS) you must
/// initialise the FFI database factory in [main] before any DB call:
/// ```dart
/// sqfliteFfiInit();
/// databaseFactory = databaseFactoryFfi;
/// ```
class DatabaseService {
  static const _tag = 'DatabaseService';
  static Database? _db;

  /// Open (or create) the local database.
  static Future<Database> get database async {
    if (_db != null) return _db!;
    LoggerService.i(_tag, 'Initialising database ...');
    _db = await _init();
    LoggerService.d(_tag, 'Database ready');
    return _db!;
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY,
        username TEXT NOT NULL,
        nickname TEXT,
        avatar TEXT,
        bio TEXT,
        email TEXT,
        phone TEXT,
        date_joined TEXT DEFAULT '',
        last_login TEXT DEFAULT '',
        is_active INTEGER DEFAULT 1
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
        total_reviews INTEGER DEFAULT 0,
        published_app_count INTEGER DEFAULT 0
      )
    ''');
  }

  /// Convert Dart bool → int (1/0) recursively in a map for sqflite compatibility.
  static Map<String, dynamic> _toDbMap(Map<String, dynamic> map) {
    return map.map((String k, dynamic v) {
      if (v is bool) return MapEntry<String, dynamic>(k, v ? 1 : 0);
      if (v is Map) return MapEntry<String, dynamic>(k, _toDbMap(v.cast<String, dynamic>()));
      return MapEntry<String, dynamic>(k, v);
    });
  }

  static Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'dydev.db');
    LoggerService.d(_tag, 'Database path: $path');

    // Delete stale database files (including WAL/SHM) to ensure fresh schema.
    for (final suffix in ['', '-wal', '-shm']) {
      final f = io.File('$path$suffix');
      if (await f.exists()) {
        await f.delete();
        LoggerService.d(_tag, 'Removed stale DB file: $path$suffix');
      }
    }

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        LoggerService.i(_tag, 'Creating database tables (v$version)');
        await _createTables(db);
      },
    );
  }

  // ---- User ----

  /// Persist the current user profile.
  static Future<void> saveUser(User user) async {
    LoggerService.d(_tag, 'saveUser(${user.username})');
    final db = await database;
    await db.insert('users', _toDbMap(user.toJson()),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Load the cached user profile, or null if none.
  static Future<User?> getUser() async {
    LoggerService.d(_tag, 'getUser');
    final db = await database;
    final rows = await db.query('users', limit: 1);
    if (rows.isEmpty) return null;
    final user = User.fromJson(rows.first);
    LoggerService.d(_tag, 'Loaded cached user: ${user.username}');
    return user;
  }

  /// Remove the cached user (used on logout).
  static Future<void> clearUser() async {
    LoggerService.d(_tag, 'clearUser');
    final db = await database;
    await db.delete('users');
  }

  // ---- Store Apps ----

  /// Persist a list of store apps (replaces all existing rows).
  static Future<void> saveStoreApps(List<StoreApp> apps) async {
    LoggerService.d(_tag, 'saveStoreApps(count=${apps.length})');
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('store_apps');
      for (final app in apps) {
        await txn.insert('store_apps', _toDbMap(app.toJson()),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  /// Load all cached store apps.
  static Future<List<StoreApp>> getStoreApps() async {
    LoggerService.d(_tag, 'getStoreApps');
    final db = await database;
    final rows = await db.query('store_apps', orderBy: 'id DESC');
    LoggerService.d(_tag, 'Loaded ${rows.length} cached apps');
    return rows.map((r) => StoreApp.fromJson(r)).toList();
  }

  // ---- Dashboard Stats ----

  /// Persist dashboard stats (single row, id=1).
  static Future<void> saveStats(DashboardStats stats) async {
    LoggerService.d(_tag, 'saveStats');
    final db = await database;
    await db.insert('dashboard_stats', _toDbMap(stats.toJson()),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Load cached dashboard stats, or default zeroed instance.
  static Future<DashboardStats> getStats() async {
    LoggerService.d(_tag, 'getStats');
    final db = await database;
    final rows = await db.query('dashboard_stats', where: 'id = 1');
    if (rows.isEmpty) {
      LoggerService.d(_tag, 'No cached stats, returning defaults');
      return DashboardStats();
    }
    return DashboardStats.fromJson(rows.first);
  }

  /// Clear all cached data.
  static Future<void> clearAll() async {
    LoggerService.i(_tag, 'Clearing all cached data');
    final db = await database;
    await db.delete('users');
    await db.delete('store_apps');
    await db.delete('dashboard_stats');
  }
}
