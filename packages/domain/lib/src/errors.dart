import 'package:meta/meta.dart';

import 'animal/animal_status.dart';

sealed class DomainError {
  const DomainError();
}

@immutable
final class NameTooShort extends DomainError {
  const NameTooShort({required this.min});

  final int min;

  @override
  bool operator ==(Object other) => other is NameTooShort && other.min == min;

  @override
  int get hashCode => Object.hash(NameTooShort, min);

  @override
  String toString() => 'NameTooShort(min: $min)';
}

@immutable
final class NameTooLong extends DomainError {
  const NameTooLong({required this.max});

  final int max;

  @override
  bool operator ==(Object other) => other is NameTooLong && other.max == max;

  @override
  int get hashCode => Object.hash(NameTooLong, max);

  @override
  String toString() => 'NameTooLong(max: $max)';
}

@immutable
final class MotivationTooShort extends DomainError {
  const MotivationTooShort(this.length, {required this.min});

  final int length;
  final int min;

  @override
  bool operator ==(Object other) => other is MotivationTooShort && other.length == length && other.min == min;

  @override
  int get hashCode => Object.hash(MotivationTooShort, length, min);

  @override
  String toString() => 'MotivationTooShort($length, min: $min)';
}

@immutable
final class MotivationTooLong extends DomainError {
  const MotivationTooLong({required this.max});

  final int max;

  @override
  bool operator ==(Object other) => other is MotivationTooLong && other.max == max;

  @override
  int get hashCode => Object.hash(MotivationTooLong, max);

  @override
  String toString() => 'MotivationTooLong(max: $max)';
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

@immutable
final class TooManyActiveRequests extends DomainError {
  const TooManyActiveRequests({required this.max});

  final int max;

  @override
  bool operator ==(Object other) => other is TooManyActiveRequests && other.max == max;

  @override
  int get hashCode => Object.hash(TooManyActiveRequests, max);

  @override
  String toString() => 'TooManyActiveRequests(max: $max)';
}

final class AnimalNotAdoptable extends DomainError {
  const AnimalNotAdoptable();
}

final class DuplicateRequest extends DomainError {
  const DuplicateRequest();
}

final class WithdrawNotAllowed extends DomainError {
  const WithdrawNotAllowed();
}

final class InvalidRequestTransition extends DomainError {
  const InvalidRequestTransition();
}
