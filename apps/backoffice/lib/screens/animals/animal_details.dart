import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../../format.dart';

class AnimalDetails extends StatelessWidget {
  const AnimalDetails({
    super.key,
    required this.animal,
    required this.requests,
    required this.now,
    required this.nameOf,
  });

  final Animal animal;

  final AdoptionRequestState requests;
  final DateTime now;
  final String Function(UserId) nameOf;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AnimalPhoto.banner(animal: animal),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(animal.name.text, style: theme.textTheme.headlineMedium)),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: StatusBadge(status: animal.status),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${animal.species.label} · ${formatAge(animal.ageInMonths(now))} · prostor ${animal.enclosureId.value}',
          style: muted,
        ),
        const SizedBox(height: 16),
        _Fact(icon: Icons.info_outline, text: _statusDetail(animal.status)),
        _Fact(icon: Icons.home_outlined, text: 'U utočištu od ${formatDate(animal.receivedAt)}'),
        _Fact(icon: Icons.cake_outlined, text: 'Rođena ${formatDate(animal.birthDate)}'),
        const SizedBox(height: 20),
        Text('Opis', style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(animal.description, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 24),
        ..._requestsSection(context),
      ],
    );
  }

  List<Widget> _requestsSection(BuildContext context) {
    final theme = Theme.of(context);
    switch (requests) {
      case RequestsLoading():
        return [Text('Zahtevi za udomljavanje', style: theme.textTheme.titleMedium), const LinearProgressIndicator()];
      case RequestsFailure():
        return [
          Text('Zahtevi za udomljavanje', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          const Text('Zahtevi trenutno nisu dostupni.'),
        ];
      case RequestsLoaded(requests: final all):
        final mine = [
          for (final r in all)
            if (r.animalId == animal.id) r,
        ]..sort(_pendingFirstThenNewest);
        return [
          Text('Zahtevi za udomljavanje (${mine.length})', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (mine.isEmpty) Text('Još nema zahteva za ${animal.name.text}.', style: theme.textTheme.bodyMedium),
          for (final request in mine) _RequestCard(request: request, applicant: nameOf(request.applicantId)),
        ];
    }
  }

  String _statusDetail(AnimalStatus status) => switch (status) {
    Received(:final receivedBy, :final at) => 'Primio/la ${nameOf(receivedBy)}, ${formatDate(at)}',
    InQuarantine(:final since, :final until) => 'U karantinu od ${formatDate(since)} do ${formatDate(until)}',
    ReadyForAdoption(:final since) => 'Spremna za udomljavanje od ${formatDate(since)}',
    Reserved(:final approvedBy, :final at) => 'Rezervisana ${formatDate(at)}, odobrio/la ${nameOf(approvedBy)}',
    Adopted(:final adopterId, :final at) => 'Udomljena ${formatDate(at)}, udomitelj ${nameOf(adopterId)}',
    PermanentResident(:final reason) => 'Stalni stanar: $reason',
    Returned(:final reason, :final at) => 'Vraćena ${formatDate(at)}: $reason',
  };
}

int _pendingFirstThenNewest(AdoptionRequest a, AdoptionRequest b) {
  final pending =
      (b.status == AdoptionRequestStatus.pending ? 1 : 0) - (a.status == AdoptionRequestStatus.pending ? 1 : 0);
  return pending != 0 ? pending : b.createdAt.compareTo(a.createdAt);
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.tertiary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.applicant});

  final AdoptionRequest request;
  final String applicant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (background, foreground) = switch (request.status) {
      AdoptionRequestStatus.pending => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      AdoptionRequestStatus.approved => (scheme.primaryContainer, scheme.onPrimaryContainer),
      AdoptionRequestStatus.rejected ||
      AdoptionRequestStatus.withdrawn => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(applicant, style: theme.textTheme.titleSmall)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
                    child: Text(request.status.label, style: theme.textTheme.labelMedium?.copyWith(color: foreground)),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                formatDate(request.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(request.motivation.text, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
