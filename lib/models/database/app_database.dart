import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'db_constants.dart';
import 'migrations/migration_registry.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final basePath = await getDatabasesPath();
    final databasePath = path.join(basePath, DbConstants.databaseName);

    return openDatabase(
      databasePath,
      version: DbConstants.databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _runMigrations(db, 0, version);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _runMigrations(db, oldVersion, newVersion);
      },
    );
  }

  Future<void> _runMigrations(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    final migrations = [...migrationRegistry]
      ..sort((a, b) => a.version.compareTo(b.version));

    for (final migration in migrations) {
      if (migration.version > oldVersion && migration.version <= newVersion) {
        await migration.up(db);
      }
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
