import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'fake_sessions.dart';

void main() {
  const ana = User(id: UserId('u-ana'), name: 'Ana Petrović', role: Role.adopter);
  const dragana = User(id: UserId('u-coordinator'), name: 'Dragana Ilić', role: Role.coordinator);

  late FakeSessions sessions;

  SessionBloc blocFor(bool Function(User) admits) => SessionBloc(
    restoreSession: RestoreSession(sessions: sessions),
    logOut: LogOut(sessions: sessions),
    admits: admits,
    expirations: sessions.expirations,
  );

  blocTest<SessionBloc, SessionState>(
    'starts unknown until it has asked about a remembered session',
    setUp: () => sessions = FakeSessions(),
    build: () => blocFor(AccessPolicy.canUseMobileApp),
    verify: (bloc) => expect(bloc.state, const SessionUnknown()),
  );

  blocTest<SessionBloc, SessionState>(
    'a remembered adopter goes straight into the mobile app',
    setUp: () => sessions = FakeSessions(remembered: ana),
    build: () => blocFor(AccessPolicy.canUseMobileApp),
    act: (bloc) => bloc.add(const SessionRestoreRequested()),
    expect: () => [const SignedIn(ana)],
  );

  blocTest<SessionBloc, SessionState>(
    'without a remembered session the login screen opens without a reason',
    setUp: () => sessions = FakeSessions(),
    build: () => blocFor(AccessPolicy.canUseMobileApp),
    act: (bloc) => bloc.add(const SessionRestoreRequested()),
    expect: () => [const SignedOut()],
  );

  blocTest<SessionBloc, SessionState>(
    'without a connection at start the reason says so',
    setUp: () => sessions = FakeSessions(remembered: ana, offline: true),
    build: () => blocFor(AccessPolicy.canUseMobileApp),
    act: (bloc) => bloc.add(const SessionRestoreRequested()),
    expect: () => [const SignedOut(reason: SignOutReason.unreachable)],
  );

  blocTest<SessionBloc, SessionState>(
    'an adopter cannot enter the backoffice and is signed out on the server too',
    setUp: () => sessions = FakeSessions(remembered: ana),
    build: () => blocFor(AccessPolicy.canUseBackoffice),
    act: (bloc) => bloc.add(const SessionRestoreRequested()),
    expect: () => [const SignedOut(reason: SignOutReason.roleNotAllowed)],
    verify: (_) {
      expect(sessions.logOuts, 1);
      expect(sessions.remembered, isNull);
    },
  );

  blocTest<SessionBloc, SessionState>(
    'staff cannot enter the mobile app',
    setUp: () => sessions = FakeSessions(),
    build: () => blocFor(AccessPolicy.canUseMobileApp),
    act: (bloc) => bloc.add(const SessionStarted(dragana)),
    expect: () => [const SignedOut(reason: SignOutReason.roleNotAllowed)],
  );

  blocTest<SessionBloc, SessionState>(
    'a coordinator who has just logged in enters the backoffice',
    setUp: () => sessions = FakeSessions(),
    build: () => blocFor(AccessPolicy.canUseBackoffice),
    act: (bloc) => bloc.add(const SessionStarted(dragana)),
    expect: () => [const SignedIn(dragana)],
  );

  blocTest<SessionBloc, SessionState>(
    'logging out ends the session with that reason',
    setUp: () => sessions = FakeSessions(remembered: ana),
    build: () => blocFor(AccessPolicy.canUseMobileApp),
    act: (bloc) async {
      bloc.add(const SessionRestoreRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const SessionLogOutRequested());
    },
    expect: () => [const SignedIn(ana), const SignedOut(reason: SignOutReason.loggedOut)],
    verify: (_) => expect(sessions.logOuts, 1),
  );

  blocTest<SessionBloc, SessionState>(
    'when the server says the session expired, the user is sent back with that reason',
    setUp: () => sessions = FakeSessions(remembered: ana),
    build: () => blocFor(AccessPolicy.canUseMobileApp),
    act: (bloc) async {
      bloc.add(const SessionRestoreRequested());
      await Future<void>.delayed(Duration.zero);
      sessions.expire();
    },
    expect: () => [const SignedIn(ana), const SignedOut(reason: SignOutReason.expired)],
  );

  blocTest<SessionBloc, SessionState>(
    'an expiry announced while nobody is signed in changes nothing',
    setUp: () => sessions = FakeSessions(),
    build: () => blocFor(AccessPolicy.canUseMobileApp),
    act: (bloc) async {
      bloc.add(const SessionRestoreRequested());
      await Future<void>.delayed(Duration.zero);
      sessions.expire();
    },
    expect: () => [const SignedOut()],
  );
}
