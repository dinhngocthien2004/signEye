import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import 'database.dart';

Future<void> main() async {
  final db = SignEyeDatabase();
  await db.init();

  final app = Router()
    ..get('/health', (_) {
      return Response.ok(
        jsonEncode({'status': 'ok', 'database': 'postgresql'}),
      );
    })
    ..get('/users', (_) async {
      final users = await db.getUsers();
      return Response.ok(
        jsonEncode(users),
        headers: {'Content-Type': 'application/json'},
      );
    })
    ..post('/users', (Request request) async {
      final payload =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final name = (payload['name'] ?? '').toString();
      final email = (payload['email'] ?? '').toString();

      if (name.isEmpty || email.isEmpty) {
        return Response(
          400,
          body: jsonEncode({'error': 'name and email are required'}),
        );
      }

      await db.insertUser(name: name, email: email);
      return Response.ok(
        jsonEncode({'status': 'ok'}),
        headers: {'Content-Type': 'application/json'},
      );
    })
    ..get('/history', (_) async {
      final rows = await db.getHistory();
      return Response.ok(
        jsonEncode(rows),
        headers: {'Content-Type': 'application/json'},
      );
    })
    ..post('/history', (Request request) async {
      final payload =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final maBien = (payload['maBien'] ?? '').toString();
      final source = (payload['source'] ?? 'search').toString();

      if (maBien.isEmpty) {
        return Response(400, body: jsonEncode({'error': 'maBien is required'}));
      }

      await db.insertHistory(maBien: maBien, source: source);
      return Response.ok(
        jsonEncode({'status': 'ok'}),
        headers: {'Content-Type': 'application/json'},
      );
    });

  final server = await serve(app, '0.0.0.0', 8080);
  print('Serving at http://${server.address.host}:${server.port}');
}
