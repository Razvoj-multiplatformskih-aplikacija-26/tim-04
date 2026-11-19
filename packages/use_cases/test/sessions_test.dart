import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'in_memory_sessions.dart';

void main() {
  const ana = User(id: UserId('u-ana'), name: 'Ana Petrović', role: Role.adopter);
  const dragana = User(id: UserId('u-coordinator'), name: 'Dragana Ilić', role: Role.coordinator);

  InMemorySessions sessions({User? signedIn}) => InMemorySessions({
    'udomitelj1': ('utociste-demo', ana),
    'koordinator1': ('utociste-demo', dragana),
  }, signedIn: signedIn);

  group('LogIn', () {
    test('the right username and password sign the user in', () async {
      final repository = sessions();

      expect(await LogIn(sessions: repository)(username: 'udomitelj1', password: 'utociste-demo'), ana);
      expect(await repository.current(), ana);
    });

    test('a wrong password signs nobody in', () async {
      final repository = sessions();

      expect(await LogIn(sessions: repository)(username: 'udomitelj1', password: 'pogresna'), isNull);
      expect(await repository.current(), isNull);
    });

    test('spaces around the username are ignored, the password is sent as typed', () async {
      final repository = sessions();

      final user = await LogIn(sessions: repository)(username: '  koordinator1 ', password: 'utociste-demo');

      expect(user, dragana);
      expect(repository.logIns.single, (username: 'koordinator1', password: 'utociste-demo'));
    });

    test('a missing connection is reported, not mistaken for a wrong password', () {
      expect(
        LogIn(sessions: UnreachableSessions())(username: 'udomitelj1', password: 'utociste-demo'),
        throwsA(isA<RepositoryException>().having((e) => e.failure, 'failure', RepositoryFailure.unreachable)),
      );
    });
  });

  group('RestoreSession', () {
    test('returns the user who is still signed in', () async {
      expect(await RestoreSession(sessions: sessions(signedIn: ana))(), ana);
    });

    test('returns nobody when there is no session', () async {
      expect(await RestoreSession(sessions: sessions())(), isNull);
    });
  });

  group('LogOut', () {
    test('ends the session', () async {
      final repository = sessions(signedIn: dragana);

      await LogOut(sessions: repository)();

      expect(await RestoreSession(sessions: repository)(), isNull);
    });
  });

  test('an expired session is announced and nobody stays signed in', () async {
    final repository = sessions(signedIn: ana);
    final announced = repository.expirations.first;

    repository.expire();

    await announced;
    expect(await RestoreSession(sessions: repository)(), isNull);
  });
}
