import 'package:backoffice/app.dart';
import 'package:backoffice/data/fake_shelter_repository.dart';
import 'package:backoffice/data/seed.dart';
import 'package:backoffice/dependencies.dart';
import 'package:backoffice/screens/animals/animal_details.dart';
import 'package:backoffice/screens/animals/animals_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _wide = Size(1400, 900);
const _narrow = Size(600, 900);

BackofficeDependencies _dependencies(FakeShelterRepository repository) => BackofficeDependencies(
  repository: repository,
  user: coordinator,
  clock: () => DateTime(2026, 10, 29, 10),
  newId: () => 'r-test',
  users: seedUsers,
  fakeRepository: repository,
);

Future<FakeShelterRepository> _start(
  WidgetTester tester, {
  FakeShelterRepository? repository,
  String location = '/animals',
  Size size = _wide,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = repository ?? FakeShelterRepository(latency: const Duration(milliseconds: 10));
  await tester.pumpWidget(BackofficeApp(dependencies: _dependencies(repo), initialLocation: location));
  return repo;
}

AnimalsTableRow _rowOf(WidgetTester tester, String name) =>
    tester.widget<AnimalsTableRow>(find.widgetWithText(AnimalsTableRow, name));

String _location(WidgetTester tester) {
  final context = tester.element(find.byType(Scaffold).first);
  return GoRouter.of(context).state.uri.toString();
}

const _rexDescription = 'Miran i druželjubiv pas srednje veličine, voli šetnje i decu.';

void main() {
  group('states', () {
    testWidgets('shows a spinner first, then the animals from the seed', (tester) async {
      await _start(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Rex'), findsOneWidget);
      expect(find.text('Spremna za udomljavanje'), findsWidgets);
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
  });

  group('filter', () {
    testWidgets('the "Spremne" chip keeps only animals ready for adoption', (tester) async {
      await _start(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Spremne'));
      await tester.pumpAndSettle();

      expect(find.text('Rex'), findsOneWidget);
      expect(find.text('Luna'), findsOneWidget);
      expect(find.text('Grom'), findsNothing);
      expect(find.text('Žućko'), findsNothing);
      expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Spremne')).selected, isTrue);
    });
  });

  group('wide: table and details panel', () {
    testWidgets('without a selection the panel asks to pick an animal', (tester) async {
      await _start(tester);
      await tester.pumpAndSettle();

      expect(find.byType(AnimalsTable), findsOneWidget);
      expect(find.text('Izaberite životinju iz tabele da vidite detalje.'), findsOneWidget);
    });

    testWidgets('tapping an animal selects it, puts it in the address and fills the panel', (tester) async {
      await _start(tester);
      await tester.pumpAndSettle();

      expect(_rowOf(tester, 'Rex').selected, isFalse);

      await tester.tap(find.text('Rex'));
      await tester.pumpAndSettle();

      expect(_rowOf(tester, 'Rex').selected, isTrue);
      expect(_rowOf(tester, 'Luna').selected, isFalse);
      expect(_location(tester), '/animals?selected=a-01');
      expect(find.text(_rexDescription), findsOneWidget);
    });

    testWidgets('the panel lists the requests for the selected animal with applicant names', (tester) async {
      await _start(tester, location: '/animals?selected=a-01');
      await tester.pumpAndSettle();

      final panel = find.descendant(of: find.byType(AnimalDetails), matching: find.byType(Scrollable));
      await tester.scrollUntilVisible(find.text('Marko Jovanović'), 200, scrollable: panel);

      expect(find.text('Zahtevi za udomljavanje (3)'), findsOneWidget);
      expect(find.text('Marko Jovanović'), findsOneWidget);
      expect(find.text('Jelena Nikolić'), findsOneWidget);
      expect(find.text('Ana Petrović'), findsNothing);
    });

    testWidgets('opening a link with ?selected= selects that animal', (tester) async {
      await _start(tester, location: '/animals?selected=a-02');
      await tester.pumpAndSettle();

      expect(_rowOf(tester, 'Luna').selected, isTrue);
      expect(_rowOf(tester, 'Rex').selected, isFalse);
    });

    testWidgets('tapping the selected animal again clears the selection', (tester) async {
      await _start(tester, location: '/animals?selected=a-01');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(AnimalsTableRow, 'Rex'));
      await tester.pumpAndSettle();

      expect(_rowOf(tester, 'Rex').selected, isFalse);
      expect(_location(tester), '/animals');
    });

    testWidgets('the close button on the panel clears the selection', (tester) async {
      await _start(tester, location: '/animals?selected=a-01');
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Zatvori detalje'));
      await tester.pumpAndSettle();

      expect(find.text(_rexDescription), findsNothing);
      expect(_location(tester), '/animals');
    });
  });

  group('narrow: list and full-screen details', () {
    testWidgets('a tap opens the details and back returns to the list', (tester) async {
      await _start(tester, size: _narrow);
      await tester.pumpAndSettle();

      expect(find.byType(AnimalsTable), findsNothing);

      await tester.tap(find.text('Rex'));
      await tester.pumpAndSettle();

      expect(find.text(_rexDescription), findsOneWidget);
      expect(find.text('Luna'), findsNothing);
      expect(_location(tester), '/animals?selected=a-01');

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Luna'), findsOneWidget);
      expect(_location(tester), '/animals');
    });
  });

  testWidgets('the root address redirects to the animals list', (tester) async {
    await _start(tester, location: '/');
    await tester.pumpAndSettle();

    expect(find.text('Rex'), findsOneWidget);
    expect(_location(tester), '/animals');
  });
}
