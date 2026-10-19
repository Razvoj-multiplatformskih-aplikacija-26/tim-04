import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  final request = AdoptionRequest(
    id: const AdoptionRequestId('r-1'),
    animalId: const AnimalId('a-1'),
    applicantId: const UserId('u-ana'),
    motivation: RequestMotivation.parse('Imamo veliko dvorište i mnogo vremena.').valueOrNull!,
    createdAt: DateTime(2026, 10, 1),
  );

  group('AdoptionRequestStatus', () {
    test('pending and approved requests are active', () {
      expect(AdoptionRequestStatus.pending.isActive, isTrue);
      expect(AdoptionRequestStatus.approved.isActive, isTrue);
    });

    test('rejected and withdrawn requests are not active', () {
      expect(AdoptionRequestStatus.rejected.isActive, isFalse);
      expect(AdoptionRequestStatus.withdrawn.isActive, isFalse);
    });
  });

  group('AdoptionRequest', () {
    test('a new request is pending', () {
      expect(request.status, AdoptionRequestStatus.pending);
      expect(request.isActive, isTrue);
    });

    test('copyWith changes only the status', () {
      final withdrawn = request.copyWith(status: AdoptionRequestStatus.withdrawn);

      expect(withdrawn.status, AdoptionRequestStatus.withdrawn);
      expect(withdrawn.id, request.id);
      expect(withdrawn.isActive, isFalse);
      expect(request.copyWith(), request);
    });
  });
}
