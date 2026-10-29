import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../../format.dart';

/// The wide layout's list: one row per animal, hover and selection highlight, two columns dropped when narrow.
class AnimalsTable extends StatelessWidget {
  const AnimalsTable({
    super.key,
    required this.animals,
    required this.selectedId,
    required this.now,
    required this.onSelect,
  });

  final List<Animal> animals;
  final AnimalId? selectedId;
  final DateTime now;
  final ValueChanged<AnimalId> onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 640;
          return Column(
            children: [
              _HeaderRow(compact: compact),
              const Divider(),
              Expanded(
                child: ListView.separated(
                  itemCount: animals.length,
                  separatorBuilder: (_, _) => const Divider(indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final animal = animals[index];
                    return AnimalsTableRow(
                      key: ValueKey(animal.id),
                      animal: animal,
                      now: now,
                      compact: compact,
                      selected: animal.id == selectedId,
                      onTap: () => onSelect(animal.id),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

const _name = 4;
const _species = 2;
const _age = 3;
const _enclosure = 2;
const _status = 4;
const _received = 3;

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    Widget cell(int flex, String text) => Expanded(
      flex: flex,
      child: Text(text, style: style),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Row(
        children: [
          cell(_name, 'IME'),
          cell(_species, 'VRSTA'),
          if (!compact) cell(_age, 'STAROST'),
          cell(_enclosure, 'PROSTOR'),
          cell(_status, 'STATUS'),
          if (!compact) cell(_received, 'PRIMLJENA'),
        ],
      ),
    );
  }
}

class AnimalsTableRow extends StatelessWidget {
  const AnimalsTableRow({
    super.key,
    required this.animal,
    required this.now,
    required this.compact,
    required this.selected,
    required this.onTap,
  });

  final Animal animal;
  final DateTime now;
  final bool compact;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget cell(int flex, Widget child) => Expanded(flex: flex, child: child);
    Widget text(String value) => Text(value, style: theme.textTheme.bodyMedium, overflow: TextOverflow.ellipsis);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: selected ? scheme.tertiaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          hoverColor: scheme.tertiaryContainer.withValues(alpha: 0.35),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                cell(
                  _name,
                  Row(
                    children: [
                      AnimalPhoto(animal: animal, size: 40),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          animal.name.text,
                          style: theme.textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                cell(_species, text(animal.species.label)),
                if (!compact) cell(_age, text(formatAge(animal.ageInMonths(now)))),
                cell(_enclosure, text(animal.enclosureId.value)),
                cell(
                  _status,
                  Align(
                    alignment: Alignment.centerLeft,
                    child: StatusBadge(status: animal.status),
                  ),
                ),
                if (!compact) cell(_received, text(formatDate(animal.receivedAt))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
