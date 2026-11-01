import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

class RequestStatusChip extends StatelessWidget {
  const RequestStatusChip({super.key, required this.status});

  final AdoptionRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (background, foreground) = switch (status) {
      AdoptionRequestStatus.pending => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      AdoptionRequestStatus.approved => (scheme.primaryContainer, scheme.onPrimaryContainer),
      AdoptionRequestStatus.rejected => (scheme.errorContainer, scheme.onErrorContainer),
      AdoptionRequestStatus.withdrawn => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(status.label, style: theme.textTheme.labelMedium?.copyWith(color: foreground)),
    );
  }
}
