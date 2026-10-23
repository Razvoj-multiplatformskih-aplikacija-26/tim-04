import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  final anasRequest = AdoptionRequest(
    id: const AdoptionRequestId('r-1'),
    animalId: const AnimalId('a-1'),
    applicantId: ana.id,
    motivation: RequestMotivation.parse('Imamo veliko dvorište i mnogo vremena.').valueOrNull!,
    createdAt: DateTime(2026, 10, 1),
  );

  group('AccessPolicy', () {
    group('canSubmitRequest', () {
      test('an adopter can submit a request', () {
        expect(AccessPolicy.canSubmitRequest(ana), isTrue);
      });

      test('staff cannot submit a request', () {
        expect(AccessPolicy.canSubmitRequest(volunteer), isFalse);
        expect(AccessPolicy.canSubmitRequest(senior), isFalse);
        expect(AccessPolicy.canSubmitRequest(vet), isFalse);
        expect(AccessPolicy.canSubmitRequest(coordinator), isFalse);
      });
    });

    group('canWithdraw', () {
      test('the applicant can withdraw their own request', () {
        expect(AccessPolicy.canWithdraw(ana, anasRequest), isTrue);
      });

      test('another adopter cannot withdraw it', () {
        expect(AccessPolicy.canWithdraw(marko, anasRequest), isFalse);
      });

      test('staff cannot withdraw it either', () {
        expect(AccessPolicy.canWithdraw(coordinator, anasRequest), isFalse);
        expect(AccessPolicy.canWithdraw(senior, anasRequest), isFalse);
      });
    });

    group('canDecide', () {
      test('a coordinator and a senior volunteer can decide', () {
        expect(AccessPolicy.canDecide(coordinator), isTrue);
        expect(AccessPolicy.canDecide(senior), isTrue);
      });

      test('adopters, volunteers and vets cannot decide', () {
        expect(AccessPolicy.canDecide(ana), isFalse);
        expect(AccessPolicy.canDecide(volunteer), isFalse);
        expect(AccessPolicy.canDecide(vet), isFalse);
      });
    });

    group('canIntake', () {
      test('a coordinator can take in an animal', () {
        expect(AccessPolicy.canIntake(coordinator), isTrue);
      });

      test('nobody else can take in an animal', () {
        expect(AccessPolicy.canIntake(ana), isFalse);
        expect(AccessPolicy.canIntake(volunteer), isFalse);
        expect(AccessPolicy.canIntake(senior), isFalse);
        expect(AccessPolicy.canIntake(vet), isFalse);
      });
    });

    group('canEndQuarantine', () {
      test('a coordinator and a vet can end quarantine', () {
        expect(AccessPolicy.canEndQuarantine(coordinator), isTrue);
        expect(AccessPolicy.canEndQuarantine(vet), isTrue);
      });

      test('adopters and volunteers cannot end quarantine', () {
        expect(AccessPolicy.canEndQuarantine(ana), isFalse);
        expect(AccessPolicy.canEndQuarantine(volunteer), isFalse);
        expect(AccessPolicy.canEndQuarantine(senior), isFalse);
      });
    });

    group('canChangeAnimalStatus', () {
      test('a coordinator can change the status', () {
        expect(AccessPolicy.canChangeAnimalStatus(coordinator), isTrue);
      });

      test('nobody else can change the status', () {
        expect(AccessPolicy.canChangeAnimalStatus(ana), isFalse);
        expect(AccessPolicy.canChangeAnimalStatus(volunteer), isFalse);
        expect(AccessPolicy.canChangeAnimalStatus(senior), isFalse);
        expect(AccessPolicy.canChangeAnimalStatus(vet), isFalse);
      });
    });
  });
}
