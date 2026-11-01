import 'package:domain/domain.dart';

const coordinator = User(id: UserId('u-coordinator'), username: 'Dragana Ilić', role: Role.coordinator);
const seniorVolunteer = User(id: UserId('u-senior'), username: 'Petar Simić', role: Role.seniorVolunteer);
const veterinarian = User(id: UserId('u-vet'), username: 'dr Ivana Lazić', role: Role.veterinarian);

const ana = User(id: UserId('u-ana'), username: 'Ana Petrović', role: Role.adopter);
const marko = User(id: UserId('u-marko'), username: 'Marko Jovanović', role: Role.adopter);
const jelena = User(id: UserId('u-jelena'), username: 'Jelena Nikolić', role: Role.adopter);
const nikola = User(id: UserId('u-nikola'), username: 'Nikola Đorđević', role: Role.adopter);
const milica = User(id: UserId('u-milica'), username: 'Milica Stojanović', role: Role.adopter);
const stefan = User(id: UserId('u-stefan'), username: 'Stefan Ilić', role: Role.adopter);

const seedUsers = [coordinator, seniorVolunteer, veterinarian, ana, marko, jelena, nikola, milica, stefan];
const currentUser = ana;

AnimalName _name(String text) => AnimalName.parse(text).valueOrNull!;

RequestMotivation _motivation(String text) => RequestMotivation.parse(text).valueOrNull!;

Animal _animal(
  String id, {
  required String name,
  required Species species,
  required DateTime birthDate,
  required String description,
  required String enclosure,
  required DateTime receivedAt,
  required AnimalStatus status,
}) {
  return Animal(
    id: AnimalId(id),
    name: _name(name),
    species: species,
    birthDate: birthDate,
    description: description,
    enclosureId: EnclosureId(enclosure),
    status: status,
    receivedAt: receivedAt,
  );
}

AdoptionRequest _request(
  String id, {
  required User by,
  required String animal,
  required DateTime createdAt,
  required String motivation,
  AdoptionRequestStatus status = AdoptionRequestStatus.pending,
}) {
  return AdoptionRequest(
    id: AdoptionRequestId(id),
    animalId: AnimalId(animal),
    applicantId: by.id,
    motivation: _motivation(motivation),
    createdAt: createdAt,
    status: status,
  );
}

final seedAnimals = [
  _animal(
    'a-01',
    name: 'Rex',
    species: Species.dog,
    birthDate: DateTime(2022, 4, 12),
    description: 'Miran i druželjubiv pas srednje veličine, voli šetnje i decu.',
    enclosure: 'B-1',
    receivedAt: DateTime(2026, 8, 3),
    status: ReadyForAdoption(since: DateTime(2026, 8, 20)),
  ),
  _animal(
    'a-02',
    name: 'Luna',
    species: Species.dog,
    birthDate: DateTime(2024, 1, 5),
    description: 'Razigrana mlada kuja, brzo uči komande i slaže se sa drugim psima.',
    enclosure: 'B-2',
    receivedAt: DateTime(2026, 9, 1),
    status: ReadyForAdoption(since: DateTime(2026, 9, 16)),
  ),
  _animal(
    'a-03',
    name: 'Mrvica',
    species: Species.goat,
    birthDate: DateTime(2025, 3, 20),
    description: 'Mala radoznala koza, navikla na ljude, traži dvorište sa travom.',
    enclosure: 'I-1',
    receivedAt: DateTime(2026, 7, 14),
    status: ReadyForAdoption(since: DateTime(2026, 8, 1)),
  ),
  _animal(
    'a-04',
    name: 'Bela',
    species: Species.cow,
    birthDate: DateTime(2023, 6, 2),
    description: 'Mirna krava, spašena sa napuštenog imanja, potpuno zdrava.',
    enclosure: 'S-1',
    receivedAt: DateTime(2026, 6, 10),
    status: ReadyForAdoption(since: DateTime(2026, 7, 1)),
  ),
  _animal(
    'a-05',
    name: 'Žućko',
    species: Species.dog,
    birthDate: DateTime(2021, 9, 1),
    description: 'Pronađen na putu pored Pančeva, čeka prvi pregled veterinara.',
    enclosure: 'P-1',
    receivedAt: DateTime(2026, 10, 27),
    status: Received(receivedBy: coordinator.id, at: DateTime(2026, 10, 27, 9, 30)),
  ),
  _animal(
    'a-06',
    name: 'Milka',
    species: Species.cow,
    birthDate: DateTime(2020, 2, 14),
    description: 'Starija krava sa blagom upalom papka, na terapiji.',
    enclosure: 'K-1',
    receivedAt: DateTime(2026, 10, 15),
    status: InQuarantine(since: DateTime(2026, 10, 16), until: DateTime(2026, 11, 6)),
  ),
  _animal(
    'a-07',
    name: 'Grom',
    species: Species.horse,
    birthDate: DateTime(2016, 5, 30),
    description: 'Bivši radni konj, plašljiv prema novim ljudima, ali vrlo nežan.',
    enclosure: 'K-2',
    receivedAt: DateTime(2026, 10, 20),
    status: InQuarantine(since: DateTime(2026, 10, 21), until: DateTime(2026, 11, 4)),
  ),
  _animal(
    'a-08',
    name: 'Maza',
    species: Species.dog,
    birthDate: DateTime(2023, 11, 11),
    description: 'Mala maza koja obožava krilo, pogodna za stan.',
    enclosure: 'B-3',
    receivedAt: DateTime(2026, 8, 25),
    status: Reserved(
      requestId: const AdoptionRequestId('r-08'),
      approvedBy: coordinator.id,
      at: DateTime(2026, 10, 24, 14, 0),
    ),
  ),
  _animal(
    'a-09',
    name: 'Bobi',
    species: Species.dog,
    birthDate: DateTime(2022, 12, 24),
    description: 'Veseo pas koji je pronašao novu porodicu u Novom Sadu.',
    enclosure: 'B-4',
    receivedAt: DateTime(2026, 5, 2),
    status: Adopted(adopterId: stefan.id, at: DateTime(2026, 9, 28)),
  ),
  _animal(
    'a-10',
    name: 'Zvezda',
    species: Species.horse,
    birthDate: DateTime(2004, 4, 4),
    description: 'Najstarija stanovnica utočišta, ostaje kod nas i traži kuma.',
    enclosure: 'K-3',
    receivedAt: DateTime(2025, 3, 1),
    status: const PermanentResident(reason: 'Starost'),
  ),
  _animal(
    'a-11',
    name: 'Kozica',
    species: Species.goat,
    birthDate: DateTime(2019, 8, 8),
    description: 'Slepa na jedno oko, potrebna joj je stalna nega u poznatom okruženju.',
    enclosure: 'I-2',
    receivedAt: DateTime(2025, 11, 12),
    status: const PermanentResident(reason: 'Zdravstveno stanje'),
  ),
  _animal(
    'a-12',
    name: 'Medo',
    species: Species.dog,
    birthDate: DateTime(2021, 3, 3),
    description: 'Krupan i dobroćudan pas, vraćen jer porodica nije imala dovoljno prostora.',
    enclosure: 'B-5',
    receivedAt: DateTime(2026, 4, 18),
    status: Returned(reason: 'Nedovoljno prostora', at: DateTime(2026, 10, 22)),
  ),
];

final seedRequests = [
  _request(
    'r-01',
    by: marko,
    animal: 'a-01',
    createdAt: DateTime(2026, 10, 18, 10, 15),
    motivation: 'Imamo kuću sa velikim dvorištem i dvoje dece koja obožavaju pse.',
  ),
  _request(
    'r-02',
    by: jelena,
    animal: 'a-01',
    createdAt: DateTime(2026, 10, 20, 18, 40),
    motivation: 'Radim od kuće i mogu Rexu da posvetim mnogo vremena i šetnji.',
  ),
  _request(
    'r-03',
    by: nikola,
    animal: 'a-01',
    createdAt: DateTime(2026, 10, 23, 8, 5),
    motivation: 'Već sam imao psa iste rase i znam kakva mu je briga potrebna.',
  ),
  _request(
    'r-04',
    by: ana,
    animal: 'a-02',
    createdAt: DateTime(2026, 10, 25, 12, 0),
    motivation: 'Luna bi imala društvo našeg starijeg psa i mnogo prostora za igru.',
  ),
  _request(
    'r-05',
    by: milica,
    animal: 'a-03',
    createdAt: DateTime(2026, 10, 26, 16, 30),
    motivation: 'Imamo malo imanje sa ograđenim pašnjakom i još dve koze.',
  ),
  _request(
    'r-06',
    by: ana,
    animal: 'a-04',
    createdAt: DateTime(2026, 10, 1, 9, 0),
    motivation: 'Želela sam Belu, ali smo se predomislili zbog selidbe.',
    status: AdoptionRequestStatus.withdrawn,
  ),
  _request(
    'r-07',
    by: ana,
    animal: 'a-09',
    createdAt: DateTime(2026, 9, 10, 11, 20),
    motivation: 'Bobi bi bio odličan drug za naše dugačke šetnje po Fruškoj gori.',
    status: AdoptionRequestStatus.rejected,
  ),
  _request(
    'r-08',
    by: milica,
    animal: 'a-08',
    createdAt: DateTime(2026, 10, 19, 15, 45),
    motivation: 'Živim sama u stanu i tražim malog psa koji voli da se mazi.',
    status: AdoptionRequestStatus.approved,
  ),
];
