import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

/// The animal's photo from `packages/ui/assets/animals/`, or a rose circle with the species icon when there is none.
class AnimalPhoto extends StatelessWidget {
  const AnimalPhoto({super.key, required this.animal, this.size = 48});

  final Animal animal;
  final double size;

  @override
  Widget build(BuildContext context) {
    final photo = animal.photoUrl;
    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: photo == null
            ? _Placeholder(species: animal.species, size: size)
            : Image.asset(
                photo,
                package: 'ui',
                fit: BoxFit.cover,
                semanticLabel: animal.name.text,
                errorBuilder: (_, _, _) => _Placeholder(species: animal.species, size: size),
              ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.species, required this.size});

  final Species species;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.tertiaryContainer,
      child: Icon(_icon, size: size * 0.5, color: scheme.onTertiaryContainer),
    );
  }

  IconData get _icon => switch (species) {
    Species.dog || Species.horse => Icons.pets,
    Species.cow || Species.goat => Icons.grass,
  };
}
