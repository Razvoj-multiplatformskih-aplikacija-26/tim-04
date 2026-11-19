import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile/app.dart';
import 'package:mobile/data/fake_shelter_repository.dart';
import 'package:mobile/dependencies.dart';
import 'package:use_cases/use_cases.dart';

Future<void> initializeTestEnvironment() => initializeDateFormatting('sr_Latn');

Widget appWith(FakeShelterRepository repository, {SessionRepository? sessions}) => UtocisteApp(
  dependencies: AppDependencies.fake(repository: repository, sessions: sessions),
);

Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(const Duration(milliseconds: 100));

void usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
}

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
  await settle(tester);
}

Future<void> openRequestForm(WidgetTester tester, String animalName) async {
  await tester.tap(find.text(animalName));
  await settle(tester);
  await tester.tap(find.text('Podnesi zahtev'));
  await settle(tester);
}
