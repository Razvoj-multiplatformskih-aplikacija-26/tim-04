import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  final received = rex.copyWith(
    status: Received(receivedBy: coordinator.id, at: DateTime(2026, 10, 20)),
  );
  final returned = rex.copyWith(
    status: Returned(reason: 'Alergija u porodici', at: DateTime(2026, 10, 20)),
  );
  final until = DateTime(2026, 11, 5);

  group('P1 · intakeAnimal', () {
    Result<Animal> intake({User by = coordinator, String name = 'Bobi'}) {
      return intakeAnimal(
        id: const AnimalId('a-new'),
        by: by,
        name: name,
        species: Species.dog,
        birthDate: DateTime(2024, 3, 1),
        description: 'Pronađen pored puta, umiljat.',
        enclosureId: const EnclosureId('e-2'),
        now: now,
      );
    }

    test('creates a received animal', () {
      final animal = intake().valueOrNull!;

      expect(animal.id, const AnimalId('a-new'));
      expect(animal.name.text, 'Bobi');
      expect(animal.status, Received(receivedBy: coordinator.id, at: now));
      expect(animal.receivedAt, now);
      expect(animal.photoUrl, isNull);
    });

    test('trims spaces around the name', () {
      expect(intake(name: '  Bobi  ').valueOrNull?.name.text, 'Bobi');
    });

    test('rejects everyone except the coordinator', () {
      for (final user in [ana, volunteer, senior, vet]) {
        expect(intake(by: user), const Failure<Animal>(NotAllowed()));
      }
    });

    test('rejects a name that is too short', () {
      expect(intake(name: 'A' * (AnimalName.minLength - 1)), const Failure<Animal>(NameTooShort()));
    });

    test('rejects a name that is too long', () {
      expect(intake(name: 'A' * (AnimalName.maxLength + 1)), const Failure<Animal>(NameTooLong()));
    });

    test('checks permission before the name', () {
      expect(intake(by: ana, name: 'A'), const Failure<Animal>(NotAllowed()));
    });
  });

  group('startQuarantine', () {
    test('moves a received animal into quarantine', () {
      expect(
        startQuarantine(animal: received, by: coordinator, now: now, until: until),
        Success(
          received.copyWith(
            status: InQuarantine(since: now, until: until),
          ),
        ),
      );
    });

    test('a returned animal can go back into quarantine', () {
      final result = startQuarantine(animal: returned, by: coordinator, now: now, until: until);

      expect(result.valueOrNull?.status, InQuarantine(since: now, until: until));
    });

    test('only the coordinator can start a quarantine', () {
      for (final user in [ana, volunteer, senior, vet]) {
        expect(
          startQuarantine(animal: received, by: user, now: now, until: until),
          const Failure<Animal>(NotAllowed()),
        );
      }
    });

    test('rejects an animal that is ready for adoption', () {
      expect(
        startQuarantine(animal: rex, by: coordinator, now: now, until: until),
        Failure<Animal>(
          InvalidTransition(
            from: rex.status,
            to: InQuarantine(since: now, until: until),
          ),
        ),
      );
    });
  });

  group('endQuarantine', () {
    test('makes a quarantined animal ready for adoption', () {
      expect(
        endQuarantine(animal: rexInQuarantine, by: coordinator, now: now),
        Success(rexInQuarantine.copyWith(status: ReadyForAdoption(since: now))),
      );
    });

    test('a veterinarian can end a quarantine as well', () {
      expect(endQuarantine(animal: rexInQuarantine, by: vet, now: now).isSuccess, isTrue);
    });

    test('rejects adopters, volunteers and senior volunteers', () {
      for (final user in [ana, volunteer, senior]) {
        expect(endQuarantine(animal: rexInQuarantine, by: user, now: now), const Failure<Animal>(NotAllowed()));
      }
    });

    test('rejects an animal that is not in quarantine', () {
      for (final animal in [received, rex]) {
        expect(endQuarantine(animal: animal, by: coordinator, now: now).errorOrNull, isA<InvalidTransition>());
      }
    });

    test('rejects a returned animal even though Returned → ReadyForAdoption is an allowed transition', () {
      expect(canTransition(returned.status, ReadyForAdoption(since: now)), isTrue);
      expect(endQuarantine(animal: returned, by: coordinator, now: now).errorOrNull, isA<InvalidTransition>());
    });
  });
}
