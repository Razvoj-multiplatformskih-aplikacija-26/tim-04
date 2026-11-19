import 'dart:convert';

final class ServerConfig {
  const ServerConfig({
    required this.host,
    required this.demoPassword,
    required this.port,
    required this.databaseUrl,
    required this.corsOrigins,
    required this.notifierApiKey,
    required this.jwtSecret,
    this.sessionTtl = const Duration(hours: 8),
    this.secureCookie = false,
  });

  factory ServerConfig.fromEnvironment(Map<String, String> environment) => ServerConfig(
    host: environment['HOST'] ?? '127.0.0.1',
    port: int.parse(environment['PORT'] ?? '8080'),
    databaseUrl:
        environment['DATABASE_URL'] ??
        (throw StateError('DATABASE_URL is not set. Copy .env.example to .env in the repository root.')),
    demoPassword:
        environment['DEMO_PASSWORD'] ??
        (throw StateError('DEMO_PASSWORD is not set. Copy .env.example to .env in the repository root.')),
    corsOrigins: [
      for (final origin in (environment['CORS_ORIGINS'] ?? 'http://localhost:8081').split(','))
        if (origin.trim().isNotEmpty) origin.trim(),
    ],
    notifierApiKey: environment['NOTIFIER_API_KEY'] ?? 'dev-fake',
    jwtSecret: _jwtSecret(environment['JWT_SECRET']),
    sessionTtl: Duration(minutes: int.parse(environment['SESSION_TTL_MINUTES'] ?? '480')),
    secureCookie: environment['COOKIE_SECURE'] == 'true',
  );

  final String host;
  final int port;
  final String databaseUrl;
  final List<String> corsOrigins;
  final String notifierApiKey;
  final String demoPassword;
  final String jwtSecret;
  final Duration sessionTtl;
  final bool secureCookie;
}

String _jwtSecret(String? secret) => switch (secret) {
  null => throw StateError('JWT_SECRET is not set. Copy .env.example to .env in the repository root.'),
  final secret when utf8.encode(secret).length < 32 => throw StateError('JWT_SECRET must have at least 32 bytes.'),
  final secret => secret,
};
