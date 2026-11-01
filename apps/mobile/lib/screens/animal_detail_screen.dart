import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ui/ui.dart';

class AnimalDetailScreen extends StatelessWidget {
  const AnimalDetailScreen({super.key, required this.id});

  final AnimalId id;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnimalsBloc, AnimalsState>(
      builder: (context, state) {
        final bloc = context.read<AnimalsBloc>();
        switch (state) {
          case AnimalsLoading():
            return const _Message(child: LoadingView());
          case AnimalsFailure():
            return _Message(child: FailureView(onRetry: () => bloc.add(const AnimalsRetried())));
          case AnimalsEmpty() || AnimalsLoaded():
            final animal = bloc.animalById(id);
            if (animal == null) return const _Message(child: EmptyView(message: 'Životinja nije pronađena.'));
            return _AnimalDetail(animal: animal);
        }
      },
    );
  }
}

/// Screen with a plain title around a loading, failure or not-found view.
class _Message extends StatelessWidget {
  const _Message({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Životinja')),
      body: child,
    );
  }
}

class _AnimalDetail extends StatelessWidget {
  const _AnimalDetail({required this.animal});

  static final _date = DateFormat('d. MMMM y.', 'sr_Latn');

  final Animal animal;

  String _age(int months) => '${months ~/ 12} god. i ${months % 12} mes.';

  List<Widget> _statusRows(AnimalStatus status) => switch (status) {
    Received() || ReadyForAdoption() => const [],
    InQuarantine(:final until) => [
      const Divider(indent: 16, endIndent: 16),
      _DetailRow(icon: Icons.medical_services_outlined, label: 'U karantinu do', value: _date.format(until)),
    ],
    Reserved() => [
      const Divider(indent: 16, endIndent: 16),
      const _DetailRow(icon: Icons.lock_clock_outlined, label: 'Rezervisana', value: 'Za drugog udomitelja'),
    ],
    Adopted(:final at) => [
      const Divider(indent: 16, endIndent: 16),
      _DetailRow(icon: Icons.favorite_outline, label: 'Udomljena', value: _date.format(at)),
    ],
    PermanentResident(:final reason) => [
      const Divider(indent: 16, endIndent: 16),
      _DetailRow(icon: Icons.home_work_outlined, label: 'Ostaje u utočištu', value: reason),
    ],
    Returned(:final reason, :final at) => [
      const Divider(indent: 16, endIndent: 16),
      _DetailRow(icon: Icons.undo_outlined, label: 'Vraćena ${_date.format(at)}', value: reason),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(animal.name.text)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              CircleAvatar(radius: 40, child: Icon(Icons.pets, size: 40, color: theme.colorScheme.primary)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(header: true, child: Text(animal.name.text, style: theme.textTheme.headlineMedium)),
                    const SizedBox(height: 8),
                    StatusBadge(status: animal.status),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                _DetailRow(icon: Icons.pets_outlined, label: 'Vrsta', value: animal.species.label),
                const Divider(indent: 16, endIndent: 16),
                _DetailRow(
                  icon: Icons.cake_outlined,
                  label: 'Starost',
                  value: _age(animal.ageInMonths(DateTime.now())),
                ),
                const Divider(indent: 16, endIndent: 16),
                _DetailRow(icon: Icons.home_outlined, label: 'Boks', value: animal.enclosureId.value),
                const Divider(indent: 16, endIndent: 16),
                _DetailRow(icon: Icons.event_outlined, label: 'Primljena', value: _date.format(animal.receivedAt)),
                ..._statusRows(animal.status),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('O životinji', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(animal.description, style: theme.textTheme.bodyLarge),
        ],
      ),
      bottomNavigationBar: animal.isAdoptable
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: FilledButton.icon(
                onPressed: () => context.push('/animals/${animal.id.value}/request'),
                icon: const Icon(Icons.favorite_outline),
                label: const Text('Podnesi zahtev'),
              ),
            )
          : null,
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      subtitle: Text(value, style: theme.textTheme.titleMedium),
    );
  }
}
