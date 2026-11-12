import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

import 'animal_mapping.dart';

extension DomainErrorMapping on DomainError {
  ProblemDto toProblem() => switch (this) {
    NameTooShort(:final min) => ProblemDto(
      status: 422,
      code: ErrorCodes.nameTooShort,
      title: 'Name too short',
      min: min,
    ),
    NameTooLong(:final max) => ProblemDto(status: 422, code: ErrorCodes.nameTooLong, title: 'Name too long', max: max),
    MotivationTooShort(:final length, :final min) => ProblemDto(
      status: 422,
      code: ErrorCodes.motivationTooShort,
      title: 'Motivation too short',
      value: length,
      min: min,
    ),
    MotivationTooLong(:final max) => ProblemDto(
      status: 422,
      code: ErrorCodes.motivationTooLong,
      title: 'Motivation too long',
      max: max,
    ),
    TooManyActiveRequests(:final max) => ProblemDto(
      status: 409,
      code: ErrorCodes.tooManyActiveRequests,
      title: 'Too many active requests',
      max: max,
    ),
    AnimalNotAdoptable() => const ProblemDto(
      status: 409,
      code: ErrorCodes.animalNotAdoptable,
      title: 'Animal not adoptable',
    ),
    DuplicateRequest() => const ProblemDto(status: 409, code: ErrorCodes.duplicateRequest, title: 'Duplicate request'),
    WithdrawNotAllowed() => const ProblemDto(
      status: 409,
      code: ErrorCodes.withdrawNotAllowed,
      title: 'Withdraw not allowed',
    ),
    InvalidRequestTransition() => const ProblemDto(
      status: 409,
      code: ErrorCodes.invalidRequestTransition,
      title: 'Invalid request transition',
    ),
    InvalidTransition(:final from, :final to) => ProblemDto(
      status: 409,
      code: ErrorCodes.invalidTransition,
      title: 'Invalid transition',
      from: from.toDto(),
      to: to.toDto(),
    ),
    NotAllowed() => const ProblemDto(status: 403, code: ErrorCodes.notAllowed, title: 'Not allowed'),
    NotFound() => const ProblemDto(status: 404, code: ErrorCodes.notFound, title: 'Not found'),
  };
}

extension ProblemMapping on ProblemDto {
  DomainError? toDomainError() => switch (this) {
    ProblemDto(code: ErrorCodes.nameTooShort, :final min?) => NameTooShort(min: min),
    ProblemDto(code: ErrorCodes.nameTooLong, :final max?) => NameTooLong(max: max),
    ProblemDto(code: ErrorCodes.motivationTooShort, :final value?, :final min?) => MotivationTooShort(value, min: min),
    ProblemDto(code: ErrorCodes.motivationTooLong, :final max?) => MotivationTooLong(max: max),
    ProblemDto(code: ErrorCodes.tooManyActiveRequests, :final max?) => TooManyActiveRequests(max: max),
    ProblemDto(code: ErrorCodes.animalNotAdoptable) => const AnimalNotAdoptable(),
    ProblemDto(code: ErrorCodes.duplicateRequest) => const DuplicateRequest(),
    ProblemDto(code: ErrorCodes.withdrawNotAllowed) => const WithdrawNotAllowed(),
    ProblemDto(code: ErrorCodes.invalidRequestTransition) => const InvalidRequestTransition(),
    ProblemDto(code: ErrorCodes.invalidTransition, :final from?, :final to?) => InvalidTransition(
      from: from.toDomain(),
      to: to.toDomain(),
    ),
    ProblemDto(code: ErrorCodes.notAllowed) => const NotAllowed(),
    ProblemDto(code: ErrorCodes.notFound) => const NotFound(),
    _ => null,
  };
}
