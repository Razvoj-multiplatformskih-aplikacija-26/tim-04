import 'dart:async';

import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

final class FakeSessions implements SessionRepository {
  FakeSessions({this.accounts = const {}, this.remembered, this.offline = false});

  final Map<String, (String, User)> accounts;
  User? remembered;
  bool offline;
  int logOuts = 0;
  final _expirations = StreamController<void>.broadcast();

  void expire() => _expirations.add(null);

  @override
  Future<User?> logIn({required String username, required String password}) async {
    if (offline) throw const RepositoryException('offline', failure: RepositoryFailure.unreachable);
    final account = accounts[username];
    return account != null && account.$1 == password ? remembered = account.$2 : null;
  }

  @override
  Future<User?> current() async {
    if (offline) throw const RepositoryException('offline', failure: RepositoryFailure.unreachable);
    return remembered;
  }

  @override
  Future<void> logOut() async {
    logOuts++;
    remembered = null;
  }

  @override
  Stream<void> get expirations => _expirations.stream;
}
