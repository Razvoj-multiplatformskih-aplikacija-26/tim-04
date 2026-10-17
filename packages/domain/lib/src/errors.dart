import 'package:meta/meta.dart';

sealed class DomainError {
  const DomainError();
}

// P1 – ime životinje
final class NameTooShort extends DomainError {
  const NameTooShort();
}

final class NameTooLong extends DomainError {
  const NameTooLong();
}

// P2 – motivacija
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
