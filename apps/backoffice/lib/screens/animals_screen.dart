import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../dependencies.dart';

class AnimalsScreen extends StatelessWidget {
  const AnimalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fake = context.read<BackofficeDependencies>().fakeRepository;
    final bloc = context.read<AnimalsBloc>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Životinje'),
        actions: [
          PopupMenuButton<AnimalsFilter>(
            tooltip: 'Filter',
            icon: const Icon(Icons.filter_list),
            onSelected: (filter) => bloc.add(AnimalsFilterChanged(filter)),
            itemBuilder: (_) => [
              for (final filter in AnimalsFilter.values)
                PopupMenuItem(value: filter, child: Text(_filterLabel(filter))),
            ],
          ),
          if (fake != null)
            TextButton.icon(
              onPressed: () {
                fake.failNextRequest();
                bloc.add(const AnimalsRetried());
              },
              icon: const Icon(Icons.bug_report_outlined),
              label: const Text('Simuliraj grešku'),
            ),
        ],
      ),
      body: BlocBuilder<AnimalsBloc, AnimalsState>(
        builder: (context, state) => switch (state) {
          AnimalsLoading() => const Center(child: CircularProgressIndicator()),
          AnimalsFailure() => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48),
                const SizedBox(height: 12),
                const Text('Učitavanje nije uspelo.'),
                const SizedBox(height: 12),
                FilledButton(onPressed: () => bloc.add(const AnimalsRetried()), child: const Text('Pokušaj ponovo')),
              ],
            ),
          ),
          AnimalsEmpty(:final filter) => Center(child: Text('Nema životinja za filter „${_filterLabel(filter)}“.')),
          AnimalsLoaded(:final animals, :final selectedId) => ListView.separated(
            itemCount: animals.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final animal = animals[index];
              return ListTile(
                leading: const Icon(Icons.pets),
                title: Text(animal.name.text),
                subtitle: Text('${_speciesLabel(animal.species)} · ${_statusLabel(animal.status)}'),
                selected: animal.id == selectedId,
                onTap: () => bloc.add(AnimalSelected(animal.id)),
              );
            },
          ),
        },
      ),
    );
  }
}

String _filterLabel(AnimalsFilter filter) => switch (filter) {
  AnimalsFilter.all => 'Sve',
  AnimalsFilter.received => 'Primljene',
  AnimalsFilter.inQuarantine => 'U karantinu',
  AnimalsFilter.readyForAdoption => 'Spremne',
  AnimalsFilter.reserved => 'Rezervisane',
  AnimalsFilter.adopted => 'Udomljene',
  AnimalsFilter.permanentResident => 'Stalni stanari',
  AnimalsFilter.returned => 'Vraćene',
};

String _speciesLabel(Species species) => switch (species) {
  Species.dog => 'Pas',
  Species.cow => 'Krava',
  Species.goat => 'Koza',
  Species.horse => 'Konj',
};

String _statusLabel(AnimalStatus status) => switch (status) {
  Received() => 'Primljena',
  InQuarantine() => 'U karantinu',
  ReadyForAdoption() => 'Spremna za udomljavanje',
  Reserved() => 'Rezervisana',
  Adopted() => 'Udomljena',
  PermanentResident() => 'Stalni stanar',
  Returned() => 'Vraćena',
};
