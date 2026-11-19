import 'package:blocs/blocs.dart';
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
    final dependencies = widget.dependencies;
    final animals = dependencies.animals;
    final requests = dependencies.requests;
    return RepositoryProvider<AppDependencies>.value(
      value: dependencies,
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
              user: dependencies.user,
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
        child: MaterialApp.router(
          title: 'Utočište',
          theme: UtocisteTheme.light(),
          darkTheme: UtocisteTheme.dark(),
          themeMode: ThemeMode.system,
          locale: UtocisteApp.locale,
          supportedLocales: const [UtocisteApp.locale],
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
