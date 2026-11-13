import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:server/server.dart';

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
