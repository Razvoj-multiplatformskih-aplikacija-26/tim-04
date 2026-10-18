import 'package:meta/meta.dart';

import 'animal/animal_status.dart';

sealed class DomainError {
  const DomainError();
}

final class NameTooShort extends DomainError {
  const NameTooShort();
}

final class NameTooLong extends DomainError {
  const NameTooLong();
}

@immutable
final class MotivationTooShort extends DomainError {
  const MotivationTooShort(this.length);

  final int length;

  @override
  bool operator ==(Object other) => other is MotivationTooShort && other.length == length;

  @override
  int get hashCode => Object.hash(MotivationTooShort, length);

  @override
  String toString() => 'MotivationTooShort($length)';
}

final class MotivationTooLong extends DomainError {
  const MotivationTooLong();
}

final class NotAllowed extends DomainError {
  const NotAllowed();
}

final class NotFound extends DomainError {
  const NotFound();
}

@immutable
final class InvalidTransition extends DomainError {
  const InvalidTransition({required this.from, required this.to});

  final AnimalStatus from;
  final AnimalStatus to;

  @override
  bool operator ==(Object other) =>
      other is InvalidTransition &&
      other.from.runtimeType == from.runtimeType &&
      other.to.runtimeType == to.runtimeType;

  @override
  int get hashCode => Object.hash(InvalidTransition, from.runtimeType, to.runtimeType);

  @override
  String toString() => 'InvalidTransition(${from.runtimeType} -> ${to.runtimeType})';
}
