import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

final class RecordingNotifier implements AdoptionNotifier {
  final approved = <AdoptionRequestId>[];
  final rejected = <AdoptionRequestId>[];

  @override
  Future<void> requestApproved(AdoptionRequest request) async => approved.add(request.id);

  @override
  Future<void> requestRejected(AdoptionRequest request) async => rejected.add(request.id);
}

final class BrokenNotifier implements AdoptionNotifier {
  @override
  Future<void> requestApproved(AdoptionRequest request) => throw Exception('mail server down');

  @override
  Future<void> requestRejected(AdoptionRequest request) => throw Exception('mail server down');
}
