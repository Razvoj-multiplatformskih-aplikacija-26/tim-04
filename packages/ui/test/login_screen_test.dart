import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

const _ana = User(id: UserId('u-ana'), name: 'Ana Petrović', role: Role.adopter);
const _roleNotAllowed = 'Aplikacija je za udomitelje. Osoblje koristi backoffice.';

final class _Sessions implements SessionRepository {
  _Sessions({this.offline = false});

  final bool offline;

  @override
  Future<User?> logIn({required String username, required String password}) async {
    if (offline) throw const RepositoryException('offline', failure: RepositoryFailure.unreachable);
    return username == 'udomitelj1' && password == 'utociste-demo' ? _ana : null;
  }

  @override
  Future<User?> current() async => null;

  @override
  Future<void> logOut() async {}

  @override
  Stream<void> get expirations => const Stream.empty();
}

void main() {
  late List<User> signedIn;

  setUp(() => signedIn = []);

  Future<void> open(WidgetTester tester, {bool offline = false, SignOutReason? reason}) => tester.pumpWidget(
    MaterialApp(
      theme: UtocisteTheme.light(),
      home: LoginScreen(
        title: 'Prijava',
        logIn: LogIn(sessions: _Sessions(offline: offline)),
        onSignedIn: signedIn.add,
        roleNotAllowedMessage: _roleNotAllowed,
        reason: reason,
      ),
    ),
  );

  Future<void> fillIn(WidgetTester tester, String username, String password) async {
    await tester.enterText(find.byType(TextField).at(0), username);
    await tester.enterText(find.byType(TextField).at(1), password);
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Prijavi se'));
    await tester.pumpAndSettle();
  }

  testWidgets('the right username and password sign the user in', (tester) async {
    await open(tester);

    await fillIn(tester, 'udomitelj1', 'utociste-demo');
    await submit(tester);

    expect(signedIn, [_ana]);
  });

  testWidgets('a wrong password says so and signs nobody in', (tester) async {
    await open(tester);

    await fillIn(tester, 'udomitelj1', 'pogresna');
    await submit(tester);

    expect(find.text('Pogrešno korisničko ime ili lozinka.'), findsOneWidget);
    expect(signedIn, isEmpty);
  });

  testWidgets('without a connection it says the server cannot be reached', (tester) async {
    await open(tester, offline: true);

    await fillIn(tester, 'udomitelj1', 'utociste-demo');
    await submit(tester);

    expect(find.text(serverUnreachableMessage), findsOneWidget);
    expect(signedIn, isEmpty);
  });

  testWidgets('an expired session is explained as soon as the screen opens', (tester) async {
    await open(tester, reason: SignOutReason.expired);

    expect(find.text(sessionExpiredMessage), findsOneWidget);
  });

  testWidgets('the wrong role shows the message the app chose', (tester) async {
    await open(tester, reason: SignOutReason.roleNotAllowed);

    expect(find.text(_roleNotAllowed), findsOneWidget);
  });

  testWidgets('after logging out the screen shows no message', (tester) async {
    await open(tester, reason: SignOutReason.loggedOut);

    expect(find.textContaining('Prijavite se ponovo'), findsNothing);
    expect(find.text(_roleNotAllowed), findsNothing);
  });

  testWidgets('Enter in the password field signs in like the button', (tester) async {
    await open(tester);

    await fillIn(tester, 'udomitelj1', 'utociste-demo');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(signedIn, [_ana]);
  });

  testWidgets('the password is hidden while typing', (tester) async {
    await open(tester);

    final password = tester.widget<TextField>(find.byType(TextField).at(1));

    expect(password.obscureText, isTrue);
  });
}
