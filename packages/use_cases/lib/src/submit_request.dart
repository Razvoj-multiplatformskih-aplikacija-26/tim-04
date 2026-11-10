import 'package:domain/domain.dart';

import 'clock.dart';
import 'ports/adoption_request_repository.dart';
import 'ports/animal_repository.dart';

final class SubmitRequest {
  const SubmitRequest({required this.requests, required this.animals, required this.clock, required this.newId});

  final AdoptionRequestRepository requests;
  final AnimalRepository animals;
  final Clock clock;
  final String Function() newId;

  Future<Result<AdoptionRequest>> call({
    required AnimalId animalId,
    required RequestMotivation motivation,
    required User by,
  }) async {
    final animal = await animals.find(animalId);
    if (animal == null) return const Failure(NotFound());
    final mine = await requests.requests(applicant: by.id);
    final result = submitRequest(
      id: AdoptionRequestId(newId()),
      user: by,
      animal: animal,
      myRequests: mine,
      motivation: motivation,
      now: clock.now(),
    );
    return switch (result) {
      Failure(:final error) => Failure(error),
      Success(:final value) => requests.submit(value),
    };
  }
}
