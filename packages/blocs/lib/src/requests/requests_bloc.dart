import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

import '../shelter_repository.dart';

part 'requests_event.dart';
part 'requests_state.dart';

final class AdoptionRequestBloc extends Bloc<AdoptionRequestEvent, AdoptionRequestState> {
  AdoptionRequestBloc({required this.repository, required this.user, required this.clock, required this.newId})
    : super(const RequestsLoading()) {
    on<MyRequestsRequested>((event, emit) => _load(emit));
    on<RequestSubmitted>((event, emit) => _onSubmitted(event, emit));
    on<RequestWithdrawn>((event, emit) => _onWithdrawn(event, emit));
    on<RequestApproved>((event, emit) => _onApproved(event, emit));
    on<RequestRejected>((event, emit) => _onRejected(event, emit));
    on<RequestsNoticeAcknowledged>((event, emit) {
      final current = state;
      if (current is RequestsLoaded && current.notice != null) {
        emit(RequestsLoaded(requests: current.requests));
      }
    });
  }

  final ShelterRepository repository;
  final User user;
  final DateTime Function() clock;
  final String Function() newId;

  List<AdoptionRequest> _requests = const [];

  Future<void> _load(Emitter<AdoptionRequestState> emit) async {
    emit(const RequestsLoading());
    try {
      await _refresh(emit);
    } catch (error) {
      emit(RequestsFailure(error));
    }
  }

  Future<void> _refresh(Emitter<AdoptionRequestState> emit, {RequestsNotice? notice}) async {
    _requests = await repository.requests(applicant: user.role == Role.adopter ? user.id : null);
    emit(RequestsLoaded(requests: _requests, notice: notice));
  }

  Future<void> _onSubmitted(RequestSubmitted event, Emitter<AdoptionRequestState> emit) async {
    try {
      emit(RequestsLoaded(requests: _requests, busy: true));
      final animal = await repository.animal(event.animalId);
      final mine = await repository.requests(applicant: user.id);
      final result = submitRequest(
        id: AdoptionRequestId(newId()),
        user: user,
        animal: animal,
        myRequests: mine,
        motivation: event.motivation,
        now: clock(),
      );
      switch (result) {
        case Failure(:final error):
          emit(RequestsLoaded(requests: _requests, notice: RequestRefused(error)));
        case Success(:final value):
          await repository.saveRequest(value);
          await _refresh(emit, notice: RequestSaved(value));
      }
    } catch (error) {
      emit(RequestsLoaded(requests: _requests, notice: RequestFailed(error)));
    }
  }

  Future<void> _onWithdrawn(RequestWithdrawn event, Emitter<AdoptionRequestState> emit) async {
    try {
      emit(RequestsLoaded(requests: _requests, busy: true));
      final request = _requests.firstWhere((r) => r.id == event.id);
      final result = withdrawRequest(request: request, by: user, now: clock());
      switch (result) {
        case Failure(:final error):
          emit(RequestsLoaded(requests: _requests, notice: RequestRefused(error)));
        case Success(:final value):
          await repository.saveRequest(value);
          await _refresh(emit, notice: RequestSaved(value));
      }
    } catch (error) {
      emit(RequestsLoaded(requests: _requests, notice: RequestFailed(error)));
    }
  }

  Future<void> _onRejected(RequestRejected event, Emitter<AdoptionRequestState> emit) async {
    try {
      emit(RequestsLoaded(requests: _requests, busy: true));
      final request = _requests.firstWhere((r) => r.id == event.id);
      final result = rejectRequest(request: request, by: user);
      switch (result) {
        case Failure(:final error):
          emit(RequestsLoaded(requests: _requests, notice: RequestRefused(error)));
        case Success(:final value):
          await repository.saveRequest(value);
          await _refresh(emit, notice: RequestSaved(value));
      }
    } catch (error) {
      emit(RequestsLoaded(requests: _requests, notice: RequestFailed(error)));
    }
  }

  Future<void> _onApproved(RequestApproved event, Emitter<AdoptionRequestState> emit) async {
    try {
      emit(RequestsLoaded(requests: _requests, busy: true));
      final request = _requests.firstWhere((r) => r.id == event.id);
      final animal = await repository.animal(request.animalId);
      final all = await repository.requests(animal: request.animalId);
      final result = approveRequest(
        animal: animal,
        request: request,
        allRequestsForAnimal: all,
        by: user,
        now: clock(),
      );
      switch (result) {
        case Failure(:final error):
          emit(RequestsLoaded(requests: _requests, notice: RequestRefused(error)));
        case Success(:final value):
          await repository.saveAnimal(value.animal);
          await repository.saveRequest(value.approved);
          for (final rejected in value.rejected) {
            await repository.saveRequest(rejected);
          }
          await _refresh(emit, notice: RequestSaved(value.approved));
      }
    } catch (error) {
      emit(RequestsLoaded(requests: _requests, notice: RequestFailed(error)));
    }
  }
}
