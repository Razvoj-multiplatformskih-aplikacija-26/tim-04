import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(semanticsLabel: 'Učitavanje'));
  }
}

class FailureView extends StatelessWidget {
  const FailureView({super.key, this.message = 'Učitavanje nije uspelo.', required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _MessageView(
      icon: Icons.cloud_off_outlined,
      message: message,
      action: FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Pokušaj ponovo'),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.message, this.icon = Icons.local_florist_outlined});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => _MessageView(icon: icon, message: message);
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.tertiary),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
            if (action case final action?) ...[const SizedBox(height: 16), action],
          ],
        ),
      ),
    );
  }
}
