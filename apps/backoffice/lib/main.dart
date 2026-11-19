import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'dependencies.dart';
import 'server_address.dart';

void main() {
  usePathUrlStrategy();
  runApp(BackofficeApp(dependencies: BackofficeDependencies.server(baseUri: serverAddress())));
}
