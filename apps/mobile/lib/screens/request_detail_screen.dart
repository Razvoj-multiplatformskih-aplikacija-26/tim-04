import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

class RequestDetailScreen extends StatelessWidget {
  const RequestDetailScreen({super.key, required this.id});

  final AdoptionRequestId id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zahtev')),
      body: Center(child: Text('Zahtev ${id.value}')),
    );
  }
}