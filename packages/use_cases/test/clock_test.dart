import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

void main() {
  test('a fixed clock always returns the same instant in UTC', () {
    final clock = FixedClock(DateTime(2026, 10, 9, 20));
    expect(clock.now(), DateTime(2026, 10, 9, 20).toUtc());
    expect(clock.now().isUtc, isTrue);
  });

  test('the system clock returns the current instant in UTC', () {
    final before = DateTime.now().toUtc();
    final now = const SystemClock().now();
    final after = DateTime.now().toUtc();

    expect(now.isUtc, isTrue);
    expect(now.isBefore(before), isFalse);
    expect(now.isAfter(after), isFalse);
  });
}
