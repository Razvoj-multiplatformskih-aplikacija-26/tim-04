import 'dart:async';

import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'seed.dart';

final class FakeSessions implements SessionRepository {
  FakeSessions({User? signedIn}) : _current = signedIn;

  static const password = 'utociste-demo';

  static const accounts = {
    'udomitelj1': ana,
    'udomitelj2': marko,
    'volonter1': volunteer,
    'stariji1': seniorVolunteer,
    'veterinar1': veterinarian,
    'koordinator1': coordinator,
  };

  User? _current;
  final _expirations = StreamController<void>.broadcast();

  void expire() {
    _current = null;
    _expirations.add(null);
  }

  @override
  Future<User?> logIn({required String username, required String password}) async =>
      password == FakeSessions.password ? _current = accounts[username] : null;

  @override
  Future<User?> current() async => _current;

  @override
  Future<void> logOut() async => _current = null;

  @override
  Stream<void> get expirations => _expirations.stream;
}
