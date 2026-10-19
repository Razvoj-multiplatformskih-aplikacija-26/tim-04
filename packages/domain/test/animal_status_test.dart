import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  final at = DateTime(2026, 10, 1);
  const staff = UserId('u-coordinator');

  final received = Received(receivedBy: staff, at: at);
  final quarantine = InQuarantine(since: at, until: at.add(const Duration(days: 14)));
  final ready = ReadyForAdoption(since: at);
  final reserved = Reserved(requestId: const AdoptionRequestId('r-1'), approvedBy: staff, at: at);
  final adopted = Adopted(adopterId: const UserId('u-ana'), at: at);
  const resident = PermanentResident(reason: 'Starost');
  final returned = Returned(reason: 'Alergija', at: at);

  group('canTransition', () {
    test('allows the main adoption path', () {
      expect(canTransition(received, quarantine), isTrue);
      expect(canTransition(quarantine, ready), isTrue);
      expect(canTransition(ready, reserved), isTrue);
      expect(canTransition(reserved, adopted), isTrue);
    });

    test('allows side paths', () {
      expect(canTransition(quarantine, resident), isTrue);
      expect(canTransition(ready, resident), isTrue);
      expect(canTransition(reserved, ready), isTrue);
      expect(canTransition(adopted, returned), isTrue);
      expect(canTransition(returned, quarantine), isTrue);
      expect(canTransition(returned, ready), isTrue);
      expect(canTransition(returned, resident), isTrue);
    });

    test('forbids skipping quarantine and leaving a permanent resident', () {
      expect(canTransition(received, ready), isFalse);
      expect(canTransition(ready, adopted), isFalse);
      expect(canTransition(resident, ready), isFalse);
      expect(canTransition(adopted, ready), isFalse);
    });
  });

  group('AnimalStatus', () {
    test('only ready animals are adoptable', () {
      expect(ready.isAdoptable, isTrue);
      expect(reserved.isAdoptable, isFalse);
      expect(resident.isAdoptable, isFalse);
    });

    test('adopted animals and permanent residents are final', () {
      expect(adopted.isFinal, isTrue);
      expect(resident.isFinal, isTrue);
      expect(ready.isFinal, isFalse);
    });
  });
}
