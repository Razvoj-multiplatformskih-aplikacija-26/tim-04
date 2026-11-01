import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:ui/ui.dart';

class RequestDetailScreen extends StatelessWidget {
  const RequestDetailScreen({super.key, required this.id});

  final AdoptionRequestId id;

  AdoptionRequest? _find(List<AdoptionRequest> requests) {
    for (final request in requests) {
      if (request.id == id) return request;
    }
    return null;
  }

  void _showNotice(BuildContext context, RequestsNotice notice) {
    final message = switch (notice) {
      RequestSaved() => 'Zahtev je povučen.',
      RequestRefused(:final error) => error.message,
      RequestFailed() => 'Povlačenje nije uspelo. Pokušajte ponovo.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    context.read<AdoptionRequestBloc>().add(const RequestsNoticeAcknowledged());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdoptionRequestBloc, AdoptionRequestState>(
      listenWhen: (previous, current) => current is RequestsLoaded && current.notice != null,
      listener: (context, state) => _showNotice(context, (state as RequestsLoaded).notice!),
      builder: (context, state) {
        final bloc = context.read<AdoptionRequestBloc>();
        switch (state) {
          case RequestsLoading():
            return const _Message(child: LoadingView());
          case RequestsFailure():
            return _Message(child: FailureView(onRetry: () => bloc.add(const MyRequestsRequested())));
          case RequestsLoaded(:final requests, :final busy):
            final request = _find(requests);
            if (request == null) return const _Message(child: EmptyView(message: 'Zahtev nije pronađen.'));
            return _RequestDetail(request: request, busy: busy);
        }
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zahtev')),
      body: child,
    );
  }
}

class _RequestDetail extends StatelessWidget {
  const _RequestDetail({required this.request, required this.busy});

  static final _date = DateFormat('d. MMMM y.', 'sr_Latn');

  final AdoptionRequest request;
  final bool busy;

  Future<void> _confirmWithdrawal(BuildContext context, String animalName) async {
    final bloc = context.read<AdoptionRequestBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Povući zahtev?'),
        content: Text('Vaš zahtev za udomljavanje ($animalName) biće povučen. Ovo ne može da se poništi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Povuci')),
        ],
      ),
    );
    if (confirmed != true) return;
    bloc.add(RequestWithdrawn(request.id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final animal = context.watch<AnimalsBloc>().animalById(request.animalId);
    final animalName = animal?.name.text ?? request.animalId.value;
    final canWithdraw = request.status == AdoptionRequestStatus.pending;
    return Scaffold(
      appBar: AppBar(title: const Text('Zahtev')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(header: true, child: Text(animalName, style: theme.textTheme.headlineMedium)),
              ),
              const SizedBox(width: 8),
              RequestStatusChip(status: request.status),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                _DetailRow(icon: Icons.event_outlined, label: 'Podnet', value: _date.format(request.createdAt)),
                const Divider(indent: 16, endIndent: 16),
                _DetailRow(icon: Icons.info_outline, label: 'Stanje', value: request.status.label),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Motivacija', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(request.motivation.text, style: theme.textTheme.bodyLarge),
        ],
      ),
      bottomNavigationBar: canWithdraw
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: OutlinedButton.icon(
                onPressed: busy ? null : () => _confirmWithdrawal(context, animalName),
                icon: busy
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : const Icon(Icons.undo),
                label: Text(busy ? 'Povlačenje…' : 'Povuci zahtev'),
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
