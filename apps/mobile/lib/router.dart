import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'screens/animal_detail_screen.dart';
import 'screens/catalog_screen.dart';
import 'screens/home_shell.dart';
import 'screens/my_requests_screen.dart';
import 'screens/request_detail_screen.dart';
import 'screens/request_form_screen.dart';

GoRouter createRouter() {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const CatalogScreen(),
                routes: [
                  GoRoute(
                    path: 'animals/:id',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => AnimalDetailScreen(id: AnimalId(state.pathParameters['id']!)),
                    routes: [
                      GoRoute(
                        path: 'request',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) =>
                            RequestFormScreen(animalId: AnimalId(state.pathParameters['id']!)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/requests',
                builder: (context, state) => const MyRequestsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) =>
                        RequestDetailScreen(id: AdoptionRequestId(state.pathParameters['id']!)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}