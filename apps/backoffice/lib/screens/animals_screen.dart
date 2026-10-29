import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import '../dependencies.dart';

/// The URL owns the selection: a tap changes the address, and the screen passes the address on to the bloc.
class AnimalsScreen extends StatefulWidget {
  const AnimalsScreen({super.key, this.selectedId});

  static const path = '/animals';

  static String pathFor(AnimalId? selected) => selected == null ? path : '$path?selected=${selected.value}';

  final AnimalId? selectedId;

  @override
  State<AnimalsScreen> createState() => _AnimalsScreenState();
}

class _AnimalsScreenState extends State<AnimalsScreen> {
  late final AnimalsBloc _bloc = context.read<AnimalsBloc>();

  @override
  void initState() {
    super.initState();
    _bloc.add(AnimalSelected(widget.selectedId));
  }

  @override
  void didUpdateWidget(AnimalsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId) _bloc.add(AnimalSelected(widget.selectedId));
  }

  /// Tapping the selected animal again clears the selection.
  void _toggle(AnimalId id) => context.go(AnimalsScreen.pathFor(id == widget.selectedId ? null : id));

  @override
  Widget build(BuildContext context) {
    final fake = context.read<BackofficeDependencies>().fakeRepository;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Životinje'),
        actions: [
          PopupMenuButton<AnimalsFilter>(
            tooltip: 'Filter',
            icon: const Icon(Icons.filter_list),
            onSelected: (filter) => _bloc.add(AnimalsFilterChanged(filter)),
            itemBuilder: (_) => [
              for (final filter in AnimalsFilter.values)
                PopupMenuItem(value: filter, child: Text(_filterLabel(filter))),
            ],
          ),
          if (fake != null)
            TextButton.icon(
              onPressed: () {
                fake.failNextRequest();
                _bloc.add(const AnimalsRetried());
              },
              icon: const Icon(Icons.bug_report_outlined),
              label: const Text('Simuliraj grešku'),
            ),
        ],
      ),
      body: BlocBuilder<AnimalsBloc, AnimalsState>(
        builder: (context, state) => switch (state) {
          AnimalsLoading() => const LoadingView(),
          AnimalsFailure() => FailureView(onRetry: () => _bloc.add(const AnimalsRetried())),
          AnimalsEmpty(:final filter) => EmptyView(message: 'Nema životinja za filter „${_filterLabel(filter)}“.'),
          AnimalsLoaded(:final animals, :final selectedId) => ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: animals.length,
            itemBuilder: (context, index) {
              final animal = animals[index];
              return ListTile(
                leading: AnimalPhoto(animal: animal),
                title: Text(animal.name.text),
                subtitle: Text(animal.species.label),
                trailing: StatusBadge(status: animal.status),
                selected: animal.id == selectedId,
                onTap: () => _toggle(animal.id),
              );
            },
          ),
        },
      ),
    );
  }
}

/// Stays in the app: `ui` must not depend on `blocs`, and AnimalsFilter lives there.
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
