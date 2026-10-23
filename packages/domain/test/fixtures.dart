import 'package:domain/domain.dart';

const ana = User(id: UserId('u-ana'), username: 'ana', role: Role.adopter);

const marko = User(id: UserId('u-marko'), username: 'marko', role: Role.adopter);

const jelena = User(id: UserId('u-jelena'), username: 'jelena', role: Role.adopter);

const coordinator = User(id: UserId('u-coordinator'), username: 'coordinator', role: Role.coordinator);

const senior = User(id: UserId('u-senior'), username: 'senior', role: Role.seniorVolunteer);

const vet = User(id: UserId('u-vet'), username: 'vet', role: Role.veterinarian);

const volunteer = User(id: UserId('u-volunteer'), username: 'volunteer', role: Role.volunteer);

final now = DateTime(2026, 10, 22);

final motivation = RequestMotivation.parse('Imamo veliko dvorište i mnogo slobodnog vremena.').valueOrNull!;

final rex = Animal(
  id: const AnimalId('a-rex'),
  name: AnimalName.parse('Rex').valueOrNull!,
  species: Species.dog,
  birthDate: DateTime(2022, 5, 10),
  description: 'Miran i druželjubiv pas.',
  enclosureId: const EnclosureId('e-1'),
  status: ReadyForAdoption(since: DateTime(2026, 9, 1)),
  receivedAt: DateTime(2026, 8, 1),
);

final rexInQuarantine = rex.copyWith(
  status: InQuarantine(since: DateTime(2026, 10, 1), until: DateTime(2026, 10, 31)),
);

AdoptionRequest requestBy(
  User user, {
  required AnimalId animalId,
  String id = 'r-1',
  AdoptionRequestStatus status = AdoptionRequestStatus.pending,
  DateTime? createdAt,
}) {
  return AdoptionRequest(
    id: AdoptionRequestId(id),
    animalId: animalId,
    applicantId: user.id,
    motivation: motivation,
    createdAt: createdAt ?? DateTime(2026, 10, 10),
    status: status,
  );
}
