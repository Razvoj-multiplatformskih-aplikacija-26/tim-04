import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

/// The animal's photo from `packages/ui/assets/animals/`, or a rose tile with the species icon when there is none.
///
/// The default is a small circle for lists; [AnimalPhoto.banner] is a 4:3 rounded picture for the details panel.
class AnimalPhoto extends StatelessWidget {
  const AnimalPhoto({super.key, required this.animal, this.size = 48}) : _banner = false;

  const AnimalPhoto.banner({super.key, required this.animal}) : size = 0, _banner = true;

  final Animal animal;

  /// Diameter of the circle; the banner takes the full width instead.
  final double size;
  final bool _banner;

  @override
  Widget build(BuildContext context) {
    final photo = animal.photoUrl;
    final placeholder = _Placeholder(species: animal.species, iconSize: _banner ? 72 : size * 0.5);
    final picture = photo == null
        ? placeholder
        : Image.asset(
            photo,
            package: 'ui',
            fit: BoxFit.cover,
            // When the photo is cropped, keep the top: that is where the heads usually are.
            alignment: const Alignment(0, -0.6),
            semanticLabel: animal.name.text,
            errorBuilder: (_, _, _) => placeholder,
          );
    if (_banner) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(aspectRatio: 4 / 3, child: picture),
      );
    }
    return ClipOval(
      child: SizedBox.square(dimension: size, child: picture),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.species, required this.iconSize});

  final Species species;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.tertiaryContainer,
      child: Center(
        child: Icon(_icon, size: iconSize, color: scheme.onTertiaryContainer),
      ),
    );
  }

  IconData get _icon => switch (species) {
    Species.dog || Species.horse => Icons.pets,
    Species.cow || Species.goat => Icons.grass,
  };
}
