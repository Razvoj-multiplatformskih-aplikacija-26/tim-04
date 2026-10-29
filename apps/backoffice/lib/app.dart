import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'dependencies.dart';
import 'screens/animals_screen.dart';

class BackofficeApp extends StatelessWidget {
  const BackofficeApp({super.key, required this.dependencies});

  static const locale = Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Cyrl');

  final BackofficeDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: dependencies,
      child: BlocProvider(
        create: (_) => AnimalsBloc(repository: dependencies.repository)..add(const AnimalsRequested()),
        child: MaterialApp(
          title: 'Utočište — Backoffice',
          theme: ThemeData(colorSchemeSeed: const Color(0xFF2E7D5B)),
          darkTheme: ThemeData(colorSchemeSeed: const Color(0xFF2E7D5B), brightness: Brightness.dark),
          locale: locale,
          supportedLocales: const [locale],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const AnimalsScreen(),
        ),
      ),
    );
  }
}
