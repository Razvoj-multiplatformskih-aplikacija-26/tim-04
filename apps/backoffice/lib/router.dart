import 'package:domain/domain.dart';
import 'package:go_router/go_router.dart';

import 'screens/animals/animals_screen.dart';

GoRouter createRouter({String initialLocation = AnimalsScreen.path}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', redirect: (_, _) => AnimalsScreen.path),
      GoRoute(
        path: AnimalsScreen.path,
        builder: (context, state) {
          final selected = state.uri.queryParameters['selected'];
          return AnimalsScreen(selectedId: selected == null ? null : AnimalId(selected));
        },
      ),
    ],
  );
}
