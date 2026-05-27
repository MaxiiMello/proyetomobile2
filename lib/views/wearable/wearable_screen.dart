import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/map_viewmodel.dart';

class WearableScreen extends StatelessWidget {
  const WearableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ClipOval(
          child: Container(
            width: 250,
            height: 250,
            color: Colors.black,
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.route,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'INICIAR ROTA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B7E3D),
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(24),
                    ),
                    onPressed: () async {
                      final viewModel = context.read<MapViewModel>();
                      await viewModel.startNavigation();

                      if (!context.mounted) return;

                      if (viewModel.isNavigating) {
                        Navigator.pop(context);
                        return;
                      }

                      final message = viewModel.errorMessage ??
                          'Defina uma rota antes de iniciar.';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          backgroundColor: Colors.red[700],
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.play_arrow,
                      size: 48,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}