import 'package:flutter/material.dart';

class EquipmentListScreen extends StatelessWidget {
  const EquipmentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorer'),
      ),
      body: const Center(
        child: Text('Liste des annonces disponibles.'),
      ),
    );
  }
}
