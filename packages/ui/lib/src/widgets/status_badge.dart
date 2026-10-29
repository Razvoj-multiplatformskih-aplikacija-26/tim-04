import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../text/serbian.dart';

/// Pastel pill with the animal's status. The pastels read well on both the light and the dark theme.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final AnimalStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      Received() => (const Color(0xFFE3E8F0), const Color(0xFF2E3A4D)),
      InQuarantine() => (const Color(0xFFFCE7B8), const Color(0xFF5A4100)),
      ReadyForAdoption() => (const Color(0xFFD8EBC4), const Color(0xFF2F5212)),
      Reserved() => (const Color(0xFFF5D5ED), const Color(0xFF6A2457)),
      Adopted() => (const Color(0xFFB9D39C), const Color(0xFF1C3309)),
      PermanentResident() => (const Color(0xFFE6DDF5), const Color(0xFF3F2E66)),
      Returned() => (const Color(0xFFF9D9CF), const Color(0xFF6B2A17)),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(status.label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: foreground)),
    );
  }
}
