part of 'requests_bloc.dart';

sealed class AdoptionRequestEvent {
  const AdoptionRequestEvent();
}

final class MyRequestsRequested extends AdoptionRequestEvent {
  const MyRequestsRequested();
}

final class RequestSubmitted extends AdoptionRequestEvent {
  const RequestSubmitted(this.animalId, this.motivation);

  final AnimalId animalId;
  final RequestMotivation motivation;
}

final class RequestWithdrawn extends AdoptionRequestEvent {
  const RequestWithdrawn(this.id);

  final AdoptionRequestId id;
}

final class RequestApproved extends AdoptionRequestEvent {
  const RequestApproved(this.id);

  final AdoptionRequestId id;
}

final class RequestRejected extends AdoptionRequestEvent {
  const RequestRejected(this.id);

  final AdoptionRequestId id;
}

final class RequestsNoticeAcknowledged extends AdoptionRequestEvent {
  const RequestsNoticeAcknowledged();
}
