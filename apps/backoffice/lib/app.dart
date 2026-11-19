import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
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
  late final SessionBloc _session = SessionBloc(
    restoreSession: widget.dependencies.restoreSession,
    logOut: widget.dependencies.logOut,
    admits: AccessPolicy.canUseBackoffice,
    expirations: widget.dependencies.sessionExpirations,
  )..add(const SessionRestoreRequested());

  @override
  void dispose() {
    _session.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = widget.dependencies;
    return RepositoryProvider.value(
      value: dependencies,
      child: BlocProvider.value(
        value: _session,
        child: BlocBuilder<SessionBloc, SessionState>(
          builder: (context, session) => switch (session) {
            SessionUnknown() => _material(
              key: const ValueKey('session-unknown'),
              home: const Scaffold(body: LoadingView()),
            ),
            SignedOut(:final reason) => _material(
              key: ValueKey('signed-out ${reason?.name}'),
              home: LoginScreen(
                title: 'Utočište — Backoffice',
                logIn: dependencies.logIn,
                reason: reason,
                roleNotAllowedMessage: 'Backoffice je za osoblje utočišta. Udomitelji koriste mobilnu aplikaciju.',
                onSignedIn: (user) => _session.add(SessionStarted(user)),
              ),
            ),
            SignedIn(:final user) => _SignedInApp(
              key: ValueKey(user.id),
              user: user,
              dependencies: dependencies,
              initialLocation: widget.initialLocation,
            ),
          },
        ),
      ),
    );
  }
}

class _SignedInApp extends StatefulWidget {
  const _SignedInApp({super.key, required this.user, required this.dependencies, required this.initialLocation});

  final User user;
  final BackofficeDependencies dependencies;
  final String initialLocation;

  @override
  State<_SignedInApp> createState() => _SignedInAppState();
}

class _SignedInAppState extends State<_SignedInApp> {
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
      value: widget.user,
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
              user: widget.user,
              getRequests: dependencies.getRequests,
              submitRequest: dependencies.submitRequest,
              withdrawRequest: dependencies.withdrawRequest,
              approveRequest: dependencies.approveRequest,
              rejectRequest: dependencies.rejectRequest,
            )..add(const MyRequestsRequested()),
          ),
        ],
        child: _material(router: _router),
      ),
    );
  }
}

Widget _material({Key? key, Widget? home, GoRouter? router}) {
  const title = 'Utočište — Backoffice';
  const delegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
  if (router != null) {
    return MaterialApp.router(
      key: key,
      title: title,
      debugShowCheckedModeBanner: false,
      theme: UtocisteTheme.light(),
      darkTheme: UtocisteTheme.dark(),
      locale: BackofficeApp.locale,
      supportedLocales: const [BackofficeApp.locale],
      localizationsDelegates: delegates,
      routerConfig: router,
    );
  }
  return MaterialApp(
    key: key,
    title: title,
    debugShowCheckedModeBanner: false,
    theme: UtocisteTheme.light(),
    darkTheme: UtocisteTheme.dark(),
    locale: BackofficeApp.locale,
    supportedLocales: const [BackofficeApp.locale],
    localizationsDelegates: delegates,
    home: home,
  );
}
