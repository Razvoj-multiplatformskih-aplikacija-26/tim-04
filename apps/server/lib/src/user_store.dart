import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart';

final class UserStore {
  const UserStore(this._database);

  final Pool<void> _database;

  Future<User?> user(UserId id) async {
    final rows = await _database.execute(
      Sql.named('SELECT name, role FROM users WHERE id = @id'),
      parameters: {'id': id.value},
    );
    if (rows.isEmpty) return null;
    final [name, role] = rows.single;
    return User(id: id, name: name! as String, role: roleFromDb(role! as String));
  }
}

Role roleFromDb(String value) => switch (value) {
  'adopter' => Role.adopter,
  'volunteer' => Role.volunteer,
  'senior-volunteer' => Role.seniorVolunteer,
  'veterinarian' => Role.veterinarian,
  'coordinator' => Role.coordinator,
  _ => throw StateError('Unknown role $value'),
};
