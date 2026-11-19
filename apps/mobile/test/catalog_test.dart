import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/fake_shelter_repository.dart';
import 'package:mobile/widgets/animal_card.dart';
import 'package:ui/ui.dart';

import 'support.dart';

void main() {
  setUpAll(initializeTestEnvironment);

  testWidgets('shows loading, failure, data and empty', (tester) async {
    usePhoneSize(tester);
    final repository = FakeShelterRepository(latency: const Duration(seconds: 1))..failNextRequest();

    await tester.pumpWidget(appWith(repository));
    await tester.pump();
    expect(find.byType(LoadingView), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Nema veze sa serverom.'), findsOneWidget);

    await tester.tap(find.text('Pokušaj ponovo'));
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
    expect(find.byType(AnimalCard), findsNWidgets(4));

    await tester.tap(find.byTooltip('Simuliraj prazan odgovor'));
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
    expect(find.text('Nema životinja u ovom prikazu.'), findsOneWidget);
  });
}
