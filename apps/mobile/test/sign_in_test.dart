import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/fake_sessions.dart';
import 'package:mobile/data/fake_shelter_repository.dart';
import 'package:mobile/data/seed.dart';
import 'package:ui/ui.dart';

import 'support.dart';

void main() {
  setUpAll(initializeTestEnvironment);

  Future<FakeSessions> start(WidgetTester tester, {bool signedIn = false}) async {
    usePhoneSize(tester);
    final sessions = FakeSessions(signedIn: signedIn ? ana : null);
    await tester.pumpWidget(appWith(FakeShelterRepository(latency: Duration.zero), sessions: sessions));
    await settle(tester);
    return sessions;
  }

  Future<void> logIn(WidgetTester tester, String username) async {
    await tester.enterText(find.byType(TextField).at(0), username);
    await tester.enterText(find.byType(TextField).at(1), FakeSessions.password);
    await tester.tap(find.widgetWithText(FilledButton, 'Prijavi se'));
    await settle(tester);
  }

  testWidgets('without a session the app opens the login, and an adopter gets in', (tester) async {
    await start(tester);
    expect(find.byType(LoginScreen), findsOneWidget);

    await logIn(tester, 'udomitelj1');

    expect(find.byType(LoginScreen), findsNothing);
    expect(find.text('Životinje'), findsWidgets);
  });

  testWidgets('a remembered adopter skips the login', (tester) async {
    await start(tester, signedIn: true);

    expect(find.byType(LoginScreen), findsNothing);
    expect(find.text('Životinje'), findsWidgets);
  });

  testWidgets('staff are told to use the backoffice', (tester) async {
    await start(tester);

    await logIn(tester, 'koordinator1');

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Aplikacija je za udomitelje. Osoblje koristi backoffice.'), findsOneWidget);
  });

  testWidgets('logging out returns to the login', (tester) async {
    await start(tester, signedIn: true);

    await tester.tap(find.byTooltip('Odjavi se'));
    await settle(tester);

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('an expired session returns to the login and says why', (tester) async {
    final sessions = await start(tester, signedIn: true);

    sessions.expire();
    await settle(tester);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text(sessionExpiredMessage), findsOneWidget);
  });
}
