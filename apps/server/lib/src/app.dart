import 'package:api_contract/api_contract.dart';
import 'package:relic/relic.dart';

import 'animal_handlers.dart';
import 'cors.dart';
import 'http.dart';
import 'request_handlers.dart';
import 'sessions.dart';

Handler buildHandler({
  required AnimalHandlers animals,
  required RequestHandlers requests,
  required SessionHandlers sessions,
  required List<String> corsOrigins,
}) {
  final signedIn = sessions.signedIn;
  final router = RelicRouter()
    ..get(ApiPaths.health, (request) => Response.ok(body: Body.fromString('ok')))
    ..post(ApiPaths.sessions, sessions.logIn)
    ..get(ApiPaths.currentSession, signedIn(sessions.current))
    ..delete(ApiPaths.currentSession, signedIn(sessions.logOut))
    ..get(ApiPaths.animals, signedIn(animals.animals))
    ..get(ApiPaths.animal(':id'), signedIn(animals.find))
    ..post(ApiPaths.animals, signedIn(animals.intake))
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
