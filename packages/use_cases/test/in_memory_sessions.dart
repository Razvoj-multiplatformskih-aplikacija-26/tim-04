import 'dart:async';

import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

final class InMemorySessions implements SessionRepository {
  InMemorySessions(this._accounts, {User? signedIn}) : _current = signedIn;

  final Map<String, (String, User)> _accounts;
  final _expirations = StreamController<void>.broadcast();
  User? _current;
  final logIns = <({String username, String password})>[];

  @override
  Future<User?> logIn({required String username, required String password}) async {
    logIns.add((username: username, password: password));
    final account = _accounts[username];
    if (account == null || account.$1 != password) return null;
    return _current = account.$2;
  }

  @override
  Future<User?> current() async => _current;

  @override
  Future<void> logOut() async => _current = null;

  @override
  Stream<void> get expirations => _expirations.stream;

  void expire() {
    _current = null;
    _expirations.add(null);
  }
}

final class UnreachableSessions implements SessionRepository {
  static const _offline = RepositoryException('no connection', failure: RepositoryFailure.unreachable);

  @override
  Future<User?> logIn({required String username, required String password}) async => throw _offline;

  @override
  Future<User?> current() async => throw _offline;

  @override
  Future<void> logOut() async {}

  @override
  Stream<void> get expirations => const Stream.empty();
}
