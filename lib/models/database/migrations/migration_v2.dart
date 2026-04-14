import 'package:sqflite/sqflite.dart';

import '../db_constants.dart';
import 'migration.dart';

class MigrationV2 implements DatabaseMigration {
  @override
  int get version => 2;

  @override
  Future<void> up(Database db) async {
    final batch = db.batch();

    // Crear tabla de usuarios con autenticación
    batch.execute('''
      CREATE TABLE ${DbConstants.tableUsers} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        preferred_city_code TEXT,
        subscription_plan TEXT NOT NULL DEFAULT 'essential',
        subscription_end_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_login TEXT
      )
    ''');

    // Crear índice para búsquedas rápidas de email
    batch.execute(
      'CREATE UNIQUE INDEX idx_users_email ON ${DbConstants.tableUsers}(email)',
    );

    // Agregar columna user_id a route_history
    batch.execute('''
      ALTER TABLE ${DbConstants.tableRouteHistory}
      ADD COLUMN user_id INTEGER REFERENCES ${DbConstants.tableUsers}(id) ON DELETE CASCADE
    ''');

    await batch.commit(noResult: true);
  }
}
