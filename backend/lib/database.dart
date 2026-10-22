import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';
import 'dart:typed_data';

class SignEyeDatabase {
  static final SignEyeDatabase _instance = SignEyeDatabase._internal();
  factory SignEyeDatabase() => _instance;
  SignEyeDatabase._internal();

  late PostgreSQLConnection _connection;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    _connection = PostgreSQLConnection(
      Platform.environment['DB_HOST'] ?? '127.0.0.1',
      int.tryParse(Platform.environment['DB_PORT'] ?? '') ?? 5432,
      Platform.environment['DB_NAME'] ?? 'signeye',
      username: Platform.environment['DB_USER'] ?? 'postgres',
      password: Platform.environment['DB_PASSWORD'] ?? '',
      timeZone: 'UTC',
      useSSL: false,
    );

    await _connection.open();
    await _createSchema();
    _initialized = true;
  }

  Future<void> _createSchema() async {
    await _connection.query('''
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    ''');

    await _connection.query('''
      CREATE TABLE IF NOT EXISTS history (
        id SERIAL PRIMARY KEY,
        ma_bien TEXT NOT NULL,
        source TEXT NOT NULL DEFAULT 'search',
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    ''');
  }

  String _hash(String input) => sha256.convert(utf8.encode(input)).toString();
  String _randomToken() {
    final random = Random.secure();
    return base64Url.encode(List<int>.generate(32, (_) => random.nextInt(256)));
  }

  String _passwordHash(String password, String salt) {
    var value = utf8.encode('$salt:$password');
    for (var i = 0; i < 120000; i++) {
      value = Uint8List.fromList(sha256.convert(value).bytes);
    }
    return base64Url.encode(value);
  }

  Future<void> ensureAuthSchema() async {
    await _connection.query(
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash TEXT',
    );
    await _connection.query(
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS password_salt TEXT',
    );
    await _connection.query("""CREATE TABLE IF NOT EXISTS auth_sessions (
      token_hash TEXT PRIMARY KEY, email TEXT NOT NULL REFERENCES users(email),
      expires_at TIMESTAMPTZ NOT NULL)""");
  }

  Future<Map<String, dynamic>?> authenticate(
    String email,
    String password, {
    String? name,
  }) async {
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email) ||
        password.length < 10 ||
        password.length > 256)
      return null;
    if (name != null) {
      if (name.trim().isEmpty || name.length > 120) return null;
      final salt = _randomToken();
      try {
        await _connection.query(
          'INSERT INTO users(name,email,password_hash,password_salt) VALUES (@name,@email,@hash,@salt)',
          substitutionValues: {
            'name': name.trim(),
            'email': email,
            'hash': _passwordHash(password, salt),
            'salt': salt,
          },
        );
      } catch (_) {
        return null;
      }
    } else {
      final rows = await _connection.query(
        'SELECT password_hash,password_salt FROM users WHERE email=@email',
        substitutionValues: {'email': email},
      );
      if (rows.isEmpty || rows.first[0] == null || rows.first[1] == null)
        return null;
      if (_passwordHash(password, rows.first[1] as String) != rows.first[0])
        return null;
    }
    final token = _randomToken();
    await _connection.query(
      "INSERT INTO auth_sessions(token_hash,email,expires_at) VALUES (@hash,@email,NOW()+INTERVAL '7 days')",
      substitutionValues: {'hash': _hash(token), 'email': email},
    );
    return {'token': token, 'email': email};
  }

  Future<String?> sessionEmail(String token) async {
    if (token.isEmpty) return null;
    final rows = await _connection.query(
      'SELECT email FROM auth_sessions WHERE token_hash=@hash AND expires_at>NOW()',
      substitutionValues: {'hash': _hash(token)},
    );
    return rows.isEmpty ? null : rows.first[0] as String;
  }

  Future<void> revokeSession(String token) async {
    await _connection.query(
      'DELETE FROM auth_sessions WHERE token_hash=@hash',
      substitutionValues: {'hash': _hash(token)},
    );
  }

  Future<void> ensurePaymentsSchema() async {
    await _connection.query(
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS pro_expires_at TIMESTAMPTZ',
    );
    await _connection.query('''CREATE TABLE IF NOT EXISTS pro_orders (
      id BIGSERIAL PRIMARY KEY, email TEXT NOT NULL, plan TEXT NOT NULL
      CHECK(plan IN ('month','year')), amount INTEGER NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending'
      CHECK(status IN ('pending','submitted','paid','rejected')),
      transfer_ref TEXT NOT NULL UNIQUE,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      paid_at TIMESTAMPTZ
    )''');
  }

  Future<void> ensureAuditSchema() async {
    await _connection.query("""CREATE TABLE IF NOT EXISTS payment_audit (
      id BIGSERIAL PRIMARY KEY,
      order_id BIGINT NOT NULL REFERENCES pro_orders(id),
      action TEXT NOT NULL CHECK(action IN ('approved','rejected')),
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )""");
  }

  Future<Map<String, dynamic>> createOrder(String email, String plan) async {
    final amount = plan == 'year' ? 399000 : 39000;
    final ref = 'SE${DateTime.now().microsecondsSinceEpoch}';
    final rows = await _connection.query(
      'INSERT INTO pro_orders(email,plan,amount,transfer_ref) VALUES (@email,@plan,@amount,@ref) RETURNING id,transfer_ref,amount,plan,status',
      substitutionValues: {
        'email': email,
        'plan': plan,
        'amount': amount,
        'ref': ref,
      },
    );
    return rows.first.toColumnMap();
  }

  Future<bool> submitOrder(int id, String email) async {
    final rows = await _connection.query(
      "UPDATE pro_orders SET status='submitted' WHERE id=@id AND email=@email AND status='pending' RETURNING id",
      substitutionValues: {'id': id, 'email': email},
    );
    return rows.isNotEmpty;
  }

  Future<bool> rejectOrder(int id) async {
    final result = await _connection.transaction((ctx) async {
      final rows = await ctx.query(
        "UPDATE pro_orders SET status='rejected' WHERE id=@id AND status='submitted' RETURNING id",
        substitutionValues: {'id': id},
      );
      if (rows.isEmpty) return false;
      await ctx.query(
        "INSERT INTO payment_audit(order_id,action) VALUES (@id,'rejected')",
        substitutionValues: {'id': id},
      );
         return true;
  });

  return result == true;
}

  Future<Map<String, dynamic>?> getOrder(int id, String email) async {
    final rows = await _connection.query(
      'SELECT id,plan,amount,status,transfer_ref,created_at,paid_at FROM pro_orders WHERE id=@id AND email=@email',
      substitutionValues: {'id': id, 'email': email},
    );
    if (rows.isEmpty) return null;
    return rows.first.toColumnMap().map(
      (k, v) => MapEntry(k, v is DateTime ? v.toIso8601String() : v),
    );
  }

  Future<bool> confirmOrder(int id) async {
    return await _connection.transaction((ctx) async {
      final rows = await ctx.query(
        "UPDATE pro_orders SET status='paid',paid_at=NOW() WHERE id=@id AND status='submitted' RETURNING email,plan",
        substitutionValues: {'id': id},
      );
      if (rows.isEmpty) return false;
      final email = rows.first[0] as String;
      final plan = rows.first[1] as String;
      await ctx.query(
        'INSERT INTO users(name,email) VALUES (@email,@email) ON CONFLICT(email) DO NOTHING',
        substitutionValues: {'email': email},
      );
      await ctx.query(
        """UPDATE users SET pro_expires_at=
        GREATEST(COALESCE(pro_expires_at,NOW()),NOW()) +
        CASE WHEN @plan='year' THEN INTERVAL '1 year' ELSE INTERVAL '1 month' END
        WHERE email=@email""",
        substitutionValues: {'email': email, 'plan': plan},
      );
      await ctx.query(
        "INSERT INTO payment_audit(order_id,action) VALUES (@id,'approved')",
        substitutionValues: {'id': id},
      );
      return true;
    });
  }

  Future<Map<String, dynamic>> subscription(String email) async {
    final rows = await _connection.query(
      "SELECT pro_expires_at FROM users WHERE email=@email",
      substitutionValues: {'email': email},
    );
    if (rows.isEmpty) return {'isPro': false, 'expiresAt': null};
    final expiry = rows.first[0] as DateTime?;
    return {
      'isPro': expiry != null && expiry.isAfter(DateTime.now().toUtc()),
      'expiresAt': expiry?.toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> paymentStats() async {
    final summary = await _connection.query(
      "SELECT COUNT(DISTINCT email) AS buyers, COUNT(*) AS purchases, COUNT(*) FILTER (WHERE plan='month') AS monthly, COUNT(*) FILTER (WHERE plan='year') AS yearly, COALESCE(SUM(amount),0) AS revenue FROM pro_orders WHERE status='paid'",
    );
    final orders = await _connection.query(
      'SELECT id,email,plan,amount,status,transfer_ref,created_at,paid_at FROM pro_orders ORDER BY created_at DESC LIMIT 200',
    );
    return {
      'summary': summary.first.toColumnMap().map(
        (k, v) => MapEntry(k, v.toString()),
      ),
      'orders': orders
          .map(
            (r) => r.toColumnMap().map(
              (k, v) => MapEntry(k, v is DateTime ? v.toIso8601String() : v),
            ),
          )
          .toList(),
    };
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final result = await _connection.query(
      'SELECT id,name,email,created_at,pro_expires_at FROM users ORDER BY created_at DESC',
    );
    return result.map((row) => row.toColumnMap()).toList();
  }

  Future<void> insertUser({required String name, required String email}) async {
    await _connection.query(
      'INSERT INTO users (name, email) VALUES (@name, @email) ON CONFLICT (email) DO NOTHING',
      substitutionValues: {'name': name, 'email': email},
    );
  }

  Future<void> insertHistory({
    required String maBien,
    required String source,
  }) async {
    await _connection.query(
      'INSERT INTO history (ma_bien, source) VALUES (@maBien, @source)',
      substitutionValues: {'maBien': maBien, 'source': source},
    );
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final result = await _connection.query(
      'SELECT * FROM history ORDER BY created_at DESC LIMIT 50',
    );
    return result.map((row) => row.toColumnMap()).toList();
  }
}
