import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/fake_shelter_repository.dart';

import 'support.dart';

void main() {
  setUpAll(initializeTestEnvironment);

  const validMotivation = 'Imamo veliko dvorište i mnogo vremena za šetnje.';

  testWidgets('shows the P2 message for a motivation that is too short', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(appWith(FakeShelterRepository(latency: Duration.zero)));
    await settle(tester);
    await openRequestForm(tester, 'Rex');

    await tester.enterText(find.byType(TextFormField), 'Kratko');
    await settle(tester);
    expect(find.text('Motivacija mora imati bar ${RequestMotivation.minLength} znakova (sada ima 6).'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), validMotivation);
    await settle(tester);
    expect(find.textContaining('Motivacija mora imati bar'), findsNothing);
  });

  testWidgets('sends a request, then refuses one over the P3 limit', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(appWith(FakeShelterRepository(latency: Duration.zero)));
    await settle(tester);

    await openRequestForm(tester, 'Rex');
    await tester.enterText(find.byType(TextFormField), validMotivation);
    await tester.tap(find.text('Pošalji zahtev'));
    await settle(tester);
    expect(find.text('Zahtev je poslat. Čeka odluku koordinatora.'), findsOneWidget);
    expect(find.text('Rex'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await settle(tester);

    await openTab(tester, 'Životinje');
    await openRequestForm(tester, 'Mrvica');
    await tester.enterText(find.byType(TextFormField), validMotivation);
    await tester.tap(find.text('Pošalji zahtev'));
    await settle(tester);
    expect(find.text('Možete imati najviše $maxActiveRequests aktivna zahteva.'), findsOneWidget);
  });
}
