import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PaymentApi {
  // Live Backend on Render: https://signeye.onrender.com
  static const _configuredBase = String.fromEnvironment('PAYMENT_API_URL');
  static String get base => _configuredBase.isNotEmpty ? _configuredBase : 'https://signeye.onrender.com';
  static String? token;
  static Map<String,String> get authHeaders => {'Authorization':'Bearer ${token ?? ''}'};
  static Future<Map<String,dynamic>> authenticate(String email,String password,{String? name}) async => _read(await http.post(Uri.parse('$base/auth/${name==null?'login':'register'}'),headers:{'Content-Type':'application/json'},body:jsonEncode({'email':email,'password':password,if(name!=null)'name':name})));
  static Future<Map<String,dynamic>> scanAllowance() async => _read(await http.get(Uri.parse('$base/features/scan/allowance'),headers:authHeaders));
  static Future<Map<String,dynamic>> consumeScan() async => _read(await http.post(Uri.parse('$base/features/scan/consume'),headers:authHeaders));
  static Future<Map<String,dynamic>> me() async => _read(await http.get(Uri.parse('$base/me'),headers:authHeaders));
  static Future<void> logout() async {if(token!=null)await http.post(Uri.parse('$base/auth/logout'),headers:authHeaders);token=null;}
  static Future<Map<String, dynamic>> config() async => _read(await http.get(Uri.parse('$base/config')));
  static Future<Map<String, dynamic>> create(String plan) async => _read(await http.post(Uri.parse('$base/orders'),headers:{...authHeaders,'Content-Type':'application/json'},body:jsonEncode({'plan':plan})));
  static Future<List<dynamic>> orders() async { final r=await http.get(Uri.parse('$base/orders'),headers:authHeaders); if(r.statusCode>=400) throw Exception('HTTP ${r.statusCode}'); return jsonDecode(r.body) as List<dynamic>; }
  static Future<Map<String, dynamic>> status(String id) async => _read(await http.get(Uri.parse('$base/orders/$id'),headers:authHeaders));
  static Map<String,dynamic> _read(http.Response response) {
    final data = jsonDecode(response.body) as Map<String,dynamic>;
    if(response.statusCode >= 400) throw Exception(data['detail'] ?? 'HTTP ${response.statusCode}');
    return data;
  }
}
