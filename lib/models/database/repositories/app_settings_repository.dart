import 'package:sqflite/sqflite.dart';

import '../app_database.dart';
import '../db_constants.dart';

class AppRoutingSettings {
  const AppRoutingSettings({
    required this.routeMode,
    required this.trafficLightPenalty,
    required this.dirtRoadPenalty,
    required this.cobblestonePenalty,
    required this.asphaltBonus,
    required this.updatedAt,
  });

  final String routeMode;
  final double trafficLightPenalty;
  final double dirtRoadPenalty;
  final double cobblestonePenalty;
  final double asphaltBonus;
  final DateTime updatedAt;

  factory AppRoutingSettings.fromMap(Map<String, Object?> map) {
    return AppRoutingSettings(
      routeMode: map['route_mode'] as String,
      trafficLightPenalty: (map['traffic_light_penalty'] as num).toDouble(),
      dirtRoadPenalty: (map['dirt_road_penalty'] as num).toDouble(),
      cobblestonePenalty: (map['cobblestone_penalty'] as num).toDouble(),
      asphaltBonus: (map['asphalt_bonus'] as num).toDouble(),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

class AppSettingsRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<void> ensureDefaultSettings() async {
    final db = await _db;
    final now = DateTime.now().toUtc().toIso8601String();

    await db.insert(
      DbConstants.tableAppSettings,
      <String, Object?>{
        'id': 1,
        'route_mode': 'smooth',
        'traffic_light_penalty': 35,
        'dirt_road_penalty': 20,
        'cobblestone_penalty': 10,
        'asphalt_bonus': 15,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<AppRoutingSettings> getSettings() async {
    final db = await _db;
    final result = await db.query(
      DbConstants.tableAppSettings,
      where: 'id = ?',
      whereArgs: const <Object>[1],
      limit: 1,
    );

    if (result.isEmpty) {
      await ensureDefaultSettings();
      return getSettings();
    }

    return AppRoutingSettings.fromMap(result.first);
  }

  Future<void> updateSettings({
    String? routeMode,
    double? trafficLightPenalty,
    double? dirtRoadPenalty,
    double? cobblestonePenalty,
    double? asphaltBonus,
  }) async {
    final db = await _db;

    final changes = <String, Object?>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (routeMode != null) {
      changes['route_mode'] = routeMode;
    }
    if (trafficLightPenalty != null) {
      changes['traffic_light_penalty'] = trafficLightPenalty;
    }
    if (dirtRoadPenalty != null) {
      changes['dirt_road_penalty'] = dirtRoadPenalty;
    }
    if (cobblestonePenalty != null) {
      changes['cobblestone_penalty'] = cobblestonePenalty;
    }
    if (asphaltBonus != null) {
      changes['asphalt_bonus'] = asphaltBonus;
    }

    await db.update(
      DbConstants.tableAppSettings,
      changes,
      where: 'id = ?',
      whereArgs: const <Object>[1],
    );
  }
}
