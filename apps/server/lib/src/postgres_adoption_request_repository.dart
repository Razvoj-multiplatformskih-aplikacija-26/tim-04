import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart' hide Result;
import 'package:use_cases/use_cases.dart';

const _columns = 'id, animal_id, applicant_id, motivation, created_at, status';

final class PostgresAdoptionRequestRepository implements AdoptionRequestRepository {
  const PostgresAdoptionRequestRepository(this._database);

  final Pool<void> _database;

  @override
  Future<List<AdoptionRequest>> requests({UserId? applicant, AnimalId? animal}) async {
    final rows = await _database.execute(
      Sql.named(
        'SELECT $_columns FROM adoption_requests '
        'WHERE (@applicant::text IS NULL OR applicant_id = @applicant) '
        'AND (@animal::text IS NULL OR animal_id = @animal) '
        'ORDER BY created_at',
      ),
      parameters: {'applicant': applicant?.value, 'animal': animal?.value},
    );
    return [for (final row in rows) _fromRow(row)];
  }

  @override
  Future<AdoptionRequest?> find(AdoptionRequestId id) async {
    try {
      final rows = await _database.execute(
        Sql.named('SELECT $_columns FROM adoption_requests WHERE id = @id::uuid'),
        parameters: {'id': id.value},
      );
      return rows.isEmpty ? null : _fromRow(rows.single);
    } on ServerException catch (error) {
      if (error.code == '22P02') return null;
      rethrow;
    }
  }

  @override
  Future<Result<AdoptionRequest>> save(AdoptionRequest request, {required AdoptionRequestStatus from}) async {
    final result = await _database.execute(
      Sql.named('UPDATE adoption_requests SET status = @to WHERE id = @id::uuid AND status = @from'),
      parameters: {'id': request.id.value, 'to': request.status.toDto(), 'from': from.toDto()},
    );
    if (result.affectedRows == 1) return Success(request);
    if (await find(request.id) == null) return const Failure(NotFound());
    return const Failure(InvalidRequestTransition());
  }

  AdoptionRequest _fromRow(ResultRow row) {
    final [id, animalId, applicantId, motivation, createdAt, status] = row;
    return AdoptionRequest(
      id: AdoptionRequestId(id! as String),
      animalId: AnimalId(animalId! as String),
      applicantId: UserId(applicantId! as String),
      motivation:
          RequestMotivation.parse(motivation! as String).valueOrNull ??
          (throw StateError('Invalid motivation in request $id')),
      createdAt: createdAt! as DateTime,
      status: requestStatusFromDto(status! as String),
    );
  }

  @override
  Future<Result<AdoptionRequest>> submit(AdoptionRequest request) async {
    final applicant = {'applicant': request.applicantId.value};
    try {
      await _database.runTx((tx) async {
        await tx.execute(Sql.named('SELECT id FROM users WHERE id = @applicant FOR UPDATE'), parameters: applicant);
        final animal = await tx.execute(
          Sql.named('SELECT status FROM animals WHERE id = @animal FOR SHARE'),
          parameters: {'animal': request.animalId.value},
        );
        if (animal.isEmpty) throw const _Refused(NotFound());
        if (animal.single.single != 'ready-for-adoption') throw const _Refused(AnimalNotAdoptable());
        final active = await tx.execute(
          Sql.named(
            'SELECT count(*) FROM adoption_requests '
            "WHERE applicant_id = @applicant AND status IN ('pending', 'approved')",
          ),
          parameters: applicant,
        );
        if ((active.single.single! as int) >= maxActiveRequests) {
          throw const _Refused(TooManyActiveRequests(max: maxActiveRequests));
        }
        await tx.execute(
          Sql.named(
            'INSERT INTO adoption_requests ($_columns) '
            'VALUES (@id::uuid, @animal, @applicant, @motivation, @createdAt, @status)',
          ),
          parameters: {
            ...applicant,
            'animal': request.animalId.value,
            'id': request.id.value,
            'motivation': request.motivation.text,
            'createdAt': request.createdAt,
            'status': request.status.toDto(),
          },
        );
      });
      return Success(request);
    } on _Refused catch (refused) {
      return Failure(refused.error);
    } on ServerException catch (error) {
      if (error.code == '23505') return const Failure(DuplicateRequest());
      rethrow;
    }
  }

  @override
  Future<Result<ApprovalOutcome>> approve(ApprovalOutcome outcome) async {
    final status = outcome.animal.status;
    if (status is! Reserved) return const Failure(AnimalNotAdoptable());
    final animal = outcome.animal.id.value;
    final approved = outcome.approved.id.value;
    try {
      await _database.runTx((tx) async {
        final reserved = await tx.execute(
          Sql.named(
            "UPDATE animals SET status = 'reserved', reserved_request = @request::uuid, "
            'status_since = @at, status_by = @by, status_until = NULL, adopter_id = NULL, status_reason = NULL '
            "WHERE id = @animal AND status = 'ready-for-adoption'",
          ),
          parameters: {'animal': animal, 'request': approved, 'at': status.at, 'by': status.approvedBy.value},
        );
        if (reserved.affectedRows != 1) throw const _Refused(AnimalNotAdoptable());
        final accepted = await tx.execute(
          Sql.named(
            "UPDATE adoption_requests SET status = 'approved' WHERE id = @approved::uuid AND status = 'pending'",
          ),
          parameters: {'approved': approved},
        );
        if (accepted.affectedRows != 1) throw const _Refused(InvalidRequestTransition());
        final rejected = await tx.execute(
          Sql.named(
            "UPDATE adoption_requests SET status = 'rejected' "
            "WHERE animal_id = @animal AND status = 'pending' AND id <> @approved::uuid",
          ),
          parameters: {'animal': animal, 'approved': approved},
        );
        if (rejected.affectedRows != outcome.rejected.length) throw const _Refused(InvalidRequestTransition());
      });
      return Success(outcome);
    } on _Refused catch (refused) {
      return Failure(refused.error);
    } on ServerException catch (error) {
      if (error.code == '23505') return const Failure(InvalidRequestTransition());
      rethrow;
    }
  }
}

final class _Refused implements Exception {
  const _Refused(this.error);

  final DomainError error;
}
