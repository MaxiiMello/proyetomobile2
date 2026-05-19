import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../services/maps_service.dart';
import '../../viewmodels/map_viewmodel.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  final MapsService _mapsService = MapsService.instance;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<MapViewModel>(
        builder: (context, viewModel, _) {
          // Se nenhuma localização foi carregada ainda, mostrar loading
          if (viewModel.currentLatitude == 0 && viewModel.currentLongitude == 0) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Se houver erro, mostrar mensagem
          if (viewModel.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    viewModel.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      viewModel.requestGPSLocation();
                    },
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              // Google Map
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    viewModel.currentLatitude,
                    viewModel.currentLongitude,
                  ),
                  zoom: viewModel.zoomLevel,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onCameraMove: (CameraPosition position) {
                  // Atualizar zoom no viewmodel quando câmera se move
                  viewModel.zoomLevel = position.zoom;
                },
              ),

              // Botões de zoom (inferior direito)
              Positioned(
                bottom: 80,
                right: 16,
                child: Column(
                  children: [
                    FloatingActionButton(
                      heroTag: 'zoom_in',
                      mini: true,
                      onPressed: () async {
                        await _mapsService.zoomIn();
                      },
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton(
                      heroTag: 'zoom_out',
                      mini: true,
                      onPressed: () async {
                        await _mapsService.zoomOut();
                      },
                      child: const Icon(Icons.remove),
                    ),
                  ],
                ),
              ),

              // Botão de localização atual (inferior direito)
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  heroTag: 'my_location',
                  onPressed: () async {
                    await viewModel.requestGPSLocation();
                    if (viewModel.currentLatitude != 0 &&
                        viewModel.currentLongitude != 0) {
                      // Mover câmera para localização atual usando Google Maps
                      await _mapController.animateCamera(
                        CameraUpdate.newLatLng(
                          LatLng(
                            viewModel.currentLatitude,
                            viewModel.currentLongitude,
                          ),
                        ),
                      );
                    }
                  },
                  child: const Icon(Icons.my_location),
                ),
              ),

              // Barra de busca (superior)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: SearchBar(
                  viewModel: viewModel,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class SearchBar extends StatefulWidget {
  final MapViewModel viewModel;

  const SearchBar({
    super.key,
    required this.viewModel,
  });

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar destino...',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
        ),
        onChanged: (value) {
          setState(() {});
        },
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            widget.viewModel.searchDestination(value);
          }
        },
      ),
    );
  }
}

extension on MapViewModel {
  void searchDestination(String value) {}
}
