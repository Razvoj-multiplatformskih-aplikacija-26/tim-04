import 'package:meta/meta.dart';

import 'identifiers.dart';

enum Role {
  adopter,
  volunteer,
  seniorVolunteer,
  veterinarian,
  coordinator;

  bool get isStaff => this != Role.adopter;
}

@immutable
final class User {
  const User({required this.id, required this.username, required this.role});

  final UserId id;
  final String username;
  final Role role;

  @override
  bool operator ==(Object other) => other is User && other.id == id && other.username == username && other.role == role;

  @override
  int get hashCode => Object.hash(id, username, role);

  @override
  String toString() => 'User($username, ${role.name})';
}
