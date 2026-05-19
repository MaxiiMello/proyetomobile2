import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../services/maps_service.dart';
import '../../../viewmodels/map_viewmodel.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapController? _mapController = MapController();
  final MapsService _mapsService = MapsService.instance;
  late TextEditingController _startController;
  late TextEditingController _endController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _startController = TextEditingController();
    _endController = TextEditingController();
    
    // Listener para buscar sugestões de origem
    _startController.addListener(() {
      final viewModel = context.read<MapViewModel>();
      viewModel.setActiveSuggestionMode(0);
      if (_startController.text.isNotEmpty) {
        viewModel.getAddressSuggestions(_startController.text);
      } else {
        viewModel.clearSuggestions();
      }
    });

    // Listener para buscar sugestões de destino
    _endController.addListener(() {
      final viewModel = context.read<MapViewModel>();
      viewModel.setActiveSuggestionMode(1);
      if (_endController.text.isNotEmpty) {
        viewModel.getAddressSuggestions(_endController.text);
      } else {
        viewModel.clearSuggestions();
      }
    });

    // Carregar mapa apenas uma vez ao iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final viewModel = context.read<MapViewModel>();
        if (!_initialized && !kIsWeb) {
          viewModel.loadMap();
          _initialized = true;
        }
      }
    });
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  void _animateToPoint(double latitude, double longitude) {
    if (_mapController != null) {
      _mapController!.move(
        LatLng(latitude, longitude),
        15.0,
      );
    }
  }

  void _fitBothPoints(MapViewModel viewModel) {
    if (_mapController != null &&
        viewModel.startLatitude != null &&
        viewModel.startLongitude != null &&
        viewModel.endLatitude != null &&
        viewModel.endLongitude != null) {
      final bounds = LatLngBounds(
        LatLng(viewModel.startLatitude!, viewModel.startLongitude!),
        LatLng(viewModel.endLatitude!, viewModel.endLongitude!),
      );
      
      _mapController!.fitCamera(CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(100),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header com campos de origem e destino
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Consumer<MapViewModel>(
                builder: (context, viewModel, _) {
                  return Column(
                    children: [
                      // Campo de ORIGEM
                      TextField(
                        controller: _startController,
                        style: const TextStyle(fontSize: 14),
                        onChanged: (value) {
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: 'Local de início...',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.location_on,
                            color: Colors.green[600],
                            size: 20,
                          ),
                          suffixIcon: _startController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: Colors.grey[600],
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _startController.clear();
                                    viewModel.clearStartPoint();
                                  },
                                )
                              : IconButton(
                                  icon: Icon(
                                    Icons.touch_app,
                                    color: viewModel.mapClickMode == 0
                                        ? Colors.green[600]
                                        : Colors.grey[600],
                                    size: 20,
                                  ),
                                  tooltip: 'Clique no mapa para definir',
                                  onPressed: () {
                                    if (viewModel.mapClickMode == 0) {
                                      viewModel.deactivateMapClickMode();
                                    } else {
                                      viewModel.activateMapClickMode(0);
                                    }
                                    setState(() {});
                                  },
                                ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: viewModel.mapClickMode == 0
                                  ? Colors.green[600]!
                                  : Colors.grey[300]!,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: viewModel.mapClickMode == 0
                                  ? Colors.green[600]!
                                  : Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFF1B7E3D),
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: viewModel.mapClickMode == 0
                              ? Colors.green[50]
                              : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Campo de DESTINO
                      TextField(
                        controller: _endController,
                        style: const TextStyle(fontSize: 14),
                        onChanged: (value) {
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: 'Local de destino...',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.location_on,
                            color: Colors.red[600],
                            size: 20,
                          ),
                          suffixIcon: _endController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: Colors.grey[600],
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _endController.clear();
                                    viewModel.clearEndPoint();
                                  },
                                )
                              : IconButton(
                                  icon: Icon(
                                    Icons.touch_app,
                                    color: viewModel.mapClickMode == 1
                                        ? Colors.red[600]
                                        : Colors.grey[600],
                                    size: 20,
                                  ),
                                  tooltip: 'Clique no mapa para definir',
                                  onPressed: () {
                                    if (viewModel.mapClickMode == 1) {
                                      viewModel.deactivateMapClickMode();
                                    } else {
                                      viewModel.activateMapClickMode(1);
                                    }
                                    setState(() {});
                                  },
                                ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: viewModel.mapClickMode == 1
                                  ? Colors.red[600]!
                                  : Colors.grey[300]!,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: viewModel.mapClickMode == 1
                                  ? Colors.red[600]!
                                  : Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFF1B7E3D),
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: viewModel.mapClickMode == 1
                              ? Colors.red[50]
                              : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),

                      // Lista de sugestões
                      if (viewModel.isLoadingSuggestions)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 100),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(10),
                            ),
                          ),
                          child: const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                        )
                      else if (viewModel.addressSuggestions.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(10),
                            ),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: viewModel.addressSuggestions.length,
                            itemBuilder: (context, index) {
                              final suggestion =
                                  viewModel.addressSuggestions[index];
                              return ListTile(
                                leading: Icon(
                                  Icons.location_on_outlined,
                                  color: viewModel.activeSuggestionMode == 0
                                      ? Colors.green[600]
                                      : Colors.red[600],
                                  size: 18,
                                ),
                                title: Text(
                                  suggestion,
                                  style: const TextStyle(fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () {
                                  // Selecionar o endereço conforme o campo ativo
                                  if (viewModel.activeSuggestionMode == 0) {
                                    viewModel.selectStartPoint(suggestion);
                                    _startController.text = suggestion;
                                    // Animar para o ponto de origem após selecionar
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      if (viewModel.startLatitude != null &&
                                          viewModel.startLongitude != null) {
                                        _animateToPoint(
                                          viewModel.startLatitude!,
                                          viewModel.startLongitude!,
                                        );
                                      }
                                    });
                                  } else {
                                    viewModel.selectEndPoint(suggestion);
                                    _endController.text = suggestion;
                                    // Animar para o ponto de destino após selecionar
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      if (viewModel.endLatitude != null &&
                                          viewModel.endLongitude != null) {
                                        _animateToPoint(
                                          viewModel.endLatitude!,
                                          viewModel.endLongitude!,
                                        );
                                      }
                                    });
                                  }
                                  FocusScope.of(context).unfocus();
                                },
                              );
                            },
                          ),
                        )
                      else if ((_startController.text.isNotEmpty ||
                              _endController.text.isNotEmpty) &&
                          viewModel.addressSuggestions.isEmpty &&
                          !viewModel.isLoadingSuggestions)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 100),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.orange[300]!,
                              width: 1,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(10),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_outlined,
                                  color: Colors.orange[600],
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Sem resultados',
                                        style: TextStyle(
                                          color: Colors.orange[600],
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'Tente com mais detalhes ou clique no mapa',
                                        style: TextStyle(
                                          color: Colors.orange[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Mensagem de erro se houver
                      if (viewModel.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              border: Border.all(
                                color: Colors.red[300]!,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red[600],
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    viewModel.errorMessage!,
                                    style: TextStyle(
                                      color: Colors.red[600],
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Botão para calcular rota
                      if (viewModel.hasCompleteRoute)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B7E3D),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                // Centralizar ambos os pontos no mapa
                                _fitBothPoints(viewModel);
                                // Aqui será chamado o algoritmo A*
                                _showCalculatingRoute(context);
                              },
                              child: const Text(
                                'Calcular Melhor Rota',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        )
                      else if (_startController.text.isNotEmpty ||
                          _endController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              border: Border.all(
                                color: Colors.blue[300]!,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue[600],
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Dica: Use o botão 👆 para clicar no mapa\n(mais rápido e sem limite de requisições)',
                                    style: TextStyle(
                                      color: Colors.blue[600],
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            // Mapa com marcadores
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Consumer<MapViewModel>(
                    builder: (context, viewModel, _) {
                      return Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: LatLng(
                                viewModel.currentLatitude != 0
                                    ? viewModel.currentLatitude
                                    : -30.8831,
                                viewModel.currentLongitude != 0
                                    ? viewModel.currentLongitude
                                    : -55.5350,
                              ),
                              initialZoom: viewModel.zoomLevel > 0
                                  ? viewModel.zoomLevel
                                  : 14.0,
                              onPositionChanged: (MapCamera position, bool hasGesture) {
                                viewModel.zoomLevel = position.zoom;
                              },
                              onTap: (tapPosition, point) async {
                                // Processar clique no mapa
                                if (viewModel.mapClickMode != null) {
                                  await viewModel.handleMapClick(
                                    point.latitude,
                                    point.longitude,
                                  );
                                  // Atualizar controllers após reverse geocoding
                                  if (viewModel.mapClickMode == 0 &&
                                      viewModel.startAddress != null) {
                                    _startController.text =
                                        viewModel.startAddress!;
                                  } else if (viewModel.mapClickMode == 1 &&
                                      viewModel.endAddress != null) {
                                    _endController.text = viewModel.endAddress!;
                                  }
                                  setState(() {});
                                }
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://maps.geoapify.com/v1/tile/toner-grey/{z}/{x}/{y}.png?apiKey=602b6e2908704777bc047e4ebcaba003',
                                userAgentPackageName: 'com.sinalverde.app',
                              ),
                              // Traçado da rota calculada
                              if (viewModel.rotaCalculada != null &&
                                  viewModel.rotaCalculada!.caminhoFinal
                                      .isNotEmpty)
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                        points: viewModel.buildRoutePoints(),
                                      color: Colors.green[700]!,
                                      strokeWidth: 4.0,
                                      borderStrokeWidth: 1.0,
                                      borderColor: Colors.greenAccent,
                                    ),
                                  ],
                                ),
                              // Marcador de origem
                              if (viewModel.startLatitude != null &&
                                  viewModel.startLongitude != null)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: LatLng(
                                        viewModel.startLatitude!,
                                        viewModel.startLongitude!,
                                      ),
                                      width: 50,
                                      height: 50,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: Colors.green[600],
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.green
                                                      .withValues(alpha: 0.4),
                                                  blurRadius: 12,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.location_on,
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                          ),
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 3,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                              // Marcador de destino
                              if (viewModel.endLatitude != null &&
                                  viewModel.endLongitude != null)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: LatLng(
                                        viewModel.endLatitude!,
                                        viewModel.endLongitude!,
                                      ),
                                      width: 50,
                                      height: 50,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: Colors.red[600],
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.red
                                                      .withValues(alpha: 0.4),
                                                  blurRadius: 12,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.location_on,
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                          ),
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 3,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),

                          // Botões de ação
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: Column(
                              children: [
                                FloatingActionButton(
                                  heroTag: 'center',
                                  backgroundColor: const Color(0xFF1B7E3D),
                                  mini: true,
                                  onPressed: () async {
                                    await viewModel.requestGPSLocation();
                                    if (viewModel.currentLatitude != 0 &&
                                        viewModel.currentLongitude != 0) {
                                      await _mapsService.moveCameraTo(
                                        LatLng(
                                          viewModel.currentLatitude,
                                          viewModel.currentLongitude,
                                        ),
                                        zoom: viewModel.zoomLevel,
                                      );
                                    }
                                  },
                                  child: const Icon(
                                    Icons.gps_fixed,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                FloatingActionButton(
                                  heroTag: 'zoom_in',
                                  backgroundColor: Colors.grey[400],
                                  mini: true,
                                  onPressed: () async {
                                    await _mapsService.zoomIn();
                                  },
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                FloatingActionButton(
                                  heroTag: 'zoom_out',
                                  backgroundColor: Colors.grey[400],
                                  mini: true,
                                  onPressed: () async {
                                    await _mapsService.zoomOut();
                                  },
                                  child: const Icon(
                                    Icons.remove,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Indicador quando modo de clique está ativo
                          if (viewModel.mapClickMode != null)
                            Positioned(
                              top: 16,
                              left: 16,
                              right: 16,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: viewModel.mapClickMode == 0
                                      ? Colors.green[600]
                                      : Colors.red[600],
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        viewModel.mapClickMode == 0
                                            ? 'Clique no mapa para definir origem'
                                            : 'Clique no mapa para definir destino',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showCalculatingRoute(BuildContext context) {
    final viewModel = context.read<MapViewModel>();
    
    // Mostrar loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calculando melhor rota com algoritmo A*...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Origem: ${viewModel.startAddress ?? "Não definido"}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Destino: ${viewModel.endAddress ?? "Não definido"}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.green[700],
      ),
    );
    
    // Calcular rota
    viewModel.calcularMelhorRota().then((_) {
      if (viewModel.dadosRotaUI != null) {
        // Mostrar resultado
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '✅ Rota Calculada!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tempo: ${viewModel.dadosRotaUI!.tempoFormatado}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Distância: ${viewModel.dadosRotaUI!.distancia}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Semáforos: ${viewModel.dadosRotaUI!.semaforosNosCaminho}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.green[700],
          ),
        );
        
        // Redesenhar mapa para mostrar a rota
        setState(() {});
      } else if (viewModel.errorMessage != null) {
        // Mostrar erro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ ${viewModel.errorMessage}',
              style: const TextStyle(color: Colors.white),
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    });
  }

}
