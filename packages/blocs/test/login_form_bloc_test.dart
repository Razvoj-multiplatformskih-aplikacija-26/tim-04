import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'fake_sessions.dart';

void main() {
  const ana = User(id: UserId('u-ana'), name: 'Ana Petrović', role: Role.adopter);

  late FakeSessions sessions;

  setUp(() => sessions = FakeSessions(accounts: {'udomitelj1': ('utociste-demo', ana)}));

  LoginFormBloc build() => LoginFormBloc(logIn: LogIn(sessions: sessions));

  test('starts idle', () => expect(build().state, const LoginIdle()));

  blocTest<LoginFormBloc, LoginFormState>(
    'the right username and password succeed',
    build: build,
    act: (bloc) => bloc.add(const LoginSubmitted(username: 'udomitelj1', password: 'utociste-demo')),
    expect: () => [const LoginSubmitting(), const LoginSucceeded(ana)],
  );

  blocTest<LoginFormBloc, LoginFormState>(
    'a wrong password is rejected',
    build: build,
    act: (bloc) => bloc.add(const LoginSubmitted(username: 'udomitelj1', password: 'pogresna')),
    expect: () => [const LoginSubmitting(), const LoginRejected()],
  );

  blocTest<LoginFormBloc, LoginFormState>(
    'an unknown username is rejected the same way, so it does not reveal which accounts exist',
    build: build,
    act: (bloc) => bloc.add(const LoginSubmitted(username: 'nepostojeci', password: 'utociste-demo')),
    expect: () => [const LoginSubmitting(), const LoginRejected()],
  );

  blocTest<LoginFormBloc, LoginFormState>(
    'spaces around the username do not matter',
    build: build,
    act: (bloc) => bloc.add(const LoginSubmitted(username: '  udomitelj1 ', password: 'utociste-demo')),
    expect: () => [const LoginSubmitting(), const LoginSucceeded(ana)],
  );

  blocTest<LoginFormBloc, LoginFormState>(
    'without a connection it fails with the cause instead of saying the password is wrong',
    setUp: () => sessions.offline = true,
    build: build,
    act: (bloc) => bloc.add(const LoginSubmitted(username: 'udomitelj1', password: 'utociste-demo')),
    expect: () => [
      const LoginSubmitting(),
      isA<LoginFailed>().having(
        (state) => (state.cause as RepositoryException).failure,
        'failure',
        RepositoryFailure.unreachable,
      ),
    ],
  );

  blocTest<LoginFormBloc, LoginFormState>(
    'after a wrong password a second try can still succeed',
    build: build,
    act: (bloc) async {
      bloc.add(const LoginSubmitted(username: 'udomitelj1', password: 'pogresna'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const LoginSubmitted(username: 'udomitelj1', password: 'utociste-demo'));
    },
    expect: () => [const LoginSubmitting(), const LoginRejected(), const LoginSubmitting(), const LoginSucceeded(ana)],
  );
}
