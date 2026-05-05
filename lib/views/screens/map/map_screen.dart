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
  late TextEditingController _searchController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    
    // Listener para buscar sugestões enquanto digita
    _searchController.addListener(() {
      final viewModel = context.read<MapViewModel>();
      if (_searchController.text.isNotEmpty) {
        viewModel.getAddressSuggestions(_searchController.text);
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
    _searchController.dispose();
    // GoogleMapController é gerenciado automaticamente pelo plugin
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
      // Search Bar Header com Sugestões
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Consumer<MapViewModel>(
                builder: (context, viewModel, _) {
                  return Column(
                    children: [
                      // Campo de busca
                      TextField(
                        controller: _searchController,
                        style: const TextStyle(fontSize: 14),
                        onChanged: (value) {
                          // Listener já está em initState, mas isso garante a atualização da UI
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: 'Selecionar destino...',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[500],
                            size: 20,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: Colors.grey[600],
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    viewModel.selectedDestination = null;
                                    viewModel.clearSuggestions();
                                  },
                                )
                              : Icon(
                                  Icons.location_on,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFF1B7E3D),
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),

                      // Lista de sugestões
                      if (viewModel.addressSuggestions.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: viewModel.addressSuggestions.length,
                            itemBuilder: (context, index) {
                              final suggestion = viewModel.addressSuggestions[index];
                              return ListTile(
                                leading: const Icon(
                                  Icons.location_on_outlined,
                                  color: Color(0xFF1B7E3D),
                                  size: 18,
                                ),
                                title: Text(
                                  suggestion,
                                  style: const TextStyle(fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () {
                                  // Selecionar o endereço e mover o mapa
                                  viewModel.selectAddress(suggestion);
                                  _searchController.text = suggestion;
                                  FocusScope.of(context).unfocus();
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            // Mapa interactivo con ubicación en tiempo real
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
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
                                viewModel.currentLatitude != 0 ? viewModel.currentLatitude : -30.8831,
                                viewModel.currentLongitude != 0 ? viewModel.currentLongitude : -55.5350,
                              ),
                              initialZoom: viewModel.zoomLevel > 0 ? viewModel.zoomLevel : 14.0,
                              onPositionChanged: (MapCamera position, bool hasGesture) {
                                viewModel.zoomLevel = position.zoom;
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.sinalverde.app',
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
                                  backgroundColor:
                                      const Color(0xFF1B7E3D),
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
}
