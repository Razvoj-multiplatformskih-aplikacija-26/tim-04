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
    this.pendingRequests = const {},
  });

  final List<Animal> animals;
  final AnimalId? selectedId;
  final DateTime now;
  final ValueChanged<AnimalId> onSelect;

  /// How many requests are waiting for each animal; animals without any are left out.
  final Map<AnimalId, int> pendingRequests;

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
                      pendingRequests: pendingRequests[animal.id] ?? 0,
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
const _requests = 2;
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
          if (!compact) cell(_requests, 'ZAHTEVI'),
          if (!compact) cell(_received, 'PRIMLJENA'),
        ],
      ),
    );
  }
}

/// One animal in the table. Tab focuses it (a leaf-green outline shows where the focus is) and Enter or Space selects it.
class AnimalsTableRow extends StatefulWidget {
  const AnimalsTableRow({
    super.key,
    required this.animal,
    required this.now,
    required this.compact,
    required this.selected,
    required this.onTap,
    this.pendingRequests = 0,
  });

  final Animal animal;
  final DateTime now;
  final bool compact;
  final bool selected;
  final VoidCallback onTap;
  final int pendingRequests;

  @override
  State<AnimalsTableRow> createState() => _AnimalsTableRowState();
}

class _AnimalsTableRowState extends State<AnimalsTableRow> {
  bool _focused = false;

  @override
  void didUpdateWidget(AnimalsTableRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ↑/↓ can select a row that is scrolled out of view, so bring it back once it is laid out.
    if (widget.selected && !oldWidget.selected) WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
  }

  Future<void> _reveal() async {
    const duration = Duration(milliseconds: 150);
    // The first call scrolls down when the row is below the view, the second scrolls up when it is above.
    if (!mounted) return;
    await Scrollable.ensureVisible(
      context,
      duration: duration,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
    if (!mounted) return;
    await Scrollable.ensureVisible(
      context,
      duration: duration,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final animal = widget.animal;
    final compact = widget.compact;
    final now = widget.now;
    Widget cell(int flex, Widget child) => Expanded(flex: flex, child: child);
    Widget text(String value) => Text(value, style: theme.textTheme.bodyMedium, overflow: TextOverflow.ellipsis);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: widget.selected ? scheme.tertiaryContainer : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: _focused ? BorderSide(color: scheme.primary, width: 2) : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          hoverColor: scheme.tertiaryContainer.withValues(alpha: 0.35),
          focusColor: scheme.tertiaryContainer.withValues(alpha: 0.5),
          onFocusChange: (focused) => setState(() => _focused = focused),
          onTap: widget.onTap,
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
                    child: StatusBadge(status: animal.status, short: true),
                  ),
                ),
                if (!compact) cell(_requests, _PendingCount(count: widget.pendingRequests)),
                if (!compact) cell(_received, text(formatDate(animal.receivedAt))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The number of requests waiting for a decision, as a small rose pill; a dash when there are none.
class _PendingCount extends StatelessWidget {
  const _PendingCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (count == 0) {
      return Text('—', style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant));
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Tooltip(
        message: 'Zahteva na čekanju: $count',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(color: scheme.tertiaryContainer, borderRadius: BorderRadius.circular(999)),
          child: Text('$count', style: theme.textTheme.labelMedium?.copyWith(color: scheme.onTertiaryContainer)),
        ),
      ),
    );
  }
}
