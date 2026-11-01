import 'package:domain/domain.dart';
import 'package:intl/intl.dart';

const serbianLatin = 'sr_Latn';

String pluralize(int count, {required String one, required String few, required String many}) {
  final lastDigit = count % 10;
  final lastTwoDigits = count % 100;
  if (lastDigit == 1 && lastTwoDigits != 11) return one;
  if (lastDigit >= 2 && lastDigit <= 4 && (lastTwoDigits < 12 || lastTwoDigits > 14)) return few;
  return many;
}

String yearsLabel(int count) => '$count ${pluralize(count, one: 'godina', few: 'godine', many: 'godina')}';

String monthsLabel(int count) => '$count ${pluralize(count, one: 'mesec', few: 'meseca', many: 'meseci')}';

String ageLabel(int months) {
  final years = months ~/ 12;
  final rest = months % 12;
  if (years == 0) return monthsLabel(rest);
  if (rest == 0) return yearsLabel(years);
  return '${yearsLabel(years)} i ${monthsLabel(rest)}';
}

final _longDate = DateFormat('d. MMMM y.', serbianLatin);

String formatLongDate(DateTime date) => _longDate.format(date);

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
