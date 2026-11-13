import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:relic/relic.dart' hide Result;

import 'http.dart';
import 'user_store.dart';

final currentUser = ContextProperty<User>('user');

const devUserHeader = 'X-Dev-User';

const _signInRequired = ProblemDto(status: 401, code: ErrorCodes.signInRequired, title: 'Sign in required');

final class DevSignIn {
  const DevSignIn(this._users);

  final UserStore _users;

  Handler signedIn(Handler handler) => (Request request) async {
    final id = request.headers[devUserHeader]?.firstOrNull;
    if (id == null || id.isEmpty) return problemResponse(_signInRequired);
    final user = await _users.user(UserId(id));
    if (user == null) return problemResponse(_signInRequired);
    currentUser[request] = user;
    return handler(request);
  };
}
