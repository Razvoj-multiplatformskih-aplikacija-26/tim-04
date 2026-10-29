import 'package:backoffice/app.dart';
import 'package:backoffice/data/fake_shelter_repository.dart';
import 'package:backoffice/data/seed.dart';
import 'package:backoffice/dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

BackofficeDependencies _dependencies(FakeShelterRepository repository) => BackofficeDependencies(
  repository: repository,
  user: coordinator,
  clock: () => DateTime(2026, 10, 29, 10),
  newId: () => 'r-test',
  fakeRepository: repository,
);

Future<FakeShelterRepository> _start(WidgetTester tester, {FakeShelterRepository? repository}) async {
  final repo = repository ?? FakeShelterRepository(latency: const Duration(milliseconds: 10));
  await tester.pumpWidget(BackofficeApp(dependencies: _dependencies(repo)));
  return repo;
}

void main() {
  testWidgets('shows a spinner first, then the animals from the seed', (tester) async {
    await _start(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Rex'), findsOneWidget);
    expect(find.text('Pas · Spremna za udomljavanje'), findsWidgets);
  });

  testWidgets('shows an error with a retry button when loading fails', (tester) async {
    final repo = FakeShelterRepository(latency: const Duration(milliseconds: 10))..failNextRequest();
    await _start(tester, repository: repo);
    await tester.pumpAndSettle();

    expect(find.text('Učitavanje nije uspelo.'), findsOneWidget);
    expect(find.text('Rex'), findsNothing);

    await tester.tap(find.text('Pokušaj ponovo'));
    await tester.pumpAndSettle();

    expect(find.text('Učitavanje nije uspelo.'), findsNothing);
    expect(find.text('Rex'), findsOneWidget);
  });

  testWidgets('shows the empty state when there are no animals', (tester) async {
    await _start(
      tester,
      repository: FakeShelterRepository(latency: const Duration(milliseconds: 10), animals: []),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nema životinja za filter „Sve“.'), findsOneWidget);
  });

  testWidgets('"Simuliraj grešku" makes the next load fail', (tester) async {
    await _start(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Simuliraj grešku'));
    await tester.pumpAndSettle();

    expect(find.text('Učitavanje nije uspelo.'), findsOneWidget);
  });

  testWidgets('the filter menu keeps only animals ready for adoption', (tester) async {
    await _start(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Filter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spremne'));
    await tester.pumpAndSettle();

    expect(find.text('Rex'), findsOneWidget);
    expect(find.text('Luna'), findsOneWidget);
    expect(find.text('Grom'), findsNothing);
    expect(find.text('Žućko'), findsNothing);
  });

  testWidgets('tapping an animal selects it', (tester) async {
    await _start(tester);
    await tester.pumpAndSettle();

    ListTile tileOf(String name) => tester.widget<ListTile>(find.widgetWithText(ListTile, name));

    expect(tileOf('Rex').selected, isFalse);

    await tester.tap(find.text('Rex'));
    await tester.pumpAndSettle();

    expect(tileOf('Rex').selected, isTrue);
    expect(tileOf('Luna').selected, isFalse);
  });
}
