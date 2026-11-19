import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'dependencies.dart';
import 'server_address.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('sr_Latn');
  runApp(UtocisteApp(dependencies: AppDependencies.server(baseUri: serverAddress())));
}
