import 'package:api_contract/api_contract.dart';
import 'package:relic/relic.dart';

import 'animal_handlers.dart';
import 'cors.dart';
import 'dev_sign_in.dart';
import 'http.dart';
import 'request_handlers.dart';

Handler buildHandler({
  required AnimalHandlers animals,
  required RequestHandlers requests,
  required DevSignIn signIn,
  required List<String> corsOrigins,
}) {
  final signedIn = signIn.signedIn;
  final router = RelicRouter()
    ..get(ApiPaths.health, (request) => Response.ok(body: Body.fromString('ok')))
    ..get(ApiPaths.animals, signedIn(animals.animals))
    ..post(ApiPaths.animals, signedIn(animals.intake))
    ..get(ApiPaths.animal(':id'), signedIn(animals.find))
    ..post(ApiPaths.quarantine(':id'), signedIn(animals.startQuarantine))
    ..delete(ApiPaths.quarantine(':id'), signedIn(animals.endQuarantine))
    ..get(ApiPaths.adoptionRequests, signedIn(requests.requests))
    ..post(ApiPaths.adoptionRequests, signedIn(requests.submit))
    ..post(ApiPaths.withdrawal(':id'), signedIn(requests.withdraw))
    ..post(ApiPaths.approval(':id'), signedIn(requests.approve))
    ..post(ApiPaths.rejection(':id'), signedIn(requests.reject))
    ..fallback = respondWith((request) => problemResponse(notFoundRoute));
  return const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(allowOrigins(corsOrigins))
      .addMiddleware(handleErrors())
      .addHandler(router.asHandler);
}

const notFoundRoute = ProblemDto(status: 404, code: ErrorCodes.notFound, title: 'No such route');
