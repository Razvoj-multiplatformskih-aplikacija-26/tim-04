import 'package:domain/domain.dart';

import 'serbian.dart';

extension DomainErrorMessage on DomainError {
  String get message => switch (this) {
    NameTooShort() => 'Ime mora imati bar ${AnimalName.minLength} znaka.',
    NameTooLong() => 'Ime može imati najviše ${AnimalName.maxLength} znakova.',
    MotivationTooShort(:final length) =>
      'Motivacija mora imati bar ${RequestMotivation.minLength} znakova (sada ima $length).',
    MotivationTooLong() => 'Motivacija može imati najviše ${RequestMotivation.maxLength} znakova.',
    NotAllowed() => 'Nemate dozvolu za ovu radnju.',
    NotFound() => 'Traženi podatak ne postoji.',
    InvalidTransition(:final from, :final to) => 'Prelaz iz „${from.label}“ u „${to.label}“ nije dozvoljen.',
    TooManyActiveRequests() => 'Možete imati najviše $maxActiveRequests aktivna zahteva.',
    AnimalNotAdoptable() => 'Ova životinja trenutno nije spremna za udomljavanje.',
    DuplicateRequest() => 'Već ste poslali zahtev za ovu životinju.',
    WithdrawNotAllowed() => 'Ovaj zahtev više ne može da se povuče.',
    InvalidRequestTransition() => 'Zahtev više nije na čekanju.',
  };
}
