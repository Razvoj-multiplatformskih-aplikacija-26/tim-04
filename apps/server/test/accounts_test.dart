import 'package:postgres/postgres.dart';
import 'package:server/server.dart';
import 'package:server/src/passwords.dart';
import 'package:test/test.dart';

import 'support/test_database.dart';

void main() {
  late Pool<void> database;

  setUpAll(() async {
    database = await freshTestDatabase('utociste_test_accounts');
    await seedDemoData(database, demoPassword: 'test-password');
  });

  tearDownAll(() => database.close());

  test('a password matches its hash and nothing else', () async {
    final hash = await hashPassword('tajna');

    expect(hash, isNot(contains('tajna')));
    expect(await verifyPassword('tajna', hash), isTrue);
    expect(await verifyPassword('pogresna', hash), isFalse);
  });

  test('every role has a demo account that opens with the demo password', () async {
    final rows = await database.execute('SELECT role, password_hash FROM users WHERE login IS NOT NULL');

    expect(
      {for (final row in rows) row[0]},
      {'adopter', 'volunteer', 'senior-volunteer', 'veterinarian', 'coordinator'},
    );
    for (final row in rows) {
      expect(await verifyPassword('test-password', row[1]! as String), isTrue, reason: '${row[0]}');
    }
  });
}
