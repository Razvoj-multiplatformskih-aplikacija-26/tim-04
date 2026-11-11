import 'package:domain/domain.dart';

import 'serbian.dart';

extension DomainErrorMessage on DomainError {
  String get message => switch (this) {
    NameTooShort(:final min) => 'Ime mora imati bar $min znaka.',
    NameTooLong(:final max) => 'Ime može imati najviše $max znakova.',
    MotivationTooShort(:final length, :final min) => 'Motivacija mora imati bar $min znakova (sada ima $length).',
    MotivationTooLong(:final max) => 'Motivacija može imati najviše $max znakova.',
    NotAllowed() => 'Nemate dozvolu za ovu radnju.',
    NotFound() => 'Traženi podatak ne postoji.',
    InvalidTransition(:final from, :final to) => 'Prelaz iz „${from.label}“ u „${to.label}“ nije dozvoljen.',
    TooManyActiveRequests(:final max) => 'Možete imati najviše $max aktivna zahteva.',
    AnimalNotAdoptable() => 'Ova životinja trenutno nije spremna za udomljavanje.',
    DuplicateRequest() => 'Već ste poslali zahtev za ovu životinju.',
    WithdrawNotAllowed() => 'Ovaj zahtev više ne može da se povuče.',
    InvalidRequestTransition() => 'Zahtev više nije na čekanju.',
  };
}
