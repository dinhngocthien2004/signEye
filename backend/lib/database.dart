import 'package:postgres/postgres.dart';

class SignEyeDatabase {
  static final SignEyeDatabase _instance = SignEyeDatabase._internal();
  factory SignEyeDatabase() => _instance;
  SignEyeDatabase._internal();

  late PostgreSQLConnection _connection;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    _connection = PostgreSQLConnection(
      '127.0.0.1',
      5432,
      'signeye',
      username: 'postgres',
      password: '12345',
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

  Future<List<Map<String, dynamic>>> getUsers() async {
    final result = await _connection.query(
      'SELECT * FROM users ORDER BY created_at DESC',
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
