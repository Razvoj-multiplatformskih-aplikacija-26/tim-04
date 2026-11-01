import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'dependencies.dart';

void main() {
  usePathUrlStrategy();
  runApp(BackofficeApp(dependencies: BackofficeDependencies.fake()));
}
