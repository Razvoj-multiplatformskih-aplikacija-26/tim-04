import 'package:api_client/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'data/secure_token_store.dart';
import 'dependencies.dart';
import 'server_address.dart';

void main() {
  usePathUrlStrategy();
  runApp(
    BackofficeApp(
      dependencies: BackofficeDependencies.server(
        baseUri: serverAddress(),
        tokens: kIsWeb ? MemoryTokenStore() : const SecureTokenStore(),
      ),
    ),
  );
}
