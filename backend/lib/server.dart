import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import 'database.dart';

Future<void> main() async {
  final db = SignEyeDatabase();
  await db.init();
  await db.ensurePaymentsSchema();
  await db.ensureAuthSchema();
  await db.ensureAuditSchema();

  final app = Router()
    ..get('/health', (_) {
      return Response.ok(
        jsonEncode({'status': 'ok'}),
      );
    })
    ..get('/admin', (_) => Response.ok(File('web/admin.html').readAsStringSync(), headers: {'Content-Type':'text/html; charset=utf-8','Cache-Control':'no-store','X-Content-Type-Options':'nosniff','Referrer-Policy':'no-referrer','Content-Security-Policy':"default-src 'self'; style-src 'unsafe-inline'; script-src 'unsafe-inline'; connect-src 'self'; base-uri 'none'; frame-ancestors 'none'"}))
    ..post('/auth/register', (Request request) async {
      final data=await _readJson(request);
      if(data==null) return Response(400);
      final result=await db.authenticate((data['email']??'').toString().trim().toLowerCase(),(data['password']??'').toString(),name:(data['name']??'').toString());
      return result==null?Response(400,body:'Không thể đăng ký'):Response.ok(jsonEncode(result),headers:{'Content-Type':'application/json'});
    })
    ..post('/auth/login', (Request request) async {
      final data=await _readJson(request);
      if(data==null) return Response(400);
      final result=await db.authenticate((data['email']??'').toString().trim().toLowerCase(),(data['password']??'').toString());
      return result==null?Response(401,body:'Sai thông tin đăng nhập'):Response.ok(jsonEncode(result),headers:{'Content-Type':'application/json'});
    })
    ..post('/auth/logout', (Request request) async {
      final token=_bearer(request); if(await db.sessionEmail(token)==null) return Response(401);
      await db.revokeSession(token); return Response.ok('{}');
    })
    ..get('/users', (Request request) async {
      if(!_isAdmin(request)) return Response.forbidden('Unauthorized');
      final users = await db.getUsers();
      return Response.ok(
        jsonEncode(users),
        headers: {'Content-Type': 'application/json'},
      );
    })
    ..post('/users', (Request request) async {
      if(!_isAdmin(request)) return Response.forbidden('Unauthorized');
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
    ..post('/payments/orders', (Request request) async {
      try {
        final data=jsonDecode(await request.readAsString()) as Map<String,dynamic>;
        final email=await db.sessionEmail(_bearer(request));
        if(email==null) return Response(401);
        final plan=(data['plan']??'').toString();
        if(!email.contains('@') || !['month','year'].contains(plan)) return Response(400,body:'Invalid email or plan');
        final order=await db.createOrder(email,plan);
        return Response.ok(jsonEncode(order),headers:{'Content-Type':'application/json'});
      } catch (_) { return Response(400,body:'Invalid request'); }
    })
    ..post('/payments/orders/<id>/submit', (Request request,String id) async {
      final data=await _readJson(request);
      if(data==null) return Response(400,body:'Invalid request');
      final email=await db.sessionEmail(_bearer(request));
      if(email==null) return Response(401);
      final parsed=int.tryParse(id);
      if(parsed==null || email.isEmpty) return Response(400);
      final changed=await db.submitOrder(parsed,email);
      return changed?Response.ok(jsonEncode({'status':'submitted'}),headers:{'Content-Type':'application/json'}):Response(409,body:'Đơn không hợp lệ hoặc đã gửi');
    })
    ..get('/payments/subscription', (Request request) async {
      final email=await db.sessionEmail(_bearer(request));
      if(email==null) return Response(401);
      if(email.isEmpty) return Response(400);
      return Response.ok(jsonEncode(await db.subscription(email)),headers:{'Content-Type':'application/json'});
    })
    ..get('/payments/orders/<id>', (Request request,String id) async {
      final email=await db.sessionEmail(_bearer(request));
      if(email==null) return Response(401);
      final order=await db.getOrder(int.tryParse(id)??-1,email.trim().toLowerCase());
      return order==null ? Response.notFound('Not found') : Response.ok(jsonEncode(order),headers:{'Content-Type':'application/json'});
    })
    ..get('/admin/payments', (Request request) async {
      if(!_isAdmin(request)) return Response.forbidden('Unauthorized');
      return Response.ok(jsonEncode(await db.paymentStats()),headers:{'Content-Type':'application/json'});
    })
    ..post('/admin/payments/<id>/confirm', (Request request,String id) async {
      if(!_isAdmin(request)) return Response.forbidden('Unauthorized');
      final parsed=int.tryParse(id);
      if(parsed==null) return Response(400);
      final changed = await db.confirmOrder(parsed);
      if (!changed) return Response(409,body:'Đơn không ở trạng thái chờ');
      return Response.ok(jsonEncode({'status':'ok'}),headers:{'Content-Type':'application/json'});
    })
    ..post('/admin/payments/<id>/reject', (Request request,String id) async {
      if(!_isAdmin(request)) return Response.forbidden('Unauthorized');
      final parsed=int.tryParse(id);
      if(parsed==null) return Response(400);
      final changed=await db.rejectOrder(parsed);
      return changed?Response.ok(jsonEncode({'status':'rejected'}),headers:{'Content-Type':'application/json'}):Response(409,body:'Đơn không ở trạng thái chờ duyệt');
    })
    ..get('/history', (Request request) async {
      if(!_isAdmin(request)) return Response.forbidden('Unauthorized');
      final rows = await db.getHistory();
      return Response.ok(
        jsonEncode(rows),
        headers: {'Content-Type': 'application/json'},
      );
    })
    ..post('/history', (Request request) async {
      if(await db.sessionEmail(_bearer(request))==null) return Response(401);
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

  final server = await serve(app, '0.0.0.0', int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080);
  print('Serving at http://${server.address.host}:${server.port}');
}

// Configure ADMIN_API_KEY in the server environment. Never embed it in Flutter.
bool _isAdmin(Request request) {
  final key=Platform.environment['ADMIN_API_KEY'];
  if (key == null || key.length < 24) return false;
  final supplied = request.headers['x-admin-key'] ?? '';
  if (supplied.length != key.length) return false;
  var diff = 0;
  for (var i=0;i<key.length;i++) { diff |= key.codeUnitAt(i) ^ supplied.codeUnitAt(i); }
  return diff == 0;
}

Future<Map<String,dynamic>?> _readJson(Request request) async {
  try {return jsonDecode(await request.readAsString()) as Map<String,dynamic>;} catch (_) {return null;}
}

String _bearer(Request request) { final h=request.headers['authorization']??''; return h.startsWith('Bearer ')?h.substring(7):''; }
