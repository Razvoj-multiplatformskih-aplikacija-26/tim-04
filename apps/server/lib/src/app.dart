import 'package:api_contract/api_contract.dart';
import 'package:relic/relic.dart';

import 'cors.dart';
import 'dev_sign_in.dart';
import 'http.dart';

Handler buildHandler(DevSignIn signIn, {required List<String> corsOrigins}) {
  final router = RelicRouter()
    ..get(ApiPaths.health, (request) => Response.ok(body: Body.fromString('ok')))
    ..fallback = respondWith((request) => problemResponse(notFoundRoute));
  return const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(allowOrigins(corsOrigins))
      .addMiddleware(handleErrors())
      .addHandler(router.asHandler);
}

const notFoundRoute = ProblemDto(status: 404, code: ErrorCodes.notFound, title: 'No such route');
