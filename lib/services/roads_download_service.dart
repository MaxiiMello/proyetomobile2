import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/graph_geometry.dart';

class RoadsDownloadService {
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';
  static const Duration _timeout = Duration(seconds: 25);

  Future<List<RoadGeometry>> downloadRoads({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    final radiusMeters = (radiusKm * 1000).round();
    final query = _buildOverpassQuery(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
    );

    debugPrint(' Baixando geometria OSM (raio: ${radiusMeters}m)');

    final response = await http
        .post(
          Uri.parse(_overpassUrl),
          headers: const {
            'Content-Type': 'application/x-www-form-urlencoded',
            'User-Agent': 'SinalVerde-App/1.0 (Flutter)',
          },
          body: {'data': query},
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('Falha ao baixar dados OSM (${response.statusCode})');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = payload['elements'] as List<dynamic>? ?? [];

    final nodes = <int, GeoPoint>{};
    for (final element in elements) {
      final type = element['type'];
      if (type == 'node') {
        final id = element['id'] as int?;
        final lat = element['lat'] as num?;
        final lon = element['lon'] as num?;
        if (id == null || lat == null || lon == null) {
          continue;
        }
        nodes[id] = GeoPoint(lat.toDouble(), lon.toDouble());
      }
    }

    final roads = <RoadGeometry>[];
    for (final element in elements) {
      if (element['type'] != 'way') {
        continue;
      }

      final id = element['id'] as int?;
      final nodeIds = element['nodes'] as List<dynamic>? ?? [];
      if (id == null || nodeIds.length < 2) {
        continue;
      }

      final tags = element['tags'] as Map<String, dynamic>? ?? {};
      final coordinates = <GeoPoint>[];
      for (final nodeId in nodeIds) {
        final node = nodes[nodeId as int];
        if (node != null) {
          coordinates.add(node);
        }
      }

      if (coordinates.length < 2) {
        continue;
      }

      final name = (tags['name'] as String?) ?? 'Rua sem nome';
      final surfaceType = _normalizeSurface(tags['surface'] as String?);
      final oneWay = _parseOneWay(tags['oneway'] as String?);
      final speedLimit = _parseSpeed(tags['maxspeed'] as String?) ??
          _defaultSpeed(tags['highway'] as String?);

      roads.add(RoadGeometry(
        id: 'way_$id',
        name: name,
        coordinates: coordinates,
        surfaceType: surfaceType,
        oneWay: oneWay,
        speedLimitKmh: speedLimit,
        hasTrafficLight: false,
      ));
    }

    if (roads.isEmpty) {
      throw Exception('Nenhuma via encontrada para o raio selecionado.');
    }

    debugPrint(' Geometrias baixadas: ${roads.length} vias');
    return roads;
  }

  String _buildOverpassQuery({
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) {
    return '[out:json][timeout:25];\n'
        'way["highway"](around:$radiusMeters,$latitude,$longitude);\n'
        '(._;>;);\n'
        'out body;';
  }

  bool _parseOneWay(String? value) {
    if (value == null) {
      return false;
    }
    final normalized = value.toLowerCase().trim();
    return normalized == 'yes' ||
        normalized == '1' ||
        normalized == 'true' ||
        normalized == 'forward';
  }

  int? _parseSpeed(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final match = RegExp(r'\d+').firstMatch(value);
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(0) ?? '');
  }

  int _defaultSpeed(String? highway) {
    switch (highway) {
      case 'motorway':
      case 'trunk':
        return 80;
      case 'primary':
      case 'secondary':
        return 60;
      case 'tertiary':
      case 'residential':
        return 40;
      default:
        return 30;
    }
  }

  String _normalizeSurface(String? surface) {
    if (surface == null) {
      return 'asfalto';
    }
    final normalized = surface.toLowerCase().trim();
    if (normalized.contains('gravel') ||
        normalized.contains('unpaved') ||
        normalized.contains('dirt') ||
        normalized.contains('ground') ||
        normalized.contains('sand')) {
      return 'terra';
    }
    return 'asfalto';
  }
}
