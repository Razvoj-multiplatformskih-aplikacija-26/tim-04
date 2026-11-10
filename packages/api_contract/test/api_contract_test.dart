import 'package:api_contract/api_contract.dart';
import 'package:test/test.dart';

void main() {
  final quarantine = AnimalStatusDto(
    kind: AnimalStatusDto.inQuarantine,
    since: DateTime.utc(2026, 11, 1),
    until: DateTime.utc(2026, 11, 15),
  );

  final milka = AnimalDto(
    id: 'a-06',
    name: 'Milka',
    species: AnimalDto.cow,
    birthDate: DateTime.utc(2020, 3, 5),
    description: 'Mirna krava.',
    enclosureId: 'K-1',
    receivedAt: DateTime.utc(2026, 10, 15, 9, 30),
    status: quarantine,
    photo: 'milka.jpg',
  );

  final request = AdoptionRequestDto(
    id: 'r-1',
    animalId: 'a-01',
    applicantId: 'u-ana',
    motivation: 'Imamo veliko dvorište i mnogo slobodnog vremena.',
    createdAt: DateTime.utc(2026, 11, 8, 10),
    status: AdoptionRequestDto.pending,
  );

  group('AnimalStatusDto', () {
    test('a quarantine goes on the wire as its kind plus its own fields only', () {
      expect(quarantine.toJson(), {
        'kind': 'in-quarantine',
        'since': '2026-11-01T00:00:00.000Z',
        'until': '2026-11-15T00:00:00.000Z',
      });
    });

    test('a reservation survives the round trip', () {
      final reserved = AnimalStatusDto(
        kind: AnimalStatusDto.reserved,
        requestId: 'r-1',
        approvedBy: 'u-coordinator',
        at: DateTime.utc(2026, 11, 8, 12),
      );

      final back = AnimalStatusDto.fromJson(reserved.toJson());

      expect(back.kind, AnimalStatusDto.reserved);
      expect(back.requestId, 'r-1');
      expect(back.approvedBy, 'u-coordinator');
      expect(back.at, DateTime.utc(2026, 11, 8, 12));
    });

    test('a status without its kind is refused', () {
      expect(() => AnimalStatusDto.fromJson({'since': '2026-11-01T00:00:00.000Z'}), throwsFormatException);
    });
  });

  group('AnimalDto', () {
    test('survives the round trip', () {
      final back = AnimalDto.fromJson(milka.toJson());

      expect(back.id, milka.id);
      expect(back.name, milka.name);
      expect(back.species, AnimalDto.cow);
      expect(back.birthDate, milka.birthDate);
      expect(back.description, milka.description);
      expect(back.enclosureId, milka.enclosureId);
      expect(back.receivedAt, milka.receivedAt);
      expect(back.status.kind, AnimalStatusDto.inQuarantine);
      expect(back.status.until, quarantine.until);
      expect(back.photo, 'milka.jpg');
    });

    test('the birth date is a date and the intake time is an instant', () {
      final json = milka.toJson();

      expect(json['birthDate'], '2020-03-05');
      expect(json['receivedAt'], '2026-10-15T09:30:00.000Z');
    });

    test('an animal without a photo leaves the key out', () {
      final json = AnimalDto.fromJson({...milka.toJson()}..remove('photo')).toJson();

      expect(json.containsKey('photo'), isFalse);
    });

    test('an older client reads an animal that carries a field it does not know yet', () {
      final back = AnimalDto.fromJson({...milka.toJson(), 'microchip': '688032000123456'});

      expect(back.name, 'Milka');
    });

    test('a missing required field is refused', () {
      expect(() => AnimalDto.fromJson({...milka.toJson()}..remove('name')), throwsFormatException);
      expect(() => AnimalDto.fromJson({...milka.toJson()}..remove('status')), throwsFormatException);
    });

    test('a birth date written as an instant is refused', () {
      expect(
        () => AnimalDto.fromJson({...milka.toJson(), 'birthDate': '2020-03-05T00:00:00.000Z'}),
        throwsFormatException,
      );
    });

    test('a time without a time zone is refused', () {
      expect(() => AnimalDto.fromJson({...milka.toJson(), 'receivedAt': '2026-10-15T09:30:00'}), throwsFormatException);
    });
  });

  group('IntakeDto', () {
    test('survives the round trip and carries no id, status or intake time', () {
      final intake = IntakeDto(
        name: 'Mrki',
        species: AnimalDto.dog,
        birthDate: DateTime.utc(2025, 5, 1),
        description: 'Pronađen kraj puta.',
        enclosureId: 'P-1',
      );

      final json = intake.toJson();
      final back = IntakeDto.fromJson(json);

      expect(json.keys, unorderedEquals(['name', 'species', 'birthDate', 'description', 'enclosureId']));
      expect(back.name, 'Mrki');
      expect(back.birthDate, DateTime.utc(2025, 5, 1));
      expect(back.enclosureId, 'P-1');
    });
  });

  group('QuarantineDto', () {
    test('survives the round trip', () {
      final back = QuarantineDto.fromJson(QuarantineDto(until: DateTime.utc(2026, 11, 20)).toJson());

      expect(back.until, DateTime.utc(2026, 11, 20));
    });

    test('an end without a time zone is refused', () {
      expect(() => QuarantineDto.fromJson({'until': '2026-11-20T00:00:00'}), throwsFormatException);
    });
  });

  group('AdoptionRequestDto', () {
    test('survives the round trip', () {
      final back = AdoptionRequestDto.fromJson(request.toJson());

      expect(back.id, request.id);
      expect(back.animalId, request.animalId);
      expect(back.applicantId, request.applicantId);
      expect(back.motivation, request.motivation);
      expect(back.createdAt, request.createdAt);
      expect(back.status, AdoptionRequestDto.pending);
    });

    test('an older client reads a request that carries a field it does not know yet', () {
      final back = AdoptionRequestDto.fromJson({...request.toJson(), 'decidedBy': 'u-coordinator'});

      expect(back.status, AdoptionRequestDto.pending);
    });

    test('a missing required field is refused', () {
      expect(() => AdoptionRequestDto.fromJson({...request.toJson()}..remove('animalId')), throwsFormatException);
    });
  });

  group('NewAdoptionRequestDto', () {
    test('sends only the animal and the motivation', () {
      final json = const NewAdoptionRequestDto(animalId: 'a-01', motivation: 'Imamo veliko dvorište.').toJson();
      final back = NewAdoptionRequestDto.fromJson(json);

      expect(json.keys, unorderedEquals(['animalId', 'motivation']));
      expect(back.animalId, 'a-01');
      expect(back.motivation, 'Imamo veliko dvorište.');
    });
  });

  group('ApiPaths', () {
    test('actions on a request are nouns under the request', () {
      expect(ApiPaths.withdrawal('r-1'), '/api/v1/adoption-requests/r-1/withdrawal');
      expect(ApiPaths.approval('r-1'), '/api/v1/adoption-requests/r-1/approval');
      expect(ApiPaths.rejection('r-1'), '/api/v1/adoption-requests/r-1/rejection');
    });

    test('the quarantine lives under the animal', () {
      expect(ApiPaths.animal('a-06'), '/api/v1/animals/a-06');
      expect(ApiPaths.quarantine('a-06'), '/api/v1/animals/a-06/quarantine');
    });
  });
}
