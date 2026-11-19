import 'package:backoffice/app.dart';
import 'package:backoffice/data/fake_shelter_repository.dart';
import 'package:backoffice/data/seed.dart';
import 'package:backoffice/dependencies.dart';
import 'package:backoffice/screens/animals/animal_details.dart';
import 'package:backoffice/screens/animals/animals_table.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:use_cases/use_cases.dart';

const _wide = Size(1400, 900);
const _narrow = Size(600, 900);

BackofficeDependencies _dependencies(FakeShelterRepository repository, User user) => BackofficeDependencies(
  animals: repository,
  requests: FakeAdoptionRequestRepository(repository),
  user: user,
  clock: FixedClock(DateTime(2026, 10, 29, 10)),
  newId: () => 'r-test',
  users: seedUsers,
  fakeRepository: repository,
);

Future<FakeShelterRepository> _start(
  WidgetTester tester, {
  FakeShelterRepository? repository,
  String location = '/animals',
  Size size = _wide,
  User user = coordinator,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = repository ?? FakeShelterRepository(latency: const Duration(milliseconds: 10));
  await tester.pumpWidget(BackofficeApp(dependencies: _dependencies(repo, user), initialLocation: location));
  return repo;
}

AnimalsTableRow _rowOf(WidgetTester tester, String name) =>
    tester.widget<AnimalsTableRow>(find.widgetWithText(AnimalsTableRow, name));

String _location(WidgetTester tester) {
  final context = tester.element(find.byType(Scaffold).first);
  return GoRouter.of(context).state.uri.toString();
}

/// Tall enough that every request card in the panel is built without scrolling.
const _tall = Size(1400, 2400);

/// Taps the first request button with [label] in the details panel.
Future<void> _tapRequestButton(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(AnimalDetails), matching: find.text(label)).first);
  await tester.pumpAndSettle();
}

Future<void> _tapInDialog(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text(label)));
  await tester.pumpAndSettle();
}

Finder _inRow(String name, String text) =>
    find.descendant(of: find.widgetWithText(AnimalsTableRow, name), matching: find.text(text));

Future<void> _press(WidgetTester tester, LogicalKeyboardKey key, {bool control = false}) async {
  if (control) await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  if (control) await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
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
      expect(find.text('Spremna'), findsWidgets);
    });

    testWidgets('shows an error with a retry button when loading fails', (tester) async {
      final repo = FakeShelterRepository(latency: const Duration(milliseconds: 10))..failNextRequest();
      await _start(tester, repository: repo);
      await tester.pumpAndSettle();

      expect(find.text('Nema veze sa serverom.'), findsOneWidget);
      expect(find.text('Rex'), findsNothing);

      await tester.tap(find.text('Pokušaj ponovo'));
      await tester.pumpAndSettle();

      expect(find.text('Nema veze sa serverom.'), findsNothing);
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

      expect(find.text('Nema veze sa serverom.'), findsOneWidget);
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

    testWidgets('the "Zahtevi" column counts the pending requests and drops to zero after approval', (tester) async {
      await _start(tester, location: '/animals?selected=a-01', size: _tall);
      await tester.pumpAndSettle();

      expect(find.text('ZAHTEVI'), findsOneWidget);
      expect(_inRow('Rex', '3'), findsOneWidget);
      expect(_inRow('Bobi', '—'), findsOneWidget);

      await _press(tester, LogicalKeyboardKey.enter, control: true);
      await _press(tester, LogicalKeyboardKey.enter);

      expect(_inRow('Rex', '3'), findsNothing);
      expect(_inRow('Rex', '—'), findsOneWidget);
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

      await tester.tap(find.byTooltip('Zatvori detalje (Esc)'));
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

  group('approving and rejecting requests', () {
    testWidgets('approving asks first, then reserves the animal and rejects the other requests', (tester) async {
      await _start(tester, location: '/animals?selected=a-01', size: _tall);
      await tester.pumpAndSettle();

      await _tapRequestButton(tester, 'Odobri');

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('Automatski će biti odbijeni zahtevi'), findsOneWidget);

      await _tapInDialog(tester, 'Odobri');

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Odobren'), findsOneWidget);
      expect(find.text('Odbijen'), findsNWidgets(2));
      expect(find.text('Na čekanju'), findsNothing);
      expect(_inRow('Rex', 'Rezervisana'), findsOneWidget);
      expect(_rowOf(tester, 'Rex').selected, isTrue);
    });

    testWidgets('"Otkaži" in the dialog changes nothing', (tester) async {
      await _start(tester, location: '/animals?selected=a-01', size: _tall);
      await tester.pumpAndSettle();

      await _tapRequestButton(tester, 'Odobri');
      await _tapInDialog(tester, 'Otkaži');

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Na čekanju'), findsNWidgets(3));
      expect(find.text('Odobren'), findsNothing);
      expect(_inRow('Rex', 'Rezervisana'), findsNothing);
    });

    testWidgets('rejecting changes only that request', (tester) async {
      await _start(tester, location: '/animals?selected=a-01', size: _tall);
      await tester.pumpAndSettle();

      await _tapRequestButton(tester, 'Odbij');
      await _tapInDialog(tester, 'Odbij');

      expect(find.text('Odbijen'), findsOneWidget);
      expect(find.text('Na čekanju'), findsNWidgets(2));
      expect(_inRow('Rex', 'Rezervisana'), findsNothing);
    });

    testWidgets('a refused approval is explained in a snack bar', (tester) async {
      // An adopter is not allowed to approve, so the domain refuses with NotAllowed.
      await _start(tester, location: '/animals?selected=a-01', size: _tall, user: marko);
      await tester.pumpAndSettle();

      await _tapRequestButton(tester, 'Odobri');
      await _tapInDialog(tester, 'Odobri');

      expect(find.text('Nemate dozvolu za ovu radnju.'), findsOneWidget);
      expect(find.text('Odobren'), findsNothing);
      expect(_inRow('Rex', 'Rezervisana'), findsNothing);
    });
  });

  group('keyboard', () {
    testWidgets('↓ and ↑ move the selection, Esc closes the panel', (tester) async {
      await _start(tester);
      await tester.pumpAndSettle();

      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_location(tester), '/animals?selected=a-01');

      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_location(tester), '/animals?selected=a-02');
      expect(_rowOf(tester, 'Luna').selected, isTrue);

      await _press(tester, LogicalKeyboardKey.arrowUp);
      expect(_location(tester), '/animals?selected=a-01');

      await _press(tester, LogicalKeyboardKey.escape);
      expect(_location(tester), '/animals');
      expect(find.text(_rexDescription), findsNothing);
    });

    testWidgets('↓ past the bottom of the view scrolls the selected row into sight', (tester) async {
      await _start(tester, size: const Size(1400, 500));
      await tester.pumpAndSettle();
      final last = seedAnimals.last;

      for (var i = 0; i < seedAnimals.length; i++) {
        await _press(tester, LogicalKeyboardKey.arrowDown);
      }

      expect(_location(tester), '/animals?selected=${last.id.value}');
      expect(find.widgetWithText(AnimalsTableRow, last.name.text).hitTestable(), findsOneWidget);
    });

    testWidgets('Ctrl+Enter asks to approve the oldest pending request and Enter confirms', (tester) async {
      await _start(tester, location: '/animals?selected=a-01', size: _tall);
      await tester.pumpAndSettle();

      await _press(tester, LogicalKeyboardKey.enter, control: true);
      expect(find.byType(AlertDialog), findsOneWidget);

      await _press(tester, LogicalKeyboardKey.enter);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Odobren'), findsOneWidget);
      expect(_inRow('Rex', 'Rezervisana'), findsOneWidget);
    });

    testWidgets('Ctrl+Enter does nothing when no animal is selected', (tester) async {
      await _start(tester);
      await tester.pumpAndSettle();

      await _press(tester, LogicalKeyboardKey.enter, control: true);

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('→ moves the focus into the details panel, where ↑/↓ go from button to button', (tester) async {
      await _start(tester, location: '/animals?selected=a-01', size: _tall);
      await tester.pumpAndSettle();

      bool insidePanel() {
        final focused = FocusManager.instance.primaryFocus?.context;
        return focused != null &&
            find.byType(AnimalDetails).evaluate().any((panel) {
              var inside = false;
              focused.visitAncestorElements((ancestor) => !(inside = ancestor == panel));
              return inside;
            });
      }

      expect(insidePanel(), isFalse);
      await _press(tester, LogicalKeyboardKey.arrowRight);
      expect(insidePanel(), isTrue);

      // ↓ moves inside the panel; the selected animal stays the same.
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(insidePanel(), isTrue);
      expect(_location(tester), '/animals?selected=a-01');

      // Enter presses the focused request button, which opens its confirmation dialog.
      await _press(tester, LogicalKeyboardKey.enter);
      expect(find.byType(AlertDialog), findsOneWidget);
      await _press(tester, LogicalKeyboardKey.escape);
      expect(find.byType(AlertDialog), findsNothing);

      // ← goes back to the table, and ↓ moves the selection again.
      await _press(tester, LogicalKeyboardKey.arrowLeft);
      expect(insidePanel(), isFalse);
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_location(tester), '/animals?selected=a-02');
    });

    testWidgets('Esc inside the panel closes it and the arrows work on the table again', (tester) async {
      await _start(tester, location: '/animals?selected=a-01', size: _tall);
      await tester.pumpAndSettle();

      await _press(tester, LogicalKeyboardKey.arrowRight);
      await _press(tester, LogicalKeyboardKey.escape);
      expect(_location(tester), '/animals');

      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_location(tester), '/animals?selected=a-01');
    });

    testWidgets('F1 lists the shortcuts and Esc closes the list', (tester) async {
      await _start(tester);
      await tester.pumpAndSettle();

      await _press(tester, LogicalKeyboardKey.f1);
      expect(find.text('Prečice'), findsOneWidget);
      expect(find.text('Pregled prečica'), findsOneWidget);

      await _press(tester, LogicalKeyboardKey.escape);
      expect(find.text('Prečice'), findsNothing);
    });

    testWidgets('Tab puts a visible outline on the focused row and Enter selects it', (tester) async {
      await _start(tester);
      await tester.pumpAndSettle();

      Finder outlined() => find.descendant(
        of: find.byType(AnimalsTableRow),
        matching: find.byWidgetPredicate(
          (widget) => switch (widget) {
            Material(shape: RoundedRectangleBorder(:final side)) => side != BorderSide.none,
            _ => false,
          },
        ),
      );
      expect(outlined(), findsNothing);

      // Tab past the AppBar button and the filter chips until a table row has the focus.
      for (var i = 0; i < 20 && outlined().evaluate().isEmpty; i++) {
        await _press(tester, LogicalKeyboardKey.tab);
      }
      expect(outlined(), findsOneWidget);
      expect(find.descendant(of: outlined(), matching: find.text('Rex')), findsOneWidget);

      await _press(tester, LogicalKeyboardKey.enter);
      expect(_location(tester), '/animals?selected=a-01');
    });
  });

  group('intake', () {
    testWidgets('Ctrl+N opens the form, P1 is checked, and the new animal is saved and selected', (tester) async {
      await _start(tester);
      await tester.pumpAndSettle();

      await _press(tester, LogicalKeyboardKey.keyN, control: true);
      expect(find.text('Prijem nove životinje'), findsOneWidget);

      await tester.tap(find.text('Primi'));
      await tester.pumpAndSettle();
      expect(find.text('Ime mora imati bar 2 znaka.'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Ime'), 'Mrki');
      await tester.tap(find.text('Primi'));
      await tester.pumpAndSettle();

      expect(find.text('Prijem nove životinje'), findsNothing);
      expect(find.text('Mrki je primljen/a u utočište.'), findsOneWidget);
      expect(_location(tester), '/animals?selected=a-r-test');
      expect(_rowOf(tester, 'Mrki').selected, isTrue);
      expect(_inRow('Mrki', 'Primljena'), findsOneWidget);
    });

    testWidgets('the "Nova životinja" button opens the same form and "Otkaži" adds nothing', (tester) async {
      await _start(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nova životinja'));
      await tester.pumpAndSettle();
      expect(find.text('Prijem nove životinje'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Ime'), 'Mrki');
      await tester.tap(find.text('Otkaži'));
      await tester.pumpAndSettle();

      expect(find.text('Prijem nove životinje'), findsNothing);
      expect(find.text('Mrki'), findsNothing);
      expect(_location(tester), '/animals');
    });
  });

  group('quarantine', () {
    testWidgets('"Počni karantin" asks for the end date and moves a received animal into quarantine', (tester) async {
      await _start(tester, location: '/animals?selected=a-05', size: _tall);
      await tester.pumpAndSettle();
      expect(_inRow('Žućko', 'Primljena'), findsOneWidget);

      await tester.tap(find.text('Počni karantin'));
      await tester.pumpAndSettle();
      expect(find.text('Karantin za Žućko traje do'), findsOneWidget);

      // The picker's own buttons are in the app's language, so confirm with the last one (OK) instead of its text.
      await tester.tap(find.descendant(of: find.byType(DatePickerDialog), matching: find.byType(TextButton)).last);
      await tester.pumpAndSettle();

      // The test clock is 29. 10. 2026, and the picker suggests two weeks later.
      expect(find.text('Žućko je u karantinu do 12. 11. 2026.'), findsOneWidget);
      expect(_inRow('Žućko', 'U karantinu'), findsOneWidget);
      expect(find.text('Završi karantin'), findsOneWidget);
    });

    testWidgets('"Završi karantin" asks first, then the animal is ready for adoption', (tester) async {
      await _start(tester, location: '/animals?selected=a-06', size: _tall);
      await tester.pumpAndSettle();
      expect(_inRow('Milka', 'U karantinu'), findsOneWidget);

      await tester.tap(find.text('Završi karantin'));
      await tester.pumpAndSettle();
      expect(find.text('Završiti karantin za Milka?'), findsOneWidget);

      await _press(tester, LogicalKeyboardKey.enter);

      expect(find.text('Milka je spreman/na za udomljavanje.'), findsOneWidget);
      expect(_inRow('Milka', 'Spremna'), findsOneWidget);
      expect(find.text('Završi karantin'), findsNothing);
    });

    testWidgets('animals that are ready for adoption have no quarantine button', (tester) async {
      await _start(tester, location: '/animals?selected=a-01', size: _tall);
      await tester.pumpAndSettle();

      expect(find.text('Počni karantin'), findsNothing);
      expect(find.text('Završi karantin'), findsNothing);
    });
  });
}
