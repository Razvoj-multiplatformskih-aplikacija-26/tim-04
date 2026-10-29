import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';

extension AnimalsFilterLabel on AnimalsFilter {
  String get label => switch (this) {
    AnimalsFilter.all => 'Sve',
    AnimalsFilter.received => 'Primljene',
    AnimalsFilter.inQuarantine => 'U karantinu',
    AnimalsFilter.readyForAdoption => 'Spremne',
    AnimalsFilter.reserved => 'Rezervisane',
    AnimalsFilter.adopted => 'Udomljene',
    AnimalsFilter.permanentResident => 'Trajni štićenici',
    AnimalsFilter.returned => 'Vraćene',
  };
}

class AnimalsFilterBar extends StatelessWidget {
  const AnimalsFilterBar({super.key, required this.selected, required this.onSelected});

  final AnimalsFilter selected;
  final ValueChanged<AnimalsFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: AnimalsFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = AnimalsFilter.values[index];
          return ChoiceChip(
            label: Text(filter.label),
            selected: filter == selected,
            onSelected: (_) => onSelected(filter),
          );
        },
      ),
    );
  }
}
