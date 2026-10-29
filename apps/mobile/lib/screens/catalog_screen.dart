import 'package:blocs/blocs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

import '../widgets/animal_card.dart';
import '../widgets/animals_filter_bar.dart';
import '../widgets/fake_data_controls.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AnimalsBloc>();
    return Scaffold(
      appBar: AppBar(title: const Text('Životinje'), actions: [if (kDebugMode) const FakeDataControls()]),
      body: BlocBuilder<AnimalsBloc, AnimalsState>(
        builder: (context, state) {
          final filter = switch (state) {
            AnimalsLoaded(:final filter) || AnimalsEmpty(:final filter) => filter,
            AnimalsLoading() || AnimalsFailure() => null,
          };
          return Column(
            children: [
              if (filter != null)
                AnimalsFilterBar(selected: filter, onSelected: (filter) => bloc.add(AnimalsFilterChanged(filter))),
              Expanded(
                child: switch (state) {
                  AnimalsLoading() => const LoadingView(),
                  AnimalsFailure() => FailureView(onRetry: () => bloc.add(const AnimalsRetried())),
                  AnimalsEmpty() => const EmptyView(message: 'Nema životinja u ovom prikazu.'),
                  AnimalsLoaded(:final animals) => ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: animals.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => AnimalCard(animal: animals[index]),
                  ),
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
