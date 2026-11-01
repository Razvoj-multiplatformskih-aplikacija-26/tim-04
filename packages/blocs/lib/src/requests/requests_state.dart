part of 'requests_bloc.dart';

sealed class AdoptionRequestState extends Equatable {
  const AdoptionRequestState();

  @override
  List<Object?> get props => [];
}

final class RequestsLoading extends AdoptionRequestState {
  const RequestsLoading();
}

final class RequestsFailure extends AdoptionRequestState {
  const RequestsFailure(this.cause);

  final Object cause;
  @override
  List<Object?> get props => [cause];
}

final class RequestsLoaded extends AdoptionRequestState {
  const RequestsLoaded({required this.requests, this.busy = false, this.notice});

  final List<AdoptionRequest> requests;
  final bool busy;
  final RequestsNotice? notice;

  bool get isEmpty => requests.isEmpty;

  @override
  List<Object?> get props => [requests, busy, notice];
}

sealed class RequestsNotice extends Equatable {
  const RequestsNotice();

  @override
  List<Object?> get props => [];
}

final class RequestSaved extends RequestsNotice {
  const RequestSaved(this.request);

  final AdoptionRequest request;

  @override
  List<Object?> get props => [request];
}

final class RequestRefused extends RequestsNotice {
  const RequestRefused(this.error);

  final DomainError error;

  @override
  List<Object?> get props => [error];
}

final class RequestFailed extends RequestsNotice {
  const RequestFailed(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];
}
