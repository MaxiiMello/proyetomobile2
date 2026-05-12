import 'package:flutter/foundation.dart';
import 'dart:math';

import '../models/database/repositories/user_repository.dart';
import '../services/gps_service.dart' show GpsService, LocationData;
import '../services/address_service.dart' show AddressService;
import '../services/routing_service.dart' show RoutingService;
import '../services/tile_manager_service.dart' show TileManagerService;
import '../models/route_models.dart' show ResultadoRota, DadosRota;

class MapViewModel extends ChangeNotifier {
  final GpsService _gpsService = GpsService();
  final AddressService _addressService = AddressService();
  final RoutingService _routingService = RoutingService();
  final TileManagerService _tileManager = TileManagerService();

  double currentLatitude = -30.8936; // Santana do Livramento, RS
  double currentLongitude = -55.5205;
  String? selectedDestination;
  double zoomLevel = 15.0;

  bool isLoadingMap = false;
  bool isNavigating = false;
  String? errorMessage;
  User? currentUser;

  // Propriedades para sugestões de endereços
  List<String> addressSuggestions = [];
  bool isLoadingSuggestions = false;

  // Propriedades para origem e destino
  String? startAddress;
  double? startLatitude;
  double? startLongitude;

  String? endAddress;
  double? endLatitude;
  double? endLongitude;

  // Controla qual campo está sendo editado (0 = origem, 1 = destino)
  int? activeSuggestionMode; // null = nenhum, 0 = origem, 1 = destino

  bool hasCompleteRoute = false; // true quando ambos os pontos estão definidos

  // Modo de clique no mapa: 0 = origem, 1 = destino, null = desativado
  int? mapClickMode;

  // Propriedades de roteamento
  ResultadoRota? rotaCalculada;
  DadosRota? dadosRotaUI;
  bool isCalculatingRoute = false;
  bool grafoInicializado = false;

  MapViewModel({User? user}) {
    currentUser = user;
    // Inicializar grafo da cidade (async)
    _inicializarGrafo();
    // Se em web, já começa com coordenadas padrão
    if (kIsWeb) {
      isLoadingMap = false;
    } else {
      // Em mobile, tenta carregar localização real
      loadMap();
    }
  }

  /// Inicializar o grafo da cidade carregando dados reais do banco de dados
  /// ou gerando dados de exemplo se não existirem
  Future<void> _inicializarGrafo() async {
    _routingService.limpar();

    // Coordenadas de Santana do Livramento (Brasil)
    double latBase = -30.8936;
    double lonBase = -55.5205;

    print('═' * 60);
    print('🔧 INICIALIZANDO GRAFO COM DADOS REAIS');
    print('═' * 60);

    try {
      // Carregar grafo do TileManager (que carrega do BD)
      final grafo = await _tileManager.construirGrafoDoQuadro(latBase, lonBase);

      // Adicionar nós ao RoutingService (as conexões já estão no grafo)
      for (var no in grafo.values) {
        _routingService.adicionarNo(no);
      }

      grafoInicializado = true;
      print('✅ Grafo carregado com sucesso: ${_routingService.grafo.length} nós');
      notifyListeners();
    } catch (e) {
      print('❌ Erro ao carregar grafo: $e');
      grafoInicializado = false;
      errorMessage = 'Erro ao carregar dados da cidade';
      notifyListeners();
    }

    print('═' * 60);
  }

  /// Caregar mapa
  Future<void> loadMap() async {
    isLoadingMap = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Primeiro tenta última localização conhecida (mais rápido) com timeout
      LocationData? location;
      try {
        location = await _gpsService.getLastKnownLocation()
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        // Continua mesmo que falhe
        location = null;
      }
      
      // Se não encontrou última localização, obtém atual com timeout
      if (location == null) {
        try {
          location = await _gpsService.getCurrentLocation()
              .timeout(const Duration(seconds: 8));
        } catch (e) {
          // Se GPS falhar, usa localização padrão (Santana do Livramento, RS)
          currentLatitude = -30.8936;
          currentLongitude = -55.5205;
          isLoadingMap = false;
          notifyListeners();
          return;
        }
      }
      
      currentLatitude = location.latitude;
      currentLongitude = location.longitude;
    
      isLoadingMap = false;
      notifyListeners();
    } catch (e) {
      // Fallback para localização padrão se tudo falhar
      currentLatitude = -30.8936;
      currentLongitude = -55.5205;
      isLoadingMap = false;
      notifyListeners();
    }
  }

  /// Solicitar y obtener ubicación GPS
  Future<void> requestGPSLocation() async {
    try {
      final location = await _gpsService.getCurrentLocation();
      currentLatitude = location.latitude;
      currentLongitude = location.longitude;
      isLoadingMap = false;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  /// Zoom in
  void zoomIn() {
    if (zoomLevel < 20) {
      zoomLevel += 1;
      notifyListeners();
    }
  }

  /// Zoom out
  void zoomOut() {
    if (zoomLevel > 5) {
      zoomLevel -= 1;
      notifyListeners();
    }
  }

  /// Buscar sugestões de endereços enquanto o usuário digita
  Future<void> getAddressSuggestions(String input) async {
    if (input.isEmpty) {
      addressSuggestions = [];
      notifyListeners();
      return;
    }

    isLoadingSuggestions = true;
    notifyListeners();

    try {
      final suggestions = await _addressService.getPlacePredictions(input);
      addressSuggestions = suggestions;
      
      if (suggestions.isEmpty) {
        errorMessage = 'Nenhum endereço encontrado para "$input"';
      } else {
        errorMessage = null;
      }
    } catch (e) {
      addressSuggestions = [];
      errorMessage = 'Erro ao buscar endereços: $e';
      print('Error getting suggestions: $e');
    }

    isLoadingSuggestions = false;
    notifyListeners();
  }

  /// Selecionar um endereço e mover o mapa para lá
  Future<void> selectAddress(String address) async {
    isLoadingMap = true;
    selectedDestination = address;
    addressSuggestions = []; // Limpar sugestões
    notifyListeners();

    try {
      final suggestion = await _addressService.geocodeAddress(address);
      
      if (suggestion != null) {
        currentLatitude = suggestion.latitude;
        currentLongitude = suggestion.longitude;
        zoomLevel = 15.0; // Reset zoom para endereço selecionado
        errorMessage = null;
      } else {
        errorMessage = 'Não foi possível encontrar este local';
      }
    } catch (e) {
      errorMessage = 'Erro ao buscar endereço: $e';
      print('Error selecting address: $e');
    }

    isLoadingMap = false;
    notifyListeners();
  }

  /// Limpar sugestões
  void clearSuggestions() {
    addressSuggestions = [];
    notifyListeners();
  }

  /// Definir mode de sugestão (qual campo está ativo: 0=origem, 1=destino)
  void setActiveSuggestionMode(int? mode) {
    activeSuggestionMode = mode;
    clearSuggestions();
    notifyListeners();
  }

  /// Selecionar local de origem
  Future<void> selectStartPoint(String address) async {
    isLoadingMap = true;
    addressSuggestions = [];
    notifyListeners();

    try {
      final suggestion = await _addressService.geocodeAddress(address);

      if (suggestion != null) {
        startAddress = address;
        startLatitude = suggestion.latitude;
        startLongitude = suggestion.longitude;
        _checkCompleteRoute();
        errorMessage = null;
      } else {
        errorMessage = 'Não foi possível encontrar este local';
      }
    } catch (e) {
      errorMessage = 'Erro ao buscar endereço: $e';
      print('Error selecting start point: $e');
    }

    isLoadingMap = false;
    activeSuggestionMode = null;
    notifyListeners();
  }

  /// Selecionar local de destino
  Future<void> selectEndPoint(String address) async {
    isLoadingMap = true;
    addressSuggestions = [];
    notifyListeners();

    try {
      final suggestion = await _addressService.geocodeAddress(address);

      if (suggestion != null) {
        endAddress = address;
        endLatitude = suggestion.latitude;
        endLongitude = suggestion.longitude;
        _checkCompleteRoute();
        errorMessage = null;
      } else {
        errorMessage = 'Não foi possível encontrar este local';
      }
    } catch (e) {
      errorMessage = 'Erro ao buscar endereço: $e';
      print('Error selecting end point: $e');
    }

    isLoadingMap = false;
    activeSuggestionMode = null;
    notifyListeners();
  }

  /// Verificar se ambos os pontos estão definidos
  void _checkCompleteRoute() {
    hasCompleteRoute = startLatitude != null &&
        startLongitude != null &&
        endLatitude != null &&
        endLongitude != null;
  }

  /// Limpar pontos de origem e destino
  void clearRoutePoints() {
    startAddress = null;
    startLatitude = null;
    startLongitude = null;
    endAddress = null;
    endLatitude = null;
    endLongitude = null;
    hasCompleteRoute = false;
    activeSuggestionMode = null;
    notifyListeners();
  }

  /// Limpar apenas o ponto de origem
  void clearStartPoint() {
    startAddress = null;
    startLatitude = null;
    startLongitude = null;
    _checkCompleteRoute();
    notifyListeners();
  }

  /// Limpar apenas o ponto de destino
  void clearEndPoint() {
    endAddress = null;
    endLatitude = null;
    endLongitude = null;
    _checkCompleteRoute();
    notifyListeners();
  }

  /// Ativar modo de clique no mapa (0 = origem, 1 = destino)
  void activateMapClickMode(int mode) {
    mapClickMode = mode;
    notifyListeners();
  }

  /// Desativar modo de clique no mapa
  void deactivateMapClickMode() {
    mapClickMode = null;
    notifyListeners();
  }

  /// Processar clique no mapa (reverse geocoding)
  Future<void> handleMapClick(double latitude, double longitude) async {
    if (mapClickMode == null) {
      return;
    }

    isLoadingMap = true;
    notifyListeners();

    try {
      final suggestion = await _addressService.reverseGeocodeCoordinates(
        latitude,
        longitude,
      );

      if (suggestion != null) {
        if (mapClickMode == 0) {
          startAddress = suggestion.displayName;
          startLatitude = suggestion.latitude;
          startLongitude = suggestion.longitude;
        } else {
          endAddress = suggestion.displayName;
          endLatitude = suggestion.latitude;
          endLongitude = suggestion.longitude;
        }
        _checkCompleteRoute();
        errorMessage = null;
        mapClickMode = null; // Desativar modo após selecionar
      } else {
        errorMessage = 'Não foi possível identificar o endereço neste local';
      }
    } catch (e) {
      errorMessage = 'Erro ao processar clique: $e';
      print('Error handling map click: $e');
    }

    isLoadingMap = false;
    notifyListeners();
  }

  /// Obtener stream de ubicación en tiempo real para mapa
  Stream<void> getMapLocationStream() {
    return _gpsService
        .getLocationStream(distanceFilter: 5)
        .map((location) {
      currentLatitude = location.latitude;
      currentLongitude = location.longitude;
      notifyListeners();
    });
  }

  /// Calcular a melhor rota usando A*
  /// Considera: tipo de via (asfalto/terra) e semáforos
  Future<void> calcularMelhorRota() async {
    if (!hasCompleteRoute || startLatitude == null || endLatitude == null) {
      errorMessage = 'Origem e destino precisam estar definidos';
      notifyListeners();
      return;
    }

    if (!grafoInicializado) {
      errorMessage = 'Grafo não foi inicializado. Tente novamente.';
      notifyListeners();
      return;
    }

    isCalculatingRoute = true;
    errorMessage = null;
    notifyListeners();

    try {
      print('═' * 60);
      print('🗺️ CÁLCULO DE ROTA INICIADO');
      print('═' * 60);
      print(
        '📍 Origem GPS: ($startLatitude, $startLongitude)',
      );
      print(
        '📍 Destino GPS: ($endLatitude, $endLongitude)',
      );
      print('📊 Total de nós no grafo: ${_routingService.grafo.length}');

      // Encontrar os nós mais próximos do ponto de origem e destino
      String noProximoOrigem = _encontrarNoMaisProximo(
        startLatitude!,
        startLongitude!,
      );
      String noProximoDestino = _encontrarNoMaisProximo(
        endLatitude!,
        endLongitude!,
      );

      print(
        '🎯 Nó de origem encontrado: $noProximoOrigem',
      );
      print(
        '🎯 Nó de destino encontrado: $noProximoDestino',
      );

      // Executar algoritmo A*
      rotaCalculada = _routingService.executarAEstrela(
        noProximoOrigem,
        noProximoDestino,
      );

      if (rotaCalculada != null && rotaCalculada!.temRota) {
        // Converter para dados de UI
        dadosRotaUI = DadosRota.doResultado(rotaCalculada!);
        errorMessage = null;
        print(
          '✅ Rota calculada: ${rotaCalculada!.tempoMinutos.toStringAsFixed(1)} minutos',
        );
        print(
          '📏 Distância: ${rotaCalculada!.distanciaKm.toStringAsFixed(2)} km',
        );
        print(
          '🚦 Semáforos: ${rotaCalculada!.semaforosNoCaminho}',
        );
        print(
          '🛣️ Nós na rota: ${rotaCalculada!.caminhoFinal.length}',
        );
        print('Caminho: ${rotaCalculada!.caminhoFinal.join(" → ")}');
      } else {
        errorMessage = 'Não foi possível calcular uma rota para este destino';
        dadosRotaUI = null;
        print('❌ Nenhuma rota disponível');
      }
    } catch (e) {
      errorMessage = 'Erro ao calcular rota: $e';
      rotaCalculada = null;
      dadosRotaUI = null;
      print('❌ Erro: $e');
    }

    isCalculatingRoute = false;
    notifyListeners();
  }

  /// Encontrar o nó mais próximo de uma coordenada
  String _encontrarNoMaisProximo(double latitude, double longitude) {
    double menorDistancia = double.infinity;
    String? noMaisProximo;
    int tentativas = 0;

    for (var no in _routingService.grafo.values) {
      double distancia = _calcularDistancia(
        latitude,
        longitude,
        no.latitude,
        no.longitude,
      );

      if (distancia < menorDistancia) {
        menorDistancia = distancia;
        noMaisProximo = no.id;
      }
      tentativas++;
    }

    print(
      '   → Verificados $tentativas nós. Mais próximo: $noMaisProximo (distância: ${menorDistancia.toStringAsFixed(4)} km)',
    );

    return noMaisProximo ?? "0_0"; // Fallback ao ponto de origem
  }

  /// Calcular distância entre dois pontos (Haversine)
  double _calcularDistancia(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double raioTerra = 6371000; // metros
    double dLat = (lat2 - lat1) * pi / 180;
    double dLon = (lon2 - lon1) * pi / 180;
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * asin(sqrt(a));
    double distancia = raioTerra * c; // em metros
    return distancia / 1000; // retorna em km
  }

  /// Limpar rota calculada
  void limparRota() {
    rotaCalculada = null;
    dadosRotaUI = null;
    notifyListeners();
  }
}
