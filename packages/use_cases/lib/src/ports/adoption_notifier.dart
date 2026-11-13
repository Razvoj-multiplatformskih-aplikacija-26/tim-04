import 'package:domain/domain.dart';

abstract interface class AdoptionNotifier {
  Future<void> requestApproved(AdoptionRequest request);

  Future<void> requestRejected(AdoptionRequest request);
}

final class NoopNotifier implements AdoptionNotifier {
  const NoopNotifier();

  @override
  Future<void> requestApproved(AdoptionRequest request) async {}

  @override
  Future<void> requestRejected(AdoptionRequest request) async {}
}
