import 'package:domain/domain.dart';

extension AnimalStatusLabel on AnimalStatus {
  String get label => switch (this) {
    Received() => 'Primljena',
    InQuarantine() => 'U karantinu',
    ReadyForAdoption() => 'Spremna za udomljavanje',
    Reserved() => 'Rezervisana',
    Adopted() => 'Udomljena',
    PermanentResident() => 'Stalni stanar',
    Returned() => 'Vraćena',
  };
}

extension SpeciesLabel on Species {
  String get label => switch (this) {
    Species.dog => 'Pas',
    Species.cow => 'Krava',
    Species.goat => 'Koza',
    Species.horse => 'Konj',
  };
}

extension AdoptionRequestStatusLabel on AdoptionRequestStatus {
  String get label => switch (this) {
    AdoptionRequestStatus.pending => 'Na čekanju',
    AdoptionRequestStatus.approved => 'Odobren',
    AdoptionRequestStatus.rejected => 'Odbijen',
    AdoptionRequestStatus.withdrawn => 'Povučen',
  };
}

extension RoleLabel on Role {
  String get label => switch (this) {
    Role.adopter => 'Udomitelj',
    Role.volunteer => 'Volonter',
    Role.seniorVolunteer => 'Stariji volonter',
    Role.veterinarian => 'Veterinar',
    Role.coordinator => 'Koordinator',
  };
}
