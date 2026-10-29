import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: UtocisteTheme.light(),
  home: Scaffold(body: child),
);

void main() {
  test('statuses, species and request statuses have Serbian labels', () {
    expect(const PermanentResident(reason: 'Starost').label, 'Stalni stanar');
    expect(Species.cow.label, 'Krava');
    expect(AdoptionRequestStatus.pending.label, 'Na čekanju');
  });

  test('domain errors become Serbian messages', () {
    expect(const MotivationTooShort(12).message, contains('sada ima 12'));
    expect(const TooManyActiveRequests().message, 'Možete imati najviše 2 aktivna zahteva.');
  });

  test('both themes build', () {
    expect(UtocisteTheme.light().colorScheme.primary, Flora.leafDeep);
    expect(UtocisteTheme.dark().brightness, Brightness.dark);
  });

  testWidgets('StatusBadge shows the label', (tester) async {
    await tester.pumpWidget(_wrap(StatusBadge(status: ReadyForAdoption(since: DateTime(2026, 8, 20)))));

    expect(find.text('Spremna za udomljavanje'), findsOneWidget);
  });

  testWidgets('FailureView calls onRetry', (tester) async {
    var retried = 0;
    await tester.pumpWidget(_wrap(FailureView(onRetry: () => retried++)));

    await tester.tap(find.text('Pokušaj ponovo'));

    expect(retried, 1);
  });

  testWidgets('EmptyView shows its message', (tester) async {
    await tester.pumpWidget(_wrap(const EmptyView(message: 'Nema životinja.')));

    expect(find.text('Nema životinja.'), findsOneWidget);
  });
}
