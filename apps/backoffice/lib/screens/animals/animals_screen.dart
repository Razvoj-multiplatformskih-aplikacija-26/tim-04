import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import '../../dependencies.dart';
import 'animal_details.dart';
import 'animals_filter_bar.dart';
import 'animals_list.dart';
import 'animals_table.dart';


class AnimalsScreen extends StatefulWidget {
  const AnimalsScreen({super.key, this.selectedId});

  static const path = '/animals';

  
  static const wideBreakpoint = 840.0;

  static String pathFor(AnimalId? selected) => selected == null ? path : '$path?selected=${selected.value}';

  final AnimalId? selectedId;

  @override
  State<AnimalsScreen> createState() => _AnimalsScreenState();
}

class _AnimalsScreenState extends State<AnimalsScreen> {
  late final AnimalsBloc _bloc = context.read<AnimalsBloc>();
  late final BackofficeDependencies _dependencies = context.read<BackofficeDependencies>();

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

  void _select(AnimalId? id) => context.go(AnimalsScreen.pathFor(id));

  
  void _toggle(AnimalId id) => _select(id == widget.selectedId ? null : id);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnimalsBloc, AnimalsState>(
      builder: (context, state) => LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= AnimalsScreen.wideBreakpoint;
          final selected = state is AnimalsLoaded ? state.selected : null;
          if (!wide && selected != null) return _detailsPage(selected);
          return Scaffold(
            appBar: AppBar(title: const Text('Životinje'), actions: [..._simulateFailure(), const SizedBox(width: 8)]),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state case AnimalsLoaded(:final filter) || AnimalsEmpty(:final filter))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: AnimalsFilterBar(selected: filter, onChanged: (f) => _bloc.add(AnimalsFilterChanged(f))),
                  ),
                Expanded(child: _body(state, wide: wide)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _body(AnimalsState state, {required bool wide}) {
    final now = _dependencies.clock();
    return switch (state) {
      AnimalsLoading() => const LoadingView(),
      AnimalsFailure() => FailureView(onRetry: () => _bloc.add(const AnimalsRetried())),
      AnimalsEmpty(:final filter) => EmptyView(message: 'Nema životinja za filter „${filterLabel(filter)}“.'),
      AnimalsLoaded(:final animals, :final selectedId, :final selected) when wide => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: AnimalsTable(animals: animals, selectedId: selectedId, now: now, onSelect: _toggle),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 380,
              child: Card(
                child: selected == null
                    ? const EmptyView(message: 'Izaberite životinju iz tabele da vidite detalje.')
                    : Stack(
                        children: [
                          _details(selected),
                          Positioned(
                            top: 28,
                            right: 28,
                            child: IconButton.filledTonal(
                              tooltip: 'Zatvori detalje',
                              onPressed: () => _select(null),
                              icon: const Icon(Icons.close),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
      AnimalsLoaded(:final animals) => AnimalsList(animals: animals, now: now, onSelect: _select),
    };
  }

  Widget _detailsPage(Animal animal) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => _select(null)),
        title: Text(animal.name.text),
      ),
      body: _details(animal),
    );
  }

  Widget _details(Animal animal) {
    return BlocBuilder<AdoptionRequestBloc, AdoptionRequestState>(
      builder: (context, requests) =>
          AnimalDetails(animal: animal, requests: requests, now: _dependencies.clock(), nameOf: _dependencies.nameOf),
    );
  }

  List<Widget> _simulateFailure() {
    final fake = _dependencies.fakeRepository;
    if (fake == null) return const [];
    return [
      TextButton.icon(
        onPressed: () {
          fake.failNextRequest();
          _bloc.add(const AnimalsRetried());
        },
        icon: const Icon(Icons.bug_report_outlined),
        label: const Text('Simuliraj grešku'),
      ),
    ];
  }
}
