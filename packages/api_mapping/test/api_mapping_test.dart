import 'dart:convert';

import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

Map<String, Object?> overTheWire(Map<String, Object?> json) => jsonDecode(jsonEncode(json)) as Map<String, Object?>;

Animal animalOverTheWire(Animal animal) => AnimalDto.fromJson(overTheWire(animal.toDto().toJson())).toDomain();

AdoptionRequest requestOverTheWire(AdoptionRequest request) =>
    AdoptionRequestDto.fromJson(overTheWire(request.toDto().toJson())).toDomain();

void main() {
  final rex = Animal(
    id: const AnimalId('a-01'),
    name: AnimalName.parse('Rex').valueOrNull!,
    species: Species.dog,
    birthDate: DateTime(2022, 4, 12),
    description: 'Miran i druželjubiv pas srednje veličine.',
    enclosureId: const EnclosureId('B-1'),
    status: ReadyForAdoption(since: DateTime.utc(2026, 8, 20)),
    receivedAt: DateTime.utc(2026, 8, 3, 9, 30),
    photoUrl: 'assets/animals/rex.jpg',
  );

  final request = AdoptionRequest(
    id: const AdoptionRequestId('r-01'),
    animalId: rex.id,
    applicantId: const UserId('u-marko'),
    motivation: RequestMotivation.parse('Imamo veliko dvorište i mnogo slobodnog vremena.').valueOrNull!,
    createdAt: DateTime.utc(2026, 11, 8, 10),
  );

  group('Animal', () {
    final statuses = <AnimalStatus>[
      Received(receivedBy: const UserId('u-coordinator'), at: DateTime.utc(2026, 8, 3, 9, 30)),
      InQuarantine(since: DateTime.utc(2026, 8, 3), until: DateTime.utc(2026, 8, 17)),
      ReadyForAdoption(since: DateTime.utc(2026, 8, 20)),
      Reserved(
        requestId: const AdoptionRequestId('r-01'),
        approvedBy: const UserId('u-coordinator'),
        at: DateTime.utc(2026, 11, 8, 12),
      ),
      Adopted(adopterId: const UserId('u-marko'), at: DateTime.utc(2026, 11, 20)),
      const PermanentResident(reason: 'Starost'),
      Returned(reason: 'Nedovoljno prostora', at: DateTime.utc(2026, 12, 1)),
    ];

    for (final status in statuses) {
      test('survives the trip through the contract unchanged when ${status.runtimeType}', () {
        final sent = rex.copyWith(status: status);

        expect(animalOverTheWire(sent), sent);
      });
    }

    test('every species survives the trip', () {
      for (final species in Species.values) {
        expect(speciesFromDto(species.toDto()), species);
      }
    });

    test('the photo travels as a file name and comes back as the asset path', () {
      expect(rex.toDto().photo, 'rex.jpg');
      expect(animalOverTheWire(rex).photoUrl, 'assets/animals/rex.jpg');
    });

    test('an animal without a photo comes back without one', () {
      final noPhoto = Animal(
        id: rex.id,
        name: rex.name,
        species: rex.species,
        birthDate: rex.birthDate,
        description: rex.description,
        enclosureId: rex.enclosureId,
        status: rex.status,
        receivedAt: rex.receivedAt,
      );

      expect(animalOverTheWire(noPhoto), noPhoto);
    });

    test('the birth date travels as a date and comes back as the same calendar day', () {
      expect(rex.toDto().toJson()['birthDate'], '2022-04-12');
      expect(animalOverTheWire(rex).birthDate, DateTime(2022, 4, 12));
    });

    test('an unknown status kind is refused', () {
      final json = {
        ...rex.toDto().toJson(),
        'status': {'kind': 'on-holiday'},
      };

      expect(() => AnimalDto.fromJson(overTheWire(json)).toDomain(), throwsFormatException);
    });

    test('a status that misses one of its fields is refused', () {
      final json = {
        ...rex.toDto().toJson(),
        'status': {'kind': 'reserved', 'requestId': 'r-01', 'at': '2026-11-08T12:00:00.000Z'},
      };

      expect(() => AnimalDto.fromJson(overTheWire(json)).toDomain(), throwsFormatException);
    });

    test('an unknown species is refused', () {
      final json = {...rex.toDto().toJson(), 'species': 'cat'};

      expect(() => AnimalDto.fromJson(overTheWire(json)).toDomain(), throwsFormatException);
    });

    test('a name that breaks P1 is refused even when it comes from the network', () {
      final json = {...rex.toDto().toJson(), 'name': 'R'};

      expect(() => AnimalDto.fromJson(overTheWire(json)).toDomain(), throwsFormatException);
    });
  });

  group('AdoptionRequest', () {
    for (final status in AdoptionRequestStatus.values) {
      test('survives the trip through the contract unchanged when ${status.name}', () {
        final sent = request.copyWith(status: status);

        expect(requestOverTheWire(sent), sent);
      });
    }

    test('the status goes on the wire as its name', () {
      expect(request.copyWith(status: AdoptionRequestStatus.withdrawn).toDto().status, 'withdrawn');
    });

    test('an unknown status is refused', () {
      final json = {...request.toDto().toJson(), 'status': 'on-hold'};

      expect(() => AdoptionRequestDto.fromJson(overTheWire(json)).toDomain(), throwsFormatException);
    });

    test('a motivation that breaks P2 is refused even when it comes from the network', () {
      final json = {...request.toDto().toJson(), 'motivation': 'Kratko.'};

      expect(() => AdoptionRequestDto.fromJson(overTheWire(json)).toDomain(), throwsFormatException);
    });
  });
}
