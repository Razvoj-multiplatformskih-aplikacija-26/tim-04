import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

import 'dependencies.dart';
import 'router.dart';

class UtocisteApp extends StatefulWidget {
  const UtocisteApp({super.key, required this.dependencies});

  static const locale = Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');

  final AppDependencies dependencies;

  @override
  State<UtocisteApp> createState() => _UtocisteAppState();
}

class _UtocisteAppState extends State<UtocisteApp> {
  late final SessionBloc _session = SessionBloc(
    restoreSession: widget.dependencies.restoreSession,
    logOut: widget.dependencies.logOut,
    admits: AccessPolicy.canUseMobileApp,
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
    return RepositoryProvider<AppDependencies>.value(
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
                title: 'Utočište',
                logIn: dependencies.logIn,
                reason: reason,
                roleNotAllowedMessage: 'Aplikacija je za udomitelje. Osoblje koristi backoffice.',
                onSignedIn: (user) => _session.add(SessionStarted(user)),
              ),
            ),
            SignedIn(:final user) => _SignedInApp(key: ValueKey(user.id), user: user, dependencies: dependencies),
          },
        ),
      ),
    );
  }
}

class _SignedInApp extends StatefulWidget {
  const _SignedInApp({super.key, required this.user, required this.dependencies});

  final User user;
  final AppDependencies dependencies;

  @override
  State<_SignedInApp> createState() => _SignedInAppState();
}

class _SignedInAppState extends State<_SignedInApp> {
  late final GoRouter _router = createRouter();
  int _nextRequestNumber = 1;

  String _newRequestId() => 'r-m${_nextRequestNumber++}';

  int _nextAnimalNumber = 1;

  String _newAnimalId() => 'a-m${_nextAnimalNumber++}';

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animals = widget.dependencies.animals;
    final requests = widget.dependencies.requests;
    return RepositoryProvider.value(
      value: widget.user,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AnimalsBloc(
              getAnimals: GetAnimals(animals: animals),
              intakeAnimal: IntakeAnimal(animals: animals, clock: const SystemClock(), newId: _newAnimalId),
              startQuarantine: StartQuarantine(animals: animals, clock: const SystemClock()),
              endQuarantine: EndQuarantine(animals: animals, clock: const SystemClock()),
              initialFilter: AnimalsFilter.readyForAdoption,
            )..add(const AnimalsRequested()),
          ),
          BlocProvider(
            create: (_) => AdoptionRequestBloc(
              user: widget.user,
              getRequests: GetRequests(requests: requests),
              submitRequest: SubmitRequest(
                requests: requests,
                animals: animals,
                clock: const SystemClock(),
                newId: _newRequestId,
              ),
              withdrawRequest: WithdrawRequest(requests: requests, clock: const SystemClock()),
              approveRequest: ApproveRequest(
                requests: requests,
                animals: animals,
                clock: const SystemClock(),
                notifier: const NoopNotifier(),
              ),
              rejectRequest: RejectRequest(requests: requests, notifier: const NoopNotifier()),
            )..add(const MyRequestsRequested()),
          ),
        ],
        child: _material(router: _router),
      ),
    );
  }
}

Widget _material({Key? key, Widget? home, GoRouter? router}) {
  const delegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
  if (router != null) {
    return MaterialApp.router(
      key: key,
      title: 'Utočište',
      theme: UtocisteTheme.light(),
      darkTheme: UtocisteTheme.dark(),
      themeMode: ThemeMode.system,
      locale: UtocisteApp.locale,
      supportedLocales: const [UtocisteApp.locale],
      localizationsDelegates: delegates,
      routerConfig: router,
    );
  }
  return MaterialApp(
    key: key,
    title: 'Utočište',
    theme: UtocisteTheme.light(),
    darkTheme: UtocisteTheme.dark(),
    themeMode: ThemeMode.system,
    locale: UtocisteApp.locale,
    supportedLocales: const [UtocisteApp.locale],
    localizationsDelegates: delegates,
    home: home,
  );
}
