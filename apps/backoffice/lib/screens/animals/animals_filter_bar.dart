import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';

class AnimalsFilterBar extends StatelessWidget {
  const AnimalsFilterBar({super.key, required this.selected, required this.onChanged});

  final AnimalsFilter selected;
  final ValueChanged<AnimalsFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final filter in AnimalsFilter.values)
          ChoiceChip(
            label: Text(filterLabel(filter)),
            selected: filter == selected,
            onSelected: (_) => onChanged(filter),
          ),
      ],
    );
  }
}

String filterLabel(AnimalsFilter filter) => switch (filter) {
  AnimalsFilter.all => 'Sve',
  AnimalsFilter.received => 'Primljene',
  AnimalsFilter.inQuarantine => 'U karantinu',
  AnimalsFilter.readyForAdoption => 'Spremne',
  AnimalsFilter.reserved => 'Rezervisane',
  AnimalsFilter.adopted => 'Udomljene',
  AnimalsFilter.permanentResident => 'Stalni stanari',
  AnimalsFilter.returned => 'Vraćene',
};
