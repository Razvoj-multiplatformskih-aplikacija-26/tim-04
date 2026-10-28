import 'package:domain/domain.dart';

enum AnimalsFilter {
  all,
  received,
  inQuarantine,
  readyForAdoption,
  reserved,
  adopted,
  permanentResident,
  returned;

  bool matches(Animal animal) => switch (this) {
    all => true,
    received => animal.status is Received,
    inQuarantine => animal.status is InQuarantine,
    readyForAdoption => animal.status is ReadyForAdoption,
    reserved => animal.status is Reserved,
    adopted => animal.status is Adopted,
    permanentResident => animal.status is PermanentResident,
    returned => animal.status is Returned,
  };
}
