import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/fake_shelter_repository.dart';

import 'support.dart';

void main() {
  setUpAll(initializeTestEnvironment);

  testWidgets('withdraws a request only after the dialog is confirmed', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(appWith(FakeShelterRepository(latency: Duration.zero)));
    await settle(tester);
    await openTab(tester, 'Moji zahtevi');

    await tester.tap(find.text('Luna'));
    await settle(tester);
    await tester.tap(find.text('Povuci zahtev'));
    await settle(tester);
    expect(find.text('Povući zahtev?'), findsOneWidget);

    await tester.tap(find.text('Odustani'));
    await settle(tester);
    expect(find.text('Na čekanju'), findsWidgets);

    await tester.tap(find.text('Povuci zahtev'));
    await settle(tester);
    await tester.tap(find.text('Povuci'));
    await settle(tester);
    expect(find.text('Zahtev je povučen.'), findsOneWidget);
    expect(find.text('Povučen'), findsWidgets);
    expect(find.text('Povuci zahtev'), findsNothing);
  });
}
