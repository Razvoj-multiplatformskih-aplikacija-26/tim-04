import 'dart:io';

import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

final class FakeNotifier implements AdoptionNotifier {
  const FakeNotifier({required this.apiKey});

  final String apiKey;

  @override
  Future<void> requestApproved(AdoptionRequest request) async => _send('approved', request);

  @override
  Future<void> requestRejected(AdoptionRequest request) async => _send('rejected', request);

  void _send(String what, AdoptionRequest request) =>
      stdout.writeln('notifier: request ${request.id.value} $what, to ${request.applicantId.value}');
}
