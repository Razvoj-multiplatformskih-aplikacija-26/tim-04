import 'dart:io';

import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:postgres/postgres.dart' hide Result;
import 'package:server/server.dart' show SessionHandlers, serverEnvironment;

Future<Pool<void>> freshTestDatabase(String name) async {
  final url = Uri.parse(serverEnvironment()['DATABASE_URL']!);
  final admin = Pool<void>.withUrl(url.toString());
  await admin.execute('DROP DATABASE IF EXISTS $name WITH (FORCE)');
  await admin.execute('CREATE DATABASE $name');
  await admin.close();
  final database = Pool<void>.withUrl(url.replace(path: '/$name').toString());
  await database.execute(File('db/schema.sql').readAsStringSync(), queryMode: QueryMode.simple);
  return database;
}

const testSecret = 'test-only-secret-0123456789abcdef0123456789';

Future<Map<String, String>> tokensFor(Session database, SessionHandlers sessions) async {
  final rows = await database.execute('SELECT id, name, role FROM users');
  return {
    for (final [id, name, role] in rows)
      id! as String: sessions.tokenFor(
        User(id: UserId(id as String), name: name! as String, role: roleFromDto(role! as String)),
      ),
  };
}
