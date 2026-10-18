import 'package:meta/meta.dart';

import '../identifiers.dart';
import 'animal_name.dart';
import 'animal_status.dart';

enum Species { dog, cow, goat, horse }

@immutable
final class Animal {
  const Animal({
    required this.id,
    required this.name,
    required this.species,
    required this.birthDate,
    required this.description,
    required this.enclosureId,
    required this.status,
    required this.receivedAt,
    this.photoUrl,
  });

  final AnimalId id;
  final AnimalName name;
  final Species species;
  final DateTime birthDate;
  final String description;
  final EnclosureId enclosureId;
  final AnimalStatus status;
  final DateTime receivedAt;
  final String? photoUrl;

  bool get isAdoptable => status.isAdoptable;

  int ageInMonths(DateTime now) {
    final months = (now.year - birthDate.year) * 12 + now.month - birthDate.month;
    return now.day < birthDate.day ? months - 1 : months;
  }

  Animal copyWith({AnimalStatus? status, EnclosureId? enclosureId}) {
    return Animal(
      id: id,
      name: name,
      species: species,
      birthDate: birthDate,
      description: description,
      enclosureId: enclosureId ?? this.enclosureId,
      status: status ?? this.status,
      receivedAt: receivedAt,
      photoUrl: photoUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Animal &&
      other.id == id &&
      other.name == name &&
      other.species == species &&
      other.birthDate == birthDate &&
      other.description == description &&
      other.enclosureId == enclosureId &&
      other.status == status &&
      other.receivedAt == receivedAt &&
      other.photoUrl == photoUrl;

  @override
  int get hashCode => Object.hash(id, name, species, birthDate, description, enclosureId, status, receivedAt, photoUrl);

  @override
  String toString() => 'Animal($id, ${name.text}, ${species.name}, $status)';
}
