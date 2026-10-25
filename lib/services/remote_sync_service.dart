import 'dart:convert';

import 'package:http/http.dart' as http;

class RemoteSyncService {
  static const String _baseUrl = 'https://signeye.onrender.com';

  Future<void> saveUser(String name, String email) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Remote user save failed: ${response.body}');
    }
  }

  Future<void> saveHistory(String maBien, {required String source}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/history'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'maBien': maBien,
        'source': source,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Remote save failed: ${response.body}');
    }
  }
}
