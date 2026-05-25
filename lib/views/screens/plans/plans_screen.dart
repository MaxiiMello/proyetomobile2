import 'package:flutter/material.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planes y Suscripciones'),
      ),
      body: const Center(
        child: Text('Planes disponibles'),
      ),
    );
  }
}
