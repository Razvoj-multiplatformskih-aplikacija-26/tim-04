import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

class RequestFormScreen extends StatelessWidget {
  const RequestFormScreen({super.key, required this.animalId});

  final AnimalId animalId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zahtev za udomljavanje')),
      body: Center(child: Text('Zahtev za životinju ${animalId.value}')),
    );
  }
}
