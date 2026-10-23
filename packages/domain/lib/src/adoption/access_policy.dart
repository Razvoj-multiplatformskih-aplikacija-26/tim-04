import '../user.dart';
import 'adoption_request.dart';

abstract final class AccessPolicy {
  static bool canSubmitRequest(User user) => user.role == Role.adopter;

  static bool canWithdraw(User user, AdoptionRequest request) => user.id == request.applicantId;

  static bool canDecide(User user) => user.role == Role.coordinator || user.role == Role.seniorVolunteer;

  static bool canIntake(User user) => user.role == Role.coordinator;

  static bool canEndQuarantine(User user) => user.role == Role.coordinator || user.role == Role.veterinarian;

  static bool canChangeAnimalStatus(User user) => user.role == Role.coordinator;
}
