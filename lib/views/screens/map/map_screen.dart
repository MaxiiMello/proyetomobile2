import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import '../../../services/maps_service.dart';
import '../../../viewmodels/map_viewmodel.dart';
import 'package:proyetomobile2/views/screens/plans/premium_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final MapsService _mapsService = MapsService.instance;
  late TextEditingController _startController;
  late TextEditingController _endController;
  bool _initialized = false;
  LatLng? _downloadCenter;
  double _downloadRadiusKm = 2.0;
  bool _downloadSelectionActive = false;
  LatLng? _lastNavigationCenter;

  @override
  void initState() {
    super.initState();
    _startController = TextEditingController();
    _endController = TextEditingController();

    _mapsService.setMapController(_mapController);

    _startController.addListener(() {
      final viewModel = context.read<MapViewModel>();
      viewModel.setActiveSuggestionMode(0);
      if (_startController.text.isNotEmpty) {
        viewModel.getAddressSuggestions(_startController.text);
      } else {
        viewModel.clearSuggestions();
      }
    });

    _endController.addListener(() {
      final viewModel = context.read<MapViewModel>();
      viewModel.setActiveSuggestionMode(1);
      if (_endController.text.isNotEmpty) {
        viewModel.getAddressSuggestions(_endController.text);
      } else {
        viewModel.clearSuggestions();
      }
    });

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
    _mapController.move(LatLng(latitude, longitude), 15.0);
  }

  void _fitBothPoints(MapViewModel viewModel) {
    if (viewModel.startLatitude != null &&
        viewModel.startLongitude != null &&
        viewModel.endLatitude != null &&
        viewModel.endLongitude != null) {
      final bounds = LatLngBounds(
        LatLng(viewModel.startLatitude!, viewModel.startLongitude!),
        LatLng(viewModel.endLatitude!, viewModel.endLongitude!),
      );

      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(100)),
      );
    }
  }

  LatLng _getMapCenter(MapViewModel viewModel) {
    return _mapController.camera.center;
  }

  void _centerOnUserIfNavigating(MapViewModel viewModel) {
    if (!viewModel.isNavigating) {
      return;
    }

    final current = LatLng(
      viewModel.currentLatitude,
      viewModel.currentLongitude,
    );

    if (_lastNavigationCenter != null &&
        _lastNavigationCenter!.latitude == current.latitude &&
        _lastNavigationCenter!.longitude == current.longitude) {
      return;
    }

    _lastNavigationCenter = current;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.move(current, viewModel.zoomLevel);
    });
  }

  Future<void> _handleDownload(MapViewModel viewModel) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B7E3D)),
        ),
      ),
    );

    final center = _downloadCenter ?? _getMapCenter(viewModel);

    await viewModel.downloadQuadroAt(
      latitude: center.latitude,
      longitude: center.longitude,
      radiusKm: _downloadRadiusKm,
    );

    if (!mounted) return;

    Navigator.pop(context);

    final message = viewModel.downloadStatusMessage;
    if (message == null) return;

    if (message == 'LIMITE_GRATIS_ATINGIDO') {
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PremiumScreen()),
      );
      return;
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: message.startsWith('Erro')
            ? Colors.red[700]
            : Colors.green[700],
      ),
    );
  }

  void _openDownloadSheet(MapViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final center = _downloadCenter ?? _getMapCenter(viewModel);

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Download de quadro offline',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Centro: ${center.latitude.toStringAsFixed(5)}, '
                    '${center.longitude.toStringAsFixed(5)}',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          final mapCenter = _getMapCenter(viewModel);
                          setState(() {
                            _downloadCenter = mapCenter;
                          });
                          setModalState(() {});
                        },
                        icon: const Icon(Icons.center_focus_strong, size: 18),
                        label: const Text('Usar centro do mapa'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _downloadSelectionActive = true;
                          });
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.touch_app, size: 18),
                        label: const Text('Selecionar no mapa'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Raio: ${_downloadRadiusKm.toStringAsFixed(1)} km'),
                  Slider(
                    value: _downloadRadiusKm,
                    min: 1.0,
                    max: 10.0,
                    divisions: 18,
                    label: '${_downloadRadiusKm.toStringAsFixed(1)} km',
                    onChanged: (value) {
                      setModalState(() {
                        _downloadRadiusKm = value;
                      });
                    },
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleDownload(viewModel),
                      icon: const Icon(Icons.download),
                      label: const Text('Baixar quadro'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B7E3D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (kIsWeb)
                    Text(
                      'Download offline nao esta disponivel no Web.',
                      style: TextStyle(color: Colors.red[700]),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Consumer<MapViewModel>(
                builder: (context, viewModel, _) {
                  _centerOnUserIfNavigating(viewModel);
                  return Column(
                    children: [
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
                                  if (viewModel.activeSuggestionMode == 0) {
                                    viewModel.selectStartPoint(suggestion);
                                    _startController.text = suggestion;
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          if (viewModel.startLatitude != null &&
                                              viewModel.startLongitude !=
                                                  null) {
                                            _animateToPoint(
                                              viewModel.startLatitude!,
                                              viewModel.startLongitude!,
                                            );
                                          }
                                        });
                                  } else {
                                    viewModel.selectEndPoint(suggestion);
                                    _endController.text = suggestion;
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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

                      if (viewModel.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              border: Border.all(color: Colors.red[300]!),
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

                      if (viewModel.hasCompleteRoute)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B7E3D),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                _fitBothPoints(viewModel);
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
                              border: Border.all(color: Colors.blue[300]!),
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
                                    'Dica: Use o botao 👆 para clicar no mapa\n(mais rapido e sem limite de requisicoes)',
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
                      if (viewModel.rotaCalculada != null &&
                          viewModel.rotaCalculada!.temRota)
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: viewModel.isNavigating
                                    ? Colors.red[600]
                                    : Colors.green[700],
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () async {
                                if (viewModel.isNavigating) {
                                  await viewModel.stopNavigation();
                                  return;
                                }
                                await viewModel.startNavigation();
                              },
                              icon: Icon(
                                viewModel.isNavigating
                                    ? Icons.stop
                                    : Icons.navigation,
                                color: Colors.white,
                                size: 18,
                              ),
                              label: Text(
                                viewModel.isNavigating
                                    ? 'Parar rota'
                                    : 'Iniciar rota',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (viewModel.rotaCalculada != null &&
                          viewModel.rotaCalculada!.temRota)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              border: Border.all(color: Colors.green[200]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.route,
                                  color: Colors.green[700],
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Distancia: ${viewModel.distanciaKmLabel}',
                                        style: TextStyle(
                                          color: Colors.green[700],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'Tempo medio (40 km/h): ${viewModel.tempoMedioLabel}',
                                        style: TextStyle(
                                          color: Colors.green[700],
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
                    ],
                  );
                },
              ),
            ),

            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!, width: 1),
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
                              onPositionChanged:
                                  (MapCamera position, bool hasGesture) {
                                    viewModel.zoomLevel = position.zoom;
                                  },
                              onTap: (tapPosition, point) async {
                                if (_downloadSelectionActive) {
                                  setState(() {
                                    _downloadCenter = point;
                                    _downloadSelectionActive = false;
                                  });
                                  return;
                                }

                                if (viewModel.mapClickMode != null) {
                                  final selectionMode = viewModel.mapClickMode;
                                  await viewModel.handleMapClick(
                                    point.latitude,
                                    point.longitude,
                                  );
                                  if (selectionMode == 0 &&
                                      viewModel.startAddress != null) {
                                    _startController.text =
                                        viewModel.startAddress!;
                                  } else if (selectionMode == 1 &&
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
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(
                                      viewModel.currentLatitude,
                                      viewModel.currentLongitude,
                                    ),
                                    width: 36,
                                    height: 36,
                                    child: Transform.rotate(
                                      angle:
                                          ((viewModel.currentHeading ?? 0) *
                                              math.pi) /
                                          180,
                                      child: const Icon(
                                        Icons.navigation,
                                        color: Colors.blue,
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_downloadCenter != null)
                                CircleLayer(
                                  circles: [
                                    CircleMarker(
                                      point: _downloadCenter!,
                                      radius: _downloadRadiusKm * 1000,
                                      useRadiusInMeter: true,
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      borderColor: Colors.blue[600]!,
                                      borderStrokeWidth: 1,
                                    ),
                                  ],
                                ),
                              if (_downloadCenter != null)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _downloadCenter!,
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.download_for_offline,
                                        color: Colors.blue,
                                        size: 32,
                                      ),
                                    ),
                                  ],
                                ),
                              if (viewModel.rotaCalculada != null &&
                                  viewModel
                                      .rotaCalculada!
                                      .caminhoFinal
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
                                                  color: Colors.red.withValues(
                                                    alpha: 0.4,
                                                  ),
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

                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: Column(
                              children: [
                                FloatingActionButton(
                                  heroTag: 'download_tile',
                                  backgroundColor: Colors.blue[600],
                                  mini: true,
                                  onPressed: () =>
                                      _openDownloadSheet(viewModel),
                                  child: const Icon(
                                    Icons.download,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                FloatingActionButton(
                                  heroTag: 'wearable_btn',
                                  backgroundColor: Colors.black,
                                  mini: true,
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/wearable');
                                  },
                                  child: const Icon(
                                    Icons.watch,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const SizedBox(height: 12),
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

                          if (viewModel.mapClickMode != null)
                            Positioned(
                              top: 16,
                              left: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
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
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
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
                          if (_downloadSelectionActive)
                            Positioned(
                              top: 16,
                              left: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[700],
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.download,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Clique no mapa para definir o centro do quadro',
                                        style: TextStyle(color: Colors.white),
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
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Destino: ${viewModel.endAddress ?? "Não definido"}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.green[700],
      ),
    );

    viewModel.calcularMelhorRota().then((_) {
      if (viewModel.dadosRotaUI != null) {
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
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                Text(
                  'Distância: ${viewModel.dadosRotaUI!.distancia}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                Text(
                  'Semáforos: ${viewModel.dadosRotaUI!.semaforosNosCaminho}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.green[700],
          ),
        );

        setState(() {});
      } else if (viewModel.errorMessage != null) {
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
