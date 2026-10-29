import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

class AnimalDetailScreen extends StatelessWidget {
  const AnimalDetailScreen({super.key, required this.id});

  final AnimalId id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Životinja')),
      body: Center(child: Text('Životinja ${id.value}')),
    );
  }
}