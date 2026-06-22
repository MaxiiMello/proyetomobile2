import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';
import 'dart:async';

import '../models/database/repositories/user_repository.dart';
import '../services/gps_service.dart' show GpsService, LocationData;
import '../services/address_service.dart' show AddressService;
import '../services/routing_service.dart' show RoutingService;
import '../services/roads_download_service.dart' show RoadsDownloadService;
import '../services/tile_manager_service.dart' show TileManagerService;
import '../models/route_models.dart' show ResultadoRota, DadosRota;

class MapViewModel extends ChangeNotifier {
  final GpsService _gpsService = GpsService();
  final AddressService _addressService = AddressService();
  final RoutingService _routingService = RoutingService();
  final TileManagerService _tileManager = TileManagerService();
  final RoadsDownloadService _roadsDownloadService = RoadsDownloadService();

  double currentLatitude = -30.8936; // Santana do Livramento, RS
  double currentLongitude = -55.5205;
  String? selectedDestination;
  double zoomLevel = 15.0;

  bool isLoadingMap = false;
  bool isNavigating = false;
  String? errorMessage;
  User? currentUser;
  double? currentHeading;

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
  bool isDownloadingQuadro = false;
  String? downloadStatusMessage;
  double? _graphCenterLatitude;
  double? _graphCenterLongitude;
  StreamSubscription<LocationData>? _navigationSubscription;
  bool _isRecalculating = false;
  DateTime? _lastRecalcTime;
  static const double _recalcThresholdMeters = 30;
  static const Duration _recalcCooldown = Duration(seconds: 10);
  static const double _averageSpeedKmh = 40.0;

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
    final latBase = _graphCenterLatitude ?? -30.8936;
    final lonBase = _graphCenterLongitude ?? -55.5205;

    try {
      // Carregar grafo do TileManager (que carrega do BD)
      final grafo = await _tileManager.construirGrafoDoQuadro(latBase, lonBase);

      // Adicionar nós ao RoutingService (as conexões já estão no grafo)
      for (var no in grafo.values) {
        _routingService.adicionarNo(no);
      }

      grafoInicializado = true;
      notifyListeners();
    } catch (e) {
      grafoInicializado = false;
      errorMessage = 'Erro ao carregar dados da cidade';
      notifyListeners();
    }
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
        location = await _gpsService.getLastKnownLocation().timeout(
          const Duration(seconds: 5),
        );
      } catch (e) {
        // Continua mesmo que falhe
        location = null;
      }

      // Se não encontrou última localização, obtém atual com timeout
      if (location == null) {
        try {
          location = await _gpsService.getCurrentLocation().timeout(
            const Duration(seconds: 8),
          );
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
      currentHeading = location.heading;

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
    }

    isLoadingMap = false;
    activeSuggestionMode = null;
    notifyListeners();
  }

  /// Verificar se ambos os pontos estão definidos
  void _checkCompleteRoute() {
    hasCompleteRoute =
        startLatitude != null &&
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
    }

    isLoadingMap = false;
    notifyListeners();
  }

  /// Obtener stream de ubicación en tiempo real para mapa
  Stream<void> getMapLocationStream() {
    return _gpsService.getLocationStream(distanceFilter: 5).map((location) {
      currentLatitude = location.latitude;
      currentLongitude = location.longitude;
      currentHeading = location.heading;
      notifyListeners();
    });
  }

  /// Iniciar navegacao em tempo real
  Future<void> startNavigation() async {
    if (endLatitude == null || endLongitude == null) {
      errorMessage = 'Defina um destino antes de iniciar a rota.';
      notifyListeners();
      return;
    }

    if (!grafoInicializado) {
      errorMessage = 'Grafo nao foi inicializado. Tente novamente.';
      notifyListeners();
      return;
    }

    isNavigating = true;
    errorMessage = null;
    notifyListeners();

    // Usar posicao atual como origem
    startLatitude = currentLatitude;
    startLongitude = currentLongitude;
    startAddress = 'Posicao atual';
    _checkCompleteRoute();

    await calcularMelhorRota();

    await _navigationSubscription?.cancel();
    _navigationSubscription = _gpsService
        .getLocationStream(distanceFilter: 5)
        .listen(
          _handleNavigationLocation,
          onError: (error) {
            errorMessage = 'Erro no GPS: $error';
            notifyListeners();
          },
        );
  }

  void _handleNavigationLocation(LocationData location) {
    if (!isNavigating) return;

    currentLatitude = location.latitude;
    currentLongitude = location.longitude;
    currentHeading = location.heading;
    notifyListeners();

    _maybeRecalculateRoute();
  }

  Future<void> _maybeRecalculateRoute() async {
    if (_isRecalculating || isCalculatingRoute) {
      return;
    }

    if (rotaCalculada == null || rotaCalculada!.caminhoFinal.isEmpty) {
      return;
    }

    final now = DateTime.now();
    if (_lastRecalcTime != null &&
        now.difference(_lastRecalcTime!) < _recalcCooldown) {
      return;
    }

    final distanceMeters = _distanceToRouteMeters(
      currentLatitude,
      currentLongitude,
    );

    if (distanceMeters <= _recalcThresholdMeters) {
      return;
    }

    _isRecalculating = true;
    _lastRecalcTime = now;

    startLatitude = currentLatitude;
    startLongitude = currentLongitude;
    await calcularMelhorRota();

    _isRecalculating = false;
  }

  double _distanceToRouteMeters(double latitude, double longitude) {
    final points = buildRoutePoints();
    if (points.isEmpty) {
      return double.infinity;
    }

    var minMeters = double.infinity;
    for (final point in points) {
      final km = _calcularDistancia(
        latitude,
        longitude,
        point.latitude,
        point.longitude,
      );
      final meters = km * 1000;
      if (meters < minMeters) {
        minMeters = meters;
      }
    }

    return minMeters;
  }

  Future<void> stopNavigation() async {
    isNavigating = false;
    await _navigationSubscription?.cancel();
    _navigationSubscription = null;
    notifyListeners();
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
      // Encontrar os nós mais próximos do ponto de origem e destino
      String noProximoOrigem = _encontrarNoMaisProximo(
        startLatitude!,
        startLongitude!,
      );
      String noProximoDestino = _encontrarNoMaisProximo(
        endLatitude!,
        endLongitude!,
      );

      rotaCalculada = _routingService.executarAEstrela(
        noProximoOrigem,
        noProximoDestino,
      );

      if (rotaCalculada != null && rotaCalculada!.temRota) {
        // Converter para dados de UI
        dadosRotaUI = DadosRota.doResultado(rotaCalculada!);
        errorMessage = null;
      } else {
        errorMessage = 'Não foi possível calcular uma rota para este destino';
        dadosRotaUI = null;
      }
    } catch (e) {
      errorMessage = 'Erro ao calcular rota: $e';
      rotaCalculada = null;
      dadosRotaUI = null;
    }

    isCalculatingRoute = false;
    notifyListeners();
  }

  /// Baixar quadro offline e persistir geometria real das ruas
  Future<void> downloadQuadroAt({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    if (kIsWeb) {
      downloadStatusMessage = 'Download offline nao esta disponivel no Web.';
      notifyListeners();
      return;
    }

    isDownloadingQuadro = true;
    downloadStatusMessage = null;
    notifyListeners();

    try {
      final roads = await _roadsDownloadService.downloadRoads(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );

      await _tileManager.importarGeometriaQuadro(latitude, longitude, roads);

      _graphCenterLatitude = latitude;
      _graphCenterLongitude = longitude;
      await _inicializarGrafo();

      downloadStatusMessage = 'Quadro baixado com sucesso.';
    } catch (e) {
      downloadStatusMessage = 'Erro ao baixar quadro: $e';
    } finally {
      isDownloadingQuadro = false;
      notifyListeners();
    }
  }

  /// Converter caminho final em pontos geograficos usando o grafo carregado
  List<LatLng> buildRoutePoints() {
    final pontos = <LatLng>[];

    if (rotaCalculada == null || rotaCalculada!.caminhoFinal.isEmpty) {
      return pontos;
    }

    for (final noId in rotaCalculada!.caminhoFinal) {
      final no = _routingService.grafo[noId];
      if (no == null) {
        continue;
      }
      pontos.add(LatLng(no.latitude, no.longitude));
    }
    return pontos;
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
    double a =
        sin(dLat / 2) * sin(dLat / 2) +
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

  String get distanciaKmLabel {
    final distance = rotaCalculada?.distanciaKm;
    if (distance == null) {
      return '--';
    }
    return '${distance.toStringAsFixed(2)} km';
  }

  String get tempoMedioLabel {
    final distance = rotaCalculada?.distanciaKm;
    if (distance == null) {
      return '--';
    }
    final minutes = (distance / _averageSpeedKmh) * 60;
    return _formatMinutes(minutes);
  }

  String _formatMinutes(double minutes) {
    if (!minutes.isFinite || minutes < 0) {
      return '--';
    }
    final totalMinutes = minutes.ceil();
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}min';
    }
    return '$mins min';
  }

  @override
  void dispose() {
    _navigationSubscription?.cancel();
    super.dispose();
  }
}
