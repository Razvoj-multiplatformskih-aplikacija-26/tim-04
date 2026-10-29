import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

class AnimalCard extends StatelessWidget {
  const AnimalCard({super.key, required this.animal});

  final Animal animal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: () => context.push('/animals/${animal.id.value}'),
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
                    Text(animal.name.text, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(animal.species.label, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: animal.status),
            ],
          ),
        ),
      ),
    );
  }
}
