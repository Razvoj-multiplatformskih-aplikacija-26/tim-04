import 'package:meta/meta.dart';

import '../identifiers.dart';

sealed class AnimalStatus {
  const AnimalStatus();

  bool get isAdoptable => this is ReadyForAdoption;

  bool get isFinal => switch (this) {
    Adopted() || PermanentResident() => true,
    Received() || InQuarantine() || ReadyForAdoption() || Reserved() || Returned() => false,
  };
}

@immutable
final class Received extends AnimalStatus {
  const Received({required this.receivedBy, required this.at});

  final UserId receivedBy;
  final DateTime at;

  @override
  bool operator ==(Object other) => other is Received && other.receivedBy == receivedBy && other.at == at;

  @override
  int get hashCode => Object.hash(Received, receivedBy, at);

  @override
  String toString() => 'Received(by $receivedBy at $at)';
}

@immutable
final class InQuarantine extends AnimalStatus {
  const InQuarantine({required this.since, required this.until});

  final DateTime since;
  final DateTime until;

  @override
  bool operator ==(Object other) => other is InQuarantine && other.since == since && other.until == until;

  @override
  int get hashCode => Object.hash(InQuarantine, since, until);

  @override
  String toString() => 'InQuarantine($since - $until)';
}

@immutable
final class ReadyForAdoption extends AnimalStatus {
  const ReadyForAdoption({required this.since});

  final DateTime since;

  @override
  bool operator ==(Object other) => other is ReadyForAdoption && other.since == since;

  @override
  int get hashCode => Object.hash(ReadyForAdoption, since);

  @override
  String toString() => 'ReadyForAdoption(since $since)';
}

@immutable
final class Reserved extends AnimalStatus {
  const Reserved({required this.requestId, required this.approvedBy, required this.at});

  final AdoptionRequestId requestId;
  final UserId approvedBy;
  final DateTime at;

  @override
  bool operator ==(Object other) =>
      other is Reserved && other.requestId == requestId && other.approvedBy == approvedBy && other.at == at;

  @override
  int get hashCode => Object.hash(Reserved, requestId, approvedBy, at);

  @override
  String toString() => 'Reserved(request $requestId by $approvedBy at $at)';
}

@immutable
final class Adopted extends AnimalStatus {
  const Adopted({required this.adopterId, required this.at});

  final UserId adopterId;
  final DateTime at;

  @override
  bool operator ==(Object other) => other is Adopted && other.adopterId == adopterId && other.at == at;

  @override
  int get hashCode => Object.hash(Adopted, adopterId, at);

  @override
  String toString() => 'Adopted(by $adopterId at $at)';
}

@immutable
final class PermanentResident extends AnimalStatus {
  const PermanentResident({required this.reason});

  final String reason;

  @override
  bool operator ==(Object other) => other is PermanentResident && other.reason == reason;

  @override
  int get hashCode => Object.hash(PermanentResident, reason);

  @override
  String toString() => 'PermanentResident("$reason")';
}

@immutable
final class Returned extends AnimalStatus {
  const Returned({required this.reason, required this.at});

  final String reason;
  final DateTime at;

  @override
  bool operator ==(Object other) => other is Returned && other.reason == reason && other.at == at;

  @override
  int get hashCode => Object.hash(Returned, reason, at);

  @override
  String toString() => 'Returned("$reason" at $at)';
}

bool canTransition(AnimalStatus from, AnimalStatus to) => switch ((from, to)) {
  (Received(), InQuarantine()) => true,
  (InQuarantine(), ReadyForAdoption() || PermanentResident()) => true,
  (ReadyForAdoption(), Reserved() || PermanentResident()) => true,
  (Reserved(), Adopted() || ReadyForAdoption()) => true,
  (Adopted(), Returned()) => true,
  (Returned(), InQuarantine() || ReadyForAdoption() || PermanentResident()) => true,
  _ => false,
};
