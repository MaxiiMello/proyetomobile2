import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'dart:async';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/database_models.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  static bool _isAvailable = true;
  static String? _lastError;

  // In-memory fallback storage (for web platforms without SQLite support)
  static final Map<String, Map<String, dynamic>> _memoryStorage = {};

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  /// Check if database is available
  static bool get isAvailable => _isAvailable;

  /// Get the last error message
  static String? get lastError => _lastError;

  static bool _ffiInitialized = false;

  static Future<void> ensureInitialized() async {
    if (_ffiInitialized) return;

    if (!kIsWeb &&
        (Platform.isWindows ||
         Platform.isLinux ||
         Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      debugPrint('✅ databaseFactory configurado no DatabaseService');
    }

    _ffiInitialized = true;
  }

  Future<Database?> get database async {
    if (!_isAvailable) {
      return null; // Database not available, will use memory fallback
    }
    try {
      if (_database != null) return _database!;
      _database = await _initDatabase();
      return _database!;
    } catch (e) {
      _isAvailable = false;
      _lastError = e.toString();
      print('⚠️ Database initialization failed, using memory storage: $e');
      return null;
    }
  }

  Future<Database> _initDatabase() async {
    await ensureInitialized();

    String path = join(await getDatabasesPath(), 'sinal_verde.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createTables,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              'ALTER TABLE ruas ADD COLUMN oneWay INTEGER NOT NULL DEFAULT 0');
        }
      },
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Tabela de quadros geográficos baixados
    await db.execute('''
      CREATE TABLE IF NOT EXISTS quadros_geograficos (
        id TEXT PRIMARY KEY,
        latitudeCentro REAL NOT NULL,
        longitudeCentro REAL NOT NULL,
        raioKm REAL NOT NULL,
        dataDownload TEXT NOT NULL,
        completo INTEGER NOT NULL
      )
    ''');

    // Tabela de nós de intersecção
    await db.execute('''
      CREATE TABLE IF NOT EXISTS nos_interseccao (
        id TEXT PRIMARY KEY,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        ruasConectadas TEXT NOT NULL,
        tileId TEXT NOT NULL,
        FOREIGN KEY(tileId) REFERENCES quadros_geograficos(id)
      )
    ''');

    // Tabela de ruas
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ruas (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        lat1 REAL NOT NULL,
        lon1 REAL NOT NULL,
        lat2 REAL NOT NULL,
        lon2 REAL NOT NULL,
        distanciaMetros REAL NOT NULL,
        tipo TEXT NOT NULL,
        temSemafo INTEGER NOT NULL,
        velocidadekmh INTEGER NOT NULL,
        oneWay INTEGER NOT NULL DEFAULT 0,
        tileId TEXT NOT NULL,
        FOREIGN KEY(tileId) REFERENCES quadros_geograficos(id)
      )
    ''');

    // Índices para melhor performance
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_ruas_tileId ON ruas(tileId)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_nos_tileId ON nos_interseccao(tileId)');
  }

  Future<void> salvarQuadro(QuadroGeografico quadro) async {
    final db = await database ?? (throw Exception('Database not available'));
    await db.insert(
      'quadros_geograficos',
      quadro.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<QuadroGeografico?> obterQuadro(String id) async {
    final db = await database;
    if (db == null) return null;

    try {
      final result = await db.query(
        'quadros_geograficos',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (result.isEmpty) return null;
      return QuadroGeografico.fromMap(result.first);
    } catch (e) {
      debugPrint('Error fetching quadro: $e');
      return null;
    }
  }

  Future<List<QuadroGeografico>> obterTodosQuadros() async {
    final db = await database;
    if (db == null) return [];

    try {
      final result = await db.query('quadros_geograficos');
      return result.map((map) => QuadroGeografico.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error fetching all quadros: $e');
      return [];
    }
  }

  Future<void> deletarQuadro(String id) async {
    final db = await database;
    if (db == null) return;

    try {
      // Deletar em cascata
      await db.delete('ruas', where: 'tileId = ?', whereArgs: [id]);
      await db.delete('nos_interseccao', where: 'tileId = ?', whereArgs: [id]);
      await db.delete('quadros_geograficos', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('Error deleting quadro: $e');
    }
  }

  // ===== OPERAÇÕES RUAS =====

  Future<void> salvarRua(RuaBD rua) async {
    final db = await database;
    if (db == null) return;

    try {
      await db.insert(
        'ruas',
        rua.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error saving rua: $e');
    }
  }

  Future<void> salvarMuitasRuas(List<RuaBD> ruas) async {
    final db = await database;
    if (db == null) return;

    try {
      final batch = db.batch();

      for (var rua in ruas) {
        batch.insert(
          'ruas',
          rua.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error saving multiple ruas: $e');
    }
  }

  Future<RuaBD?> obterRua(String id) async {
    final db = await database;
    if (db == null) return null;

    try {
      final result = await db.query(
        'ruas',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (result.isEmpty) return null;
      return RuaBD.fromMap(result.first);
    } catch (e) {
      debugPrint('Error fetching rua: $e');
      return null;
    }
  }

  Future<List<RuaBD>> obterRuasDoQuadro(String tileId) async {
    final db = await database;
    if (db == null) return [];

    try {
      final result = await db.query(
        'ruas',
        where: 'tileId = ?',
        whereArgs: [tileId],
      );
      return result.map((map) => RuaBD.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error fetching ruas for quadro: $e');
      return [];
    }
  }

  Future<List<RuaBD>> obterRuasProximasAGPS(
      double latitude, double longitude, double raioKm) async {
    final db = await database;
    if (db == null) return [];

    try {
      // Calcular bounding box
      const raioTerranoKm = 6371.0;
      final deltaLatitude = (raioKm / raioTerranoKm) * (180 / 3.14159265359);
      final latEmRadianos = latitude * 3.14159265359 / 180;
      final deltaLongitude = (raioKm / (raioTerranoKm * (180 / 3.14159265359))) *
          (180 / (3.14159265359 * math.cos(latEmRadianos)));

      final lat1 = latitude - deltaLatitude;
      final lat2 = latitude + deltaLatitude;
      final lon1 = longitude - deltaLongitude;
      final lon2 = longitude + deltaLongitude;

      // Query ruas que intersectam com a bounding box
      final result = await db.rawQuery('''
        SELECT DISTINCT * FROM ruas 
        WHERE (lat1 BETWEEN ? AND ? OR lat2 BETWEEN ? AND ?)
          AND (lon1 BETWEEN ? AND ? OR lon2 BETWEEN ? AND ?)
      ''', [lat1, lat2, lat1, lat2, lon1, lon2, lon1, lon2]);

      return result.map((map) => RuaBD.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error fetching nearby ruas: $e');
      return [];
    }
  }

  Future<void> deletarRuasDoQuadro(String tileId) async {
    final db = await database;
    if (db == null) return;

    try {
      await db.delete('ruas', where: 'tileId = ?', whereArgs: [tileId]);
    } catch (e) {
      debugPrint('Error deleting ruas for quadro: $e');
    }
  }

  // ===== OPERAÇÕES NÓS DE INTERSECÇÃO =====

  Future<void> salvarNo(NoInterseccaoDB no) async {
    final db = await database;
    if (db == null) return;

    try {
      await db.insert(
        'nos_interseccao',
        no.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error saving no: $e');
    }
  }

  Future<void> salvarMuitosNos(List<NoInterseccaoDB> nos) async {
    final db = await database;
    if (db == null) return;

    try {
      final batch = db.batch();

      for (var no in nos) {
        batch.insert(
          'nos_interseccao',
          no.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error saving multiple nos: $e');
    }
  }

  Future<NoInterseccaoDB?> obterNo(String id) async {
    final db = await database;
    if (db == null) return null;

    try {
      final result = await db.query(
        'nos_interseccao',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (result.isEmpty) return null;
      return NoInterseccaoDB.fromMap(result.first);
    } catch (e) {
      debugPrint('Error fetching no: $e');
      return null;
    }
  }

  Future<List<NoInterseccaoDB>> obterNosDoQuadro(String tileId) async {
    final db = await database;
    if (db == null) return [];

    try {
      final result = await db.query(
        'nos_interseccao',
        where: 'tileId = ?',
        whereArgs: [tileId],
      );
      return result.map((map) => NoInterseccaoDB.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error fetching nos for quadro: $e');
      return [];
    }
  }

  Future<List<NoInterseccaoDB>> obterNosProximosAGPS(
      double latitude, double longitude, double raioKm) async {
    final db = await database;
    if (db == null) return [];

    try {
      // Usar a mesma bounding box das ruas
      const raioTerranoKm = 6371.0;
      final deltaLatitude = (raioKm / raioTerranoKm) * (180 / 3.14159265359);
      final latEmRadianos = latitude * 3.14159265359 / 180;
      final deltaLongitude = (raioKm / (raioTerranoKm * (180 / 3.14159265359))) *
          (180 / (3.14159265359 * math.cos(latEmRadianos)));

      final lat1 = latitude - deltaLatitude;
      final lat2 = latitude + deltaLatitude;
      final lon1 = longitude - deltaLongitude;
      final lon2 = longitude + deltaLongitude;

      final result = await db.rawQuery('''
        SELECT * FROM nos_interseccao 
        WHERE latitude BETWEEN ? AND ? AND longitude BETWEEN ? AND ?
      ''', [lat1, lat2, lon1, lon2]);

      return result.map((map) => NoInterseccaoDB.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error fetching nearby nos: $e');
      return [];
    }
  }

  Future<void> deletarNosDoQuadro(String tileId) async {
    final db = await database;
    if (db == null) return;

    try {
      await db.delete('nos_interseccao', where: 'tileId = ?', whereArgs: [tileId]);
    } catch (e) {
      debugPrint('Error deleting nos for quadro: $e');
    }
  }

  // ===== UTILITÁRIOS =====

  Future<int> obterTamanhoDBemKB() async {
    final db = await database;
    if (db == null) return 0;

    try {
      final result = await db.rawQuery('PRAGMA page_count;');
      final pageCount = (result.firstOrNull?['page_count'] as int?) ?? 0;

      final result2 = await db.rawQuery('PRAGMA page_size;');
      final pageSize = (result2.firstOrNull?['page_size'] as int?) ?? 4096;

      return (pageCount * pageSize) ~/ 1024;
    } catch (e) {
      debugPrint('Error calculating database size: $e');
      return 0;
    }
  }

  Future<void> limparBancoDados() async {
    final db = await database;
    if (db == null) return;

    try {
      await db.delete('ruas');
      await db.delete('nos_interseccao');
      await db.delete('quadros_geograficos');
    } catch (e) {
      debugPrint('Error clearing database: $e');
    }
  }

  Future<void> fecharBancoDados() async {
    final db = await database;
    if (db == null) return;

    try {
      await db.close();
    } catch (e) {
      debugPrint('Error closing database: $e');
    }
  }
}
