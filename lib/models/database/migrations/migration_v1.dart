import 'package:sqflite/sqflite.dart';

import '../db_constants.dart';
import 'migration.dart';

class MigrationV1 implements DatabaseMigration {
  @override
  int get version => 1;

  @override
  Future<void> up(Database db) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE ${DbConstants.tableMapPackages} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        city_code TEXT NOT NULL UNIQUE,
        city_name TEXT NOT NULL,
        region_name TEXT,
        data_version TEXT NOT NULL,
        mbtiles_path TEXT NOT NULL,
        graph_path TEXT NOT NULL,
        is_premium INTEGER NOT NULL DEFAULT 0,
        installed_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE ${DbConstants.tableIntersections} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        package_id INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        has_traffic_light INTEGER NOT NULL DEFAULT 0,
        traffic_light_penalty REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (package_id)
          REFERENCES ${DbConstants.tableMapPackages}(id)
          ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE ${DbConstants.tableRoadSegments} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        package_id INTEGER NOT NULL,
        from_intersection_id INTEGER NOT NULL,
        to_intersection_id INTEGER NOT NULL,
        name TEXT,
        distance_m REAL NOT NULL,
        speed_limit_kmh REAL,
        is_one_way INTEGER NOT NULL DEFAULT 0,
        surface_type TEXT NOT NULL,
        traffic_light_count INTEGER NOT NULL DEFAULT 0,
        base_weight REAL NOT NULL DEFAULT 1,
        FOREIGN KEY (package_id)
          REFERENCES ${DbConstants.tableMapPackages}(id)
          ON DELETE CASCADE,
        FOREIGN KEY (from_intersection_id)
          REFERENCES ${DbConstants.tableIntersections}(id)
          ON DELETE CASCADE,
        FOREIGN KEY (to_intersection_id)
          REFERENCES ${DbConstants.tableIntersections}(id)
          ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE ${DbConstants.tableRouteHistory} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        started_at TEXT NOT NULL,
        finished_at TEXT,
        origin_lat REAL NOT NULL,
        origin_lng REAL NOT NULL,
        destination_lat REAL NOT NULL,
        destination_lng REAL NOT NULL,
        total_distance_m REAL NOT NULL,
        total_estimated_minutes REAL,
        total_score REAL NOT NULL,
        package_id INTEGER,
        FOREIGN KEY (package_id)
          REFERENCES ${DbConstants.tableMapPackages}(id)
          ON DELETE SET NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE ${DbConstants.tableAppSettings} (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        route_mode TEXT NOT NULL DEFAULT 'smooth',
        traffic_light_penalty REAL NOT NULL DEFAULT 35,
        dirt_road_penalty REAL NOT NULL DEFAULT 20,
        cobblestone_penalty REAL NOT NULL DEFAULT 10,
        asphalt_bonus REAL NOT NULL DEFAULT 15,
        updated_at TEXT NOT NULL
      )
    ''');

    batch.execute(
      'CREATE INDEX idx_intersections_package ON ${DbConstants.tableIntersections}(package_id)',
    );
    batch.execute(
      'CREATE INDEX idx_segments_package ON ${DbConstants.tableRoadSegments}(package_id)',
    );
    batch.execute(
      'CREATE INDEX idx_segments_from_to ON ${DbConstants.tableRoadSegments}(from_intersection_id, to_intersection_id)',
    );

    await batch.commit(noResult: true);
  }
}
