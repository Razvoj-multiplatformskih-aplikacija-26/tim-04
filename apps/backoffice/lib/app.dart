import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import 'dependencies.dart';
import 'router.dart';
import 'screens/animals/animals_screen.dart';

class BackofficeApp extends StatefulWidget {
  const BackofficeApp({super.key, required this.dependencies, this.initialLocation = AnimalsScreen.path});

  static const locale = Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');

  final BackofficeDependencies dependencies;

  final String initialLocation;

  @override
  State<BackofficeApp> createState() => _BackofficeAppState();
}

class _BackofficeAppState extends State<BackofficeApp> {
  late final GoRouter _router = createRouter(initialLocation: widget.initialLocation);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = widget.dependencies;
    return RepositoryProvider.value(
      value: dependencies,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AnimalsBloc(
              getAnimals: dependencies.getAnimals,
              intakeAnimal: dependencies.intakeAnimal,
              startQuarantine: dependencies.startQuarantine,
              endQuarantine: dependencies.endQuarantine,
            )..add(const AnimalsRequested()),
          ),
          BlocProvider(
            create: (_) => AdoptionRequestBloc(
              repository: dependencies.repository,
              user: dependencies.user,
              clock: dependencies.clock.now,
              newId: dependencies.newId,
            )..add(const MyRequestsRequested()),
          ),
        ],
        child: MaterialApp.router(
          title: 'Utočište — Backoffice',
          debugShowCheckedModeBanner: false,
          theme: UtocisteTheme.light(),
          darkTheme: UtocisteTheme.dark(),
          locale: BackofficeApp.locale,
          supportedLocales: const [BackofficeApp.locale],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: _router,
        ),
      ),
    );
  }
}
