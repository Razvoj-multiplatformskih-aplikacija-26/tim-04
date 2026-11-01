import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AdoptionRequestBloc>();
    return Scaffold(
      appBar: AppBar(title: const Text('Moji zahtevi')),
      body: BlocBuilder<AdoptionRequestBloc, AdoptionRequestState>(
        builder: (context, state) => switch (state) {
          RequestsLoading() => const LoadingView(),
          RequestsFailure() => FailureView(onRetry: () => bloc.add(const MyRequestsRequested())),
          RequestsLoaded(isEmpty: true) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const EmptyView(message: 'Još niste podneli nijedan zahtev.', icon: Icons.assignment_outlined),
              FilledButton.tonal(onPressed: () => context.go('/'), child: const Text('Pogledaj životinje')),
            ],
          ),
          RequestsLoaded(:final requests) => _RequestList(requests: requests),
        },
      ),
    );
  }
}

class _RequestList extends StatelessWidget {
  const _RequestList({required this.requests});

  final List<AdoptionRequest> requests;

  @override
  Widget build(BuildContext context) {
    final newestFirst = [...requests]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: newestFirst.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _RequestCard(request: newestFirst[index]),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final AdoptionRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final animal = context.watch<AnimalsBloc>().animalById(request.animalId);
    return Card(
      child: InkWell(
        onTap: () => context.push('/requests/${request.id.value}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(radius: 28, child: Icon(Icons.pets, color: theme.colorScheme.primary)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(animal?.name.text ?? request.animalId.value, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('Podnet ${formatLongDate(request.createdAt)}', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              RequestStatusChip(status: request.status),
            ],
          ),
        ),
      ),
    );
  }
}
