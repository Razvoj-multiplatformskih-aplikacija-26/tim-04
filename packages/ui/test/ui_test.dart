import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';
import 'package:intl/date_symbol_data_local.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: UtocisteTheme.light(),
  home: Scaffold(body: child),
);

void main() {
  setUpAll(() => initializeDateFormatting(serbianLatin));
  test('ages use Serbian plural forms', () {
    expect(ageLabel(5), '5 meseci');
    expect(ageLabel(12), '1 godina');
    expect(ageLabel(26), '2 godine i 2 meseca');
    expect(ageLabel(61), '5 godina i 1 mesec');
    expect(ageLabel(21 * 12), '21 godina');
  });

  test('dates are written out in Serbian', () {
    expect(formatLongDate(DateTime(2026, 8, 3)), '3. avgust 2026.');
  });
  test('statuses, species and request statuses have Serbian labels', () {
    expect(const PermanentResident(reason: 'Starost').label, 'Stalni stanar');
    expect(Species.cow.label, 'Krava');
    expect(AdoptionRequestStatus.pending.label, 'Na čekanju');
  });

  test('domain errors become Serbian messages', () {
    expect(const MotivationTooShort(12, min: 20).message, contains('sada ima 12'));
    expect(const TooManyActiveRequests(max: 2).message, 'Možete imati najviše 2 aktivna zahteva.');
    expect(const TooManyActiveRequests(max: 3).message, 'Možete imati najviše 3 aktivna zahteva.');
  });

  test('both themes build', () {
    expect(UtocisteTheme.light().colorScheme.primary, Flora.leafDeep);
    expect(UtocisteTheme.dark().brightness, Brightness.dark);
  });

  testWidgets('StatusBadge shows the label', (tester) async {
    await tester.pumpWidget(_wrap(StatusBadge(status: ReadyForAdoption(since: DateTime(2026, 8, 20)))));

    expect(find.text('Spremna za udomljavanje'), findsOneWidget);
  });

  testWidgets('StatusBadge can show the short label', (tester) async {
    await tester.pumpWidget(_wrap(StatusBadge(status: ReadyForAdoption(since: DateTime(2026, 8, 20)), short: true)));

    expect(find.text('Spremna'), findsOneWidget);
    expect(find.text('Spremna za udomljavanje'), findsNothing);
  });

  testWidgets('RequestStatusChip shows the request status label', (tester) async {
    await tester.pumpWidget(_wrap(const RequestStatusChip(status: AdoptionRequestStatus.withdrawn)));

    expect(find.text('Povučen'), findsOneWidget);
  });

  testWidgets('AnimalPhoto shows the photo, or a placeholder without one', (tester) async {
    Animal bela({String? photo}) => Animal(
      id: const AnimalId('a-04'),
      name: AnimalName.parse('Bela').valueOrNull!,
      species: Species.cow,
      birthDate: DateTime(2023, 6, 2),
      description: 'Mirna krava.',
      enclosureId: const EnclosureId('S-1'),
      status: ReadyForAdoption(since: DateTime(2026, 7, 1)),
      receivedAt: DateTime(2026, 6, 10),
      photoUrl: photo,
    );

    await tester.pumpWidget(_wrap(AnimalPhoto(animal: bela(photo: 'assets/animals/cute_cow.jpg'))));
    expect(find.byType(Image), findsOneWidget);

    await tester.pumpWidget(_wrap(AnimalPhoto(animal: bela())));
    expect(find.byIcon(Icons.grass), findsOneWidget);
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
