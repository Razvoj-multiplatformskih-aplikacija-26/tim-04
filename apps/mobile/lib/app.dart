import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import 'data/seed.dart';
import 'router.dart';

class UtocisteApp extends StatefulWidget {
  const UtocisteApp({super.key, required this.repository});

  static const locale = Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn');

  final ShelterRepository repository;

  @override
  State<UtocisteApp> createState() => _UtocisteAppState();
}

class _UtocisteAppState extends State<UtocisteApp> {
  late final GoRouter _router = createRouter();
  int _nextRequestNumber = 1;

  String _newRequestId() => 'r-m${_nextRequestNumber++}';

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = widget.repository;
    return RepositoryProvider<ShelterRepository>.value(
      value: repository,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) =>
                AnimalsBloc(repository: repository, initialFilter: AnimalsFilter.readyForAdoption)
                  ..add(const AnimalsRequested()),
          ),
          BlocProvider(
            create: (_) => AdoptionRequestBloc(
              repository: repository,
              user: currentUser,
              clock: DateTime.now,
              newId: _newRequestId,
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
