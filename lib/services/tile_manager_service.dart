import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/database_models.dart';
import '../models/graph_geometry.dart';
import '../models/route_models.dart';
import 'database_service.dart';

class TileManagerService {
  static final TileManagerService _instance = TileManagerService._internal();
  final DatabaseService _dbService = DatabaseService();

  factory TileManagerService() {
    return _instance;
  }

  TileManagerService._internal();

  static const double RAIO_QUADRO_KM = 5.0; // Raio padrão de cada quadro

  /// Gera ID de um quadro geográfico baseado em lat/lon
  static String gerarIdQuadro(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(2)},${longitude.toStringAsFixed(2)}';
  }

  /// Verifica se um quadro geográfico foi baixado localmente
  Future<bool> quadroFoiBaixado(double latitude, double longitude) async {
    if (kIsWeb) {
      return false;
    }
    final id = gerarIdQuadro(latitude, longitude);
    final quadro = await _dbService.obterQuadro(id);
    return quadro != null && quadro.completo;
  }

  /// Carrega ou cria um quadro geográfico
  Future<QuadroGeografico> obterOuCriarQuadro(
      double latitude, double longitude) async {
    if (kIsWeb) {
      return QuadroGeografico(
        id: gerarIdQuadro(latitude, longitude),
        latitudeCentro: latitude,
        longitudeCentro: longitude,
        raioKm: RAIO_QUADRO_KM,
        dataDownload: DateTime.now(),
        completo: true,
      );
    }
    final id = gerarIdQuadro(latitude, longitude);
    var quadro = await _dbService.obterQuadro(id);

    if (quadro == null) {
      quadro = QuadroGeografico(
        id: id,
        latitudeCentro: latitude,
        longitudeCentro: longitude,
        raioKm: RAIO_QUADRO_KM,
        dataDownload: DateTime.now(),
        completo: false,
      );
      await _dbService.salvarQuadro(quadro);
    }

    return quadro;
  }

  /// Constrói grafo a partir de dados no BD para uma área
  Future<Map<String, NoRota>> construirGrafoDoQuadro(
      double latitude, double longitude) async {
    print('🔧 CONSTRUINDO GRAFO DO QUADRO');
    print('📍 Centro: Lat: $latitude, Lon: $longitude');

    if (kIsWeb) {
      throw Exception('Grafo offline requer SQLite.');
    }

    final quadro = await obterOuCriarQuadro(latitude, longitude);
    print('📦 Quadro ID: ${quadro.id}, Raio: ${quadro.raioKm}km, Completo: ${quadro.completo}');

    // Check if database is actually available
    final db = await _dbService.database;
    if (db == null || !DatabaseService.isAvailable) {
      throw Exception('Banco de dados não disponível');
    }

    final ruas = await _dbService.obterRuasDoQuadro(quadro.id);
    final nos = await _dbService.obterNosDoQuadro(quadro.id);

    if (ruas.isEmpty || nos.isEmpty) {
      throw Exception('Quadro sem dados. Baixe a região antes de usar.');
    }

    print('📊 Carregado: ${ruas.length} ruas, ${nos.length} nós');

    // Construir mapa de nós com suas conexões
    final grafo = <String, NoRota>{};

    for (var no in nos) {
      final noRota = NoRota(no.id, no.latitude, no.longitude);
      grafo[no.id] = noRota;
    }

    // Conectar ruas aos nós
    for (var rua in ruas) {
      // Encontrar nó inicial mais próximo
      final noInicio = _encontrarNoMaisProximo(
        rua.lat1,
        rua.lon1,
        grafo,
      );

      // Encontrar nó final mais próximo
      final noFim = _encontrarNoMaisProximo(
        rua.lat2,
        rua.lon2,
        grafo,
      );

      if (noInicio != null && noFim != null) {
        // Criar rua para cada direção (Rua requer origem e destino)
        final ruaIda = Rua(
          origem: noInicio.id,
          destino: noFim.id,
          distancia: rua.distanciaMetros,
          tipoVia: rua.tipo,
          temSemaforo: rua.temSemafo,
        );

        grafo[noInicio.id]?.conexoes[noFim.id] = ruaIda;

        if (!rua.oneWay) {
          final ruaVolta = Rua(
            origem: noFim.id,
            destino: noInicio.id,
            distancia: rua.distanciaMetros,
            tipoVia: rua.tipo,
            temSemaforo: rua.temSemafo,
          );
          grafo[noFim.id]?.conexoes[noInicio.id] = ruaVolta;
        }
      }
    }

    print('✅ Grafo construído: ${grafo.length} nós conectados');
    return grafo;
  }

  /// Encontra nó mais próximo de uma localização GPS
  NoRota? _encontrarNoMaisProximo(
    double latitude,
    double longitude,
    Map<String, NoRota> grafo,
  ) {
    if (grafo.isEmpty) return null;

    NoRota? maisProximo;
    double menorDistancia = double.infinity;

    for (var no in grafo.values) {
      final distancia = _calcularDistanciaHaversine(
        latitude,
        longitude,
        no.latitude,
        no.longitude,
      );

      if (distancia < menorDistancia) {
        menorDistancia = distancia;
        maisProximo = no;
      }
    }

    return maisProximo;
  }


  /// Distância Haversine em quilômetros
  double _calcularDistanciaHaversine(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const raioTerra = 6371.0; // km

    final dLat = _toRadianos(lat2 - lat1);
    final dLon = _toRadianos(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadianos(lat1)) *
            math.cos(_toRadianos(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return raioTerra * c;
  }

  double _toRadianos(double graus) {
    return graus * (math.pi / 180.0);
  }

  /// Importa geometria real das ruas e persiste no SQLite
  Future<void> importarGeometriaQuadro(
    double latitude,
    double longitude,
    List<RoadGeometry> roads,
  ) async {
    if (kIsWeb) {
      throw Exception('SQLite não está disponível na web.');
    }

    final quadro = await obterOuCriarQuadro(latitude, longitude);
    final ruas = <RuaBD>[];
    final nos = <String, NoInterseccaoDB>{};

    for (final road in roads) {
      if (road.coordinates.length < 2) {
        continue;
      }

      for (var i = 0; i < road.coordinates.length - 1; i++) {
        final a = road.coordinates[i];
        final b = road.coordinates[i + 1];
        final distancia = _calcularDistanciaHaversine(
              a.latitude,
              a.longitude,
              b.latitude,
              b.longitude,
            ) *
            1000;

        final ruaId = '${road.id}_$i';
        ruas.add(RuaBD(
          id: ruaId,
          nome: road.name,
          lat1: a.latitude,
          lon1: a.longitude,
          lat2: b.latitude,
          lon2: b.longitude,
          distanciaMetros: distancia,
          tipo: road.surfaceType,
          temSemafo: road.hasTrafficLight,
          velocidadekmh: road.speedLimitKmh,
          oneWay: road.oneWay,
          tileId: quadro.id,
        ));

        _registrarNo(nos, a, ruaId, quadro.id);
        _registrarNo(nos, b, ruaId, quadro.id);
      }
    }

    if (ruas.isEmpty || nos.isEmpty) {
      throw Exception('Geometria vazia para o quadro.');
    }

    await _dbService.salvarMuitasRuas(ruas);
    await _dbService.salvarMuitosNos(nos.values.toList());

    final quadroAtualizado = QuadroGeografico(
      id: quadro.id,
      latitudeCentro: quadro.latitudeCentro,
      longitudeCentro: quadro.longitudeCentro,
      raioKm: quadro.raioKm,
      dataDownload: DateTime.now(),
      completo: true,
    );
    await _dbService.salvarQuadro(quadroAtualizado);
  }

  String _nodeKey(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(6)}_${longitude.toStringAsFixed(6)}';
  }

  void _registrarNo(
    Map<String, NoInterseccaoDB> nos,
    GeoPoint ponto,
    String ruaId,
    String tileId,
  ) {
    final key = _nodeKey(ponto.latitude, ponto.longitude);
    final existente = nos[key];

    if (existente == null) {
      nos[key] = NoInterseccaoDB(
        id: key,
        latitude: ponto.latitude,
        longitude: ponto.longitude,
        ruasConectadas: [ruaId],
        tileId: tileId,
      );
      return;
    }

    if (!existente.ruasConectadas.contains(ruaId)) {
      existente.ruasConectadas.add(ruaId);
    }
  }

  /// Obtém todos os quadros baixados
  Future<List<QuadroGeografico>> obterTodosQuadrosBaixados() async {
    if (kIsWeb) {
      return [];
    }
    return await _dbService.obterTodosQuadros();
  }

  /// Deleta um quadro e seus dados
  Future<void> deletarQuadro(String id) async {
    if (kIsWeb) {
      return;
    }
    await _dbService.deletarQuadro(id);
    print('🗑️ Quadro $id deletado');
  }

  /// Obtém tamanho do banco de dados em KB
  Future<int> obterTamanhoBD() async {
    if (kIsWeb) {
      return 0;
    }
    return await _dbService.obterTamanhoDBemKB();
  }
}
