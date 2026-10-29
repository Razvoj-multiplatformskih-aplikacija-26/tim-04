import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../../format.dart';

/// The narrow layout's list: one card per animal; a tap opens the details full screen.
class AnimalsList extends StatelessWidget {
  const AnimalsList({super.key, required this.animals, required this.now, required this.onSelect});

  final List<Animal> animals;
  final DateTime now;
  final ValueChanged<AnimalId> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: animals.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final animal = animals[index];
        return Card(
          key: ValueKey(animal.id),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: AnimalPhoto(animal: animal),
            title: Text(animal.name.text),
            subtitle: Text('${animal.species.label} · ${formatAge(animal.ageInMonths(now))}'),
            trailing: StatusBadge(status: animal.status),
            onTap: () => onSelect(animal.id),
          ),
        );
      },
    );
  }
}
