import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart' hide Result;
import 'package:server/server.dart';
import 'package:test/test.dart';

const _milica = User(id: UserId('u-milica'), name: 'Milica', role: Role.adopter);
const _petar = User(id: UserId('u-petar'), name: 'Petar', role: Role.adopter);
const _coordinator = User(id: UserId('u-coordinator'), name: 'Koordinator', role: Role.coordinator);

const _rex = AnimalId('a-rex');
const _bela = AnimalId('a-bela');
const _mila = AnimalId('a-mila');

final _since = DateTime.utc(2026, 10, 1);
final _now = DateTime.utc(2026, 11, 13, 10);

void main() {
  late Pool<void> database;
  late PostgresAdoptionRequestRepository repository;

  setUpAll(() {
    database = Pool<void>.withUrl(serverEnvironment()['DATABASE_URL']!);
    repository = PostgresAdoptionRequestRepository(database);
  });

  tearDownAll(() => database.close());

  setUp(() async {
    await database.execute('TRUNCATE adoption_requests, animals, users');
    for (final user in [_milica, _petar, _coordinator]) {
      await database.execute(
        Sql.named('INSERT INTO users (id, name, role) VALUES (@id, @name, @role)'),
        parameters: {
          'id': user.id.value,
          'name': user.name,
          'role': user.role == Role.adopter ? 'adopter' : 'coordinator',
        },
      );
    }
    for (final animal in [_rex, _bela, _mila]) {
      await database.execute(
        Sql.named(
          'INSERT INTO animals (id, name, species, birth_date, description, enclosure_id, received_at, status, status_since) '
          "VALUES (@id, @id, 'dog', '2022-05-01', 'Opis', 'A1', @since, 'ready-for-adoption', @since)",
        ),
        parameters: {'id': animal.value, 'since': _since},
      );
    }
  });

  AdoptionRequest request(String id, AnimalId animal, User applicant, {int minutes = 0}) => AdoptionRequest(
    id: AdoptionRequestId(id),
    animalId: animal,
    applicantId: applicant.id,
    motivation: RequestMotivation.parse('Imam veliko dvorište i mnogo vremena.').valueOrNull!,
    createdAt: _now.add(Duration(minutes: minutes)),
  );

  final first = request('00000000-0000-4000-8000-000000000001', _rex, _milica);
  final second = request('00000000-0000-4000-8000-000000000002', _rex, _petar, minutes: 1);
  final third = request('00000000-0000-4000-8000-000000000003', _bela, _milica, minutes: 2);
  final fourth = request('00000000-0000-4000-8000-000000000004', _mila, _milica, minutes: 3);

  Animal ready(AnimalId id) => Animal(
    id: id,
    name: AnimalName.parse(id.value).valueOrNull!,
    species: Species.dog,
    birthDate: DateTime(2022, 5, 1),
    description: 'Opis',
    enclosureId: const EnclosureId('A1'),
    status: ReadyForAdoption(since: _since),
    receivedAt: _since,
  );

  ApprovalOutcome outcome(AdoptionRequest chosen, List<AdoptionRequest> all) => approveRequest(
    animal: ready(chosen.animalId),
    request: chosen,
    allRequestsForAnimal: all,
    by: _coordinator,
    now: _now,
  ).valueOrNull!;

  Future<String> animalStatus(AnimalId id) async {
    final rows = await database.execute(
      Sql.named('SELECT status FROM animals WHERE id = @id'),
      parameters: {'id': id.value},
    );
    return rows.single.single! as String;
  }

  group('reading', () {
    test('a submitted request can be found by its id', () async {
      await repository.submit(first);

      expect(await repository.find(first.id), first);
    });

    test('find returns null for a missing id and for an id that is not a uuid', () async {
      expect(await repository.find(first.id), isNull);
      expect(await repository.find(const AdoptionRequestId('abc')), isNull);
    });

    test('requests filters by applicant and by animal, oldest first', () async {
      for (final r in [first, second, third]) {
        await repository.submit(r);
      }

      expect(await repository.requests(), [first, second, third]);
      expect(await repository.requests(applicant: _milica.id), [first, third]);
      expect(await repository.requests(animal: _rex), [first, second]);
      expect(await repository.requests(applicant: _petar.id, animal: _rex), [second]);
    });
  });

  group('save', () {
    test('changes the status when it is still the one we saw', () async {
      await repository.submit(first);
      final withdrawn = first.copyWith(status: AdoptionRequestStatus.withdrawn);

      expect(await repository.save(withdrawn, from: AdoptionRequestStatus.pending), Success(withdrawn));
      expect((await repository.find(first.id))?.status, AdoptionRequestStatus.withdrawn);
    });

    test('refuses when the status changed meanwhile', () async {
      await repository.submit(first);
      final rejected = first.copyWith(status: AdoptionRequestStatus.rejected);

      expect(
        await repository.save(rejected, from: AdoptionRequestStatus.approved),
        const Failure<AdoptionRequest>(InvalidRequestTransition()),
      );
      expect((await repository.find(first.id))?.status, AdoptionRequestStatus.pending);
    });

    test('reports a missing request as not found', () async {
      expect(
        await repository.save(first, from: AdoptionRequestStatus.pending),
        const Failure<AdoptionRequest>(NotFound()),
      );
    });
  });

  group('submit', () {
    test('a second active request for the same animal is a duplicate', () async {
      await repository.submit(first);
      final again = request('00000000-0000-4000-8000-000000000005', _rex, _milica);

      expect(await repository.submit(again), const Failure<AdoptionRequest>(DuplicateRequest()));
    });

    test('a third active request is over the limit', () async {
      await repository.submit(first);
      await repository.submit(third);

      expect(
        await repository.submit(fourth),
        const Failure<AdoptionRequest>(TooManyActiveRequests(max: maxActiveRequests)),
      );
      expect(await repository.find(fourth.id), isNull);
    });

    test('an animal that is not ready for adoption takes no requests', () async {
      await database.execute(
        Sql.named("UPDATE animals SET status = 'received', status_by = @by WHERE id = @id"),
        parameters: {'id': _rex.value, 'by': _coordinator.id.value},
      );

      expect(await repository.submit(first), const Failure<AdoptionRequest>(AnimalNotAdoptable()));
    });

    test('an unknown animal is not found', () async {
      final nowhere = request('00000000-0000-4000-8000-000000000006', const AnimalId('a-nobody'), _milica);

      expect(await repository.submit(nowhere), const Failure<AdoptionRequest>(NotFound()));
    });
  });

  group('approve', () {
    test('reserves the animal, approves the request and rejects the others', () async {
      await repository.submit(first);
      await repository.submit(second);
      final approval = outcome(first, [first, second]);

      expect(await repository.approve(approval), Success(approval));
      expect(await animalStatus(_rex), 'reserved');
      expect((await repository.find(first.id))?.status, AdoptionRequestStatus.approved);
      expect((await repository.find(second.id))?.status, AdoptionRequestStatus.rejected);
    });

    test('writes who approved it, when, and for which request', () async {
      await repository.submit(first);

      await repository.approve(outcome(first, [first]));

      final rows = await database.execute(
        Sql.named('SELECT status_by, status_since, reserved_request FROM animals WHERE id = @id'),
        parameters: {'id': _rex.value},
      );
      expect(rows.single, [_coordinator.id.value, _now, first.id.value]);
    });

    test('changes nothing when the animal is no longer ready', () async {
      await repository.submit(first);
      await repository.submit(second);
      await repository.approve(outcome(first, [first, second]));

      expect(await repository.approve(outcome(second, [second])), const Failure<ApprovalOutcome>(AnimalNotAdoptable()));
      expect((await repository.find(first.id))?.status, AdoptionRequestStatus.approved);
    });

    test('rolls the animal back when the request was withdrawn meanwhile', () async {
      await repository.submit(first);
      final approval = outcome(first, [first]);
      await repository.save(
        first.copyWith(status: AdoptionRequestStatus.withdrawn),
        from: AdoptionRequestStatus.pending,
      );

      expect(await repository.approve(approval), const Failure<ApprovalOutcome>(InvalidRequestTransition()));
      expect(await animalStatus(_rex), 'ready-for-adoption');
    });

    test('rolls everything back when a new request arrived meanwhile', () async {
      await repository.submit(first);
      final approval = outcome(first, [first]);
      await repository.submit(second);

      expect(await repository.approve(approval), const Failure<ApprovalOutcome>(InvalidRequestTransition()));
      expect(await animalStatus(_rex), 'ready-for-adoption');
      expect((await repository.find(first.id))?.status, AdoptionRequestStatus.pending);
      expect((await repository.find(second.id))?.status, AdoptionRequestStatus.pending);
    });
  });
}
