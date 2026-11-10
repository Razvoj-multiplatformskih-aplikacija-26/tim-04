import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

part 'requests_event.dart';
part 'requests_state.dart';

final class AdoptionRequestBloc extends Bloc<AdoptionRequestEvent, AdoptionRequestState> {
  AdoptionRequestBloc({
    required this.user,
    required this.getRequests,
    required this.submitRequest,
    required this.withdrawRequest,
    required this.approveRequest,
    required this.rejectRequest,
  }) : super(const RequestsLoading()) {
    on<MyRequestsRequested>((event, emit) => _load(emit));
    on<RequestSubmitted>(
      (event, emit) => _act(
        emit,
        () => submitRequest(animalId: event.animalId, motivation: event.motivation, by: user),
        (request) => request,
      ),
    );
    on<RequestWithdrawn>(
      (event, emit) => _act(emit, () => withdrawRequest(id: event.id, by: user), (request) => request),
    );
    on<RequestRejected>((event, emit) => _act(emit, () => rejectRequest(id: event.id, by: user), (request) => request));
    on<RequestApproved>(
      (event, emit) => _act(emit, () => approveRequest(id: event.id, by: user), (outcome) => outcome.approved),
    );
    on<RequestsNoticeAcknowledged>((event, emit) {
      final current = state;
      if (current is RequestsLoaded && current.notice != null) {
        emit(RequestsLoaded(requests: current.requests));
      }
    });
  }

  final User user;
  final GetRequests getRequests;
  final SubmitRequest submitRequest;
  final WithdrawRequest withdrawRequest;
  final ApproveRequest approveRequest;
  final RejectRequest rejectRequest;

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
    _requests = await getRequests(user);
    emit(RequestsLoaded(requests: _requests, notice: notice));
  }

  Future<void> _act<T>(
    Emitter<AdoptionRequestState> emit,
    Future<Result<T>> Function() action,
    AdoptionRequest Function(T value) saved,
  ) async {
    try {
      emit(RequestsLoaded(requests: _requests, busy: true));
      switch (await action()) {
        case Failure(:final error):
          emit(RequestsLoaded(requests: _requests, notice: RequestRefused(error)));
        case Success(:final value):
          await _refresh(emit, notice: RequestSaved(saved(value)));
      }
    } catch (error) {
      emit(RequestsLoaded(requests: _requests, notice: RequestFailed(error)));
    }
  }
}
