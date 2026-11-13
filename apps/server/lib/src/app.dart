import 'package:api_contract/api_contract.dart';
import 'package:relic/relic.dart';

import 'animal_handlers.dart';
import 'cors.dart';
import 'dev_sign_in.dart';
import 'http.dart';

Handler buildHandler({required AnimalHandlers animals, required DevSignIn signIn, required List<String> corsOrigins}) {
  final signedIn = signIn.signedIn;
  final router = RelicRouter()
    ..get(ApiPaths.health, (request) => Response.ok(body: Body.fromString('ok')))
    ..get(ApiPaths.animals, signedIn(animals.animals))
    ..post(ApiPaths.animals, signedIn(animals.intake))
    ..get(ApiPaths.animal(':id'), signedIn(animals.find))
    ..post(ApiPaths.quarantine(':id'), signedIn(animals.startQuarantine))
    ..delete(ApiPaths.quarantine(':id'), signedIn(animals.endQuarantine))
    ..fallback = respondWith((request) => problemResponse(notFoundRoute));
  return const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(allowOrigins(corsOrigins))
      .addMiddleware(handleErrors())
      .addHandler(router.asHandler);
}

const notFoundRoute = ProblemDto(status: 404, code: ErrorCodes.notFound, title: 'No such route');
