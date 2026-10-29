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
  const RequestsLoaded({required this.requests, this.error});

  final List<AdoptionRequest> requests;
  final DomainError? error;

  bool get isEmpty => requests.isEmpty;

  @override
  List<Object?> get props => [requests, error];
}
