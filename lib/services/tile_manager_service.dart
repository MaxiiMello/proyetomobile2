import '../models/database_models.dart';
import '../models/route_models.dart';
import 'database_service.dart';
import 'dart:math' as math;

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
    final id = gerarIdQuadro(latitude, longitude);
    final quadro = await _dbService.obterQuadro(id);
    return quadro != null && quadro.completo;
  }

  /// Carrega ou cria um quadro geográfico
  Future<QuadroGeografico> obterOuCriarQuadro(
      double latitude, double longitude) async {
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

    final quadro = await obterOuCriarQuadro(latitude, longitude);
    print('📦 Quadro ID: ${quadro.id}, Raio: ${quadro.raioKm}km, Completo: ${quadro.completo}');

    // Check if database is actually available
    final db = await _dbService.database;
    
    List<RuaBD> ruas;
    List<NoInterseccaoDB> nos;

    if (db == null || !DatabaseService.isAvailable) {
      print('⚠️ Banco de dados não disponível, gerando dados em memória...');
      // Generate example data directly
      ruas = _gerarRuasExemplo(
        quadro.latitudeCentro,
        quadro.longitudeCentro,
        quadro.raioKm,
        quadro.id,
      );
      nos = _gerarNosAPartirDasRuas(ruas, quadro.id);
    } else {
      // Load from database
      ruas = await _dbService.obterRuasDoQuadro(quadro.id);
      nos = await _dbService.obterNosDoQuadro(quadro.id);

      // If empty, generate and save
      if (ruas.isEmpty || nos.isEmpty) {
        print('📥 Quadro vazio, preenchendo com dados de exemplo...');
        await _preencherQuadroComDadosExemplo(quadro);
        ruas = await _dbService.obterRuasDoQuadro(quadro.id);
        nos = await _dbService.obterNosDoQuadro(quadro.id);
      }
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

        final ruaVolta = Rua(
          origem: noFim.id,
          destino: noInicio.id,
          distancia: rua.distanciaMetros,
          tipoVia: rua.tipo,
          temSemaforo: rua.temSemafo,
        );

        // Bidirecional
        grafo[noInicio.id]?.conexoes[noFim.id] = ruaIda;
        grafo[noFim.id]?.conexoes[noInicio.id] = ruaVolta;
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

  /// Preenche quadro com dados de exemplo (simulando download de OSM)
  Future<void> _preencherQuadroComDadosExemplo(
      QuadroGeografico quadro) async {
    print('📥 Preenchendo quadro ${quadro.id} com dados de exemplo...');

    final ruasExemplo = _gerarRuasExemplo(
      quadro.latitudeCentro,
      quadro.longitudeCentro,
      quadro.raioKm,
      quadro.id,
    );

    final nosExemplo =
        _gerarNosAPartirDasRuas(ruasExemplo, quadro.id);

    // Salvar no BD
    await _dbService.salvarMuitasRuas(ruasExemplo);
    await _dbService.salvarMuitosNos(nosExemplo);

    // Marcar como completo
    final quadroAtualizado = QuadroGeografico(
      id: quadro.id,
      latitudeCentro: quadro.latitudeCentro,
      longitudeCentro: quadro.longitudeCentro,
      raioKm: quadro.raioKm,
      dataDownload: quadro.dataDownload,
      completo: true,
    );
    await _dbService.salvarQuadro(quadroAtualizado);

    print('✅ Quadro preenchido com ${ruasExemplo.length} ruas e ${nosExemplo.length} nós');
  }

  /// Gera ruas de exemplo em uma grade realista
  List<RuaBD> _gerarRuasExemplo(
    double latBase,
    double lonBase,
    double raioKm,
    String tileId,
  ) {
    final ruas = <RuaBD>[];
    const quadraSize = 0.002; // ~200 metros em graus
    const tiposRua = ['asfalto', 'terra', 'paralelepípedo'];
    final random = math.Random();

    int ruaCount = 0;

    // Gerar grid de ruas
    for (double lat = latBase - (raioKm / 111);
        lat < latBase + (raioKm / 111);
        lat += quadraSize) {
      for (double lon = lonBase - (raioKm / 111);
          lon < lonBase + (raioKm / 111);
          lon += quadraSize) {
        // Rua horizontal
        if (lon + quadraSize < lonBase + (raioKm / 111)) {
          final tipo = tiposRua[random.nextInt(tiposRua.length)];
          final distancia = _calcularDistanciaHaversine(
            lat,
            lon,
            lat,
            lon + quadraSize,
          );

          ruas.add(RuaBD(
            id: 'rua_h_${ruaCount++}',
            nome: 'Rua ${lat.toStringAsFixed(3)}_H',
            lat1: lat,
            lon1: lon,
            lat2: lat,
            lon2: lon + quadraSize,
            distanciaMetros: distancia * 1000,
            tipo: tipo,
            temSemafo: random.nextBool(),
            velocidadekmh: tipo == 'asfalto' ? 50 : 30,
            tileId: tileId,
          ));
        }

        // Rua vertical
        if (lat + quadraSize < latBase + (raioKm / 111)) {
          final tipo = tiposRua[random.nextInt(tiposRua.length)];
          final distancia = _calcularDistanciaHaversine(
            lat,
            lon,
            lat + quadraSize,
            lon,
          );

          ruas.add(RuaBD(
            id: 'rua_v_${ruaCount++}',
            nome: 'Rua ${lon.toStringAsFixed(3)}_V',
            lat1: lat,
            lon1: lon,
            lat2: lat + quadraSize,
            lon2: lon,
            distanciaMetros: distancia * 1000,
            tipo: tipo,
            temSemafo: random.nextBool(),
            velocidadekmh: tipo == 'asfalto' ? 50 : 30,
            tileId: tileId,
          ));
        }
      }
    }

    return ruas;
  }

  /// Gera nós de intersecção a partir das ruas
  List<NoInterseccaoDB> _gerarNosAPartirDasRuas(
    List<RuaBD> ruas,
    String tileId,
  ) {
    final nos = <String, NoInterseccaoDB>{};

    // Criar nó para cada ponto de início/fim de rua
    for (var rua in ruas) {
      void criarOuAtualizarNo(double lat, double lon, String ruaId) {
        final noId = '${lat.toStringAsFixed(5)}_${lon.toStringAsFixed(5)}';

        if (nos.containsKey(noId)) {
          nos[noId]!.ruasConectadas.add(ruaId);
        } else {
          nos[noId] = NoInterseccaoDB(
            id: noId,
            latitude: lat,
            longitude: lon,
            ruasConectadas: [ruaId],
            tileId: tileId,
          );
        }
      }

      criarOuAtualizarNo(rua.lat1, rua.lon1, rua.id);
      criarOuAtualizarNo(rua.lat2, rua.lon2, rua.id);
    }

    return nos.values.toList();
  }

  /// Obtém todos os quadros baixados
  Future<List<QuadroGeografico>> obterTodosQuadrosBaixados() async {
    return await _dbService.obterTodosQuadros();
  }

  /// Deleta um quadro e seus dados
  Future<void> deletarQuadro(String id) async {
    await _dbService.deletarQuadro(id);
    print('🗑️ Quadro $id deletado');
  }

  /// Obtém tamanho do banco de dados em KB
  Future<int> obterTamanhoBD() async {
    return await _dbService.obterTamanhoDBemKB();
  }
}
