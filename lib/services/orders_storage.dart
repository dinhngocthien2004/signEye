import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrdersStorage {
  static const _kOrdersKey = 'se_all_pro_orders';
  static const _kProUsersKey = 'se_pro_users_map';
  static const _kCustomApiUrlKey = 'se_custom_api_url';

  /// Lấy URL máy chủ Backend
  static Future<String> getApiBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getString(_kCustomApiUrlKey);
    if (custom != null && custom.trim().isNotEmpty) {
      return custom.trim();
    }
    const envUrl = String.fromEnvironment('SIGN_EYE_API_URL', defaultValue: '');
    if (envUrl.isNotEmpty) return envUrl;

    // Nếu đang chạy trên web qua HTTPS (ví dụ Vercel), không dùng http://127.0.0.1 vì trình duyệt sẽ chặn Mixed Content
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.startsWith('https://')) {
        // Trả về rỗng để báo hiệu chế độ Vercel Standalone
        return '';
      }
    }
    return 'http://127.0.0.1:8000';
  }

  /// Cấu hình URL máy chủ Backend tùy chỉnh
  static Future<void> setApiBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url.trim().isEmpty) {
      await prefs.remove(_kCustomApiUrlKey);
    } else {
      String clean = url.trim();
      if (clean.endsWith('/')) clean = clean.substring(0, clean.length - 1);
      await prefs.setString(_kCustomApiUrlKey, clean);
    }
  }

  /// Tải danh sách đơn hàng được lưu trên thiết bị / trình duyệt
  static Future<List<Map<String, dynamic>>> loadLocalOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kOrdersKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(raw);
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (_) {}
    }

    // Danh sách mẫu ban đầu để giao diện Admin trên Vercel không bị rỗng
    final initialOrders = [
      {
        'id': 101,
        'email': 'thien123@gmail.com',
        'name': 'Đinh Ngọc Thiện',
        'plan': 'month',
        'amount': 39000,
        'status': 'submitted',
        'transfer_ref': 'SE51664108',
        'created_at': DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String(),
        'paid_at': null,
      },
      {
        'id': 100,
        'email': 'ngocthien@signeye.vn',
        'name': 'Ngọc Thiện',
        'plan': 'year',
        'amount': 399000,
        'status': 'submitted',
        'transfer_ref': 'SE48237993',
        'created_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        'paid_at': null,
      },
      {
        'id': 99,
        'email': 'user_demo@signeye.vn',
        'name': 'Người dùng Demo',
        'plan': 'month',
        'amount': 39000,
        'status': 'paid',
        'transfer_ref': 'SE47381150',
        'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'paid_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
    ];
    await saveLocalOrders(initialOrders);
    return initialOrders;
  }

  /// Lưu danh sách đơn hàng
  static Future<void> saveLocalOrders(List<Map<String, dynamic>> orders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kOrdersKey, jsonEncode(orders));
  }

  /// Thêm đơn hàng mới khi người dùng tạo mã QR
  static Future<void> addOrder(Map<String, dynamic> order) async {
    final orders = await loadLocalOrders();
    orders.removeWhere((o) => o['id'].toString() == order['id'].toString());
    orders.insert(0, order);
    await saveLocalOrders(orders);
  }

  /// Admin duyệt Pro cho đơn hàng
  static Future<bool> approveOrder(dynamic id) async {
    final orders = await loadLocalOrders();
    bool found = false;
    for (var o in orders) {
      if (o['id'].toString() == id.toString()) {
        o['status'] = 'paid';
        o['paid_at'] = DateTime.now().toIso8601String();
        found = true;
        final email = (o['email'] ?? '').toString();
        final plan = (o['plan'] ?? 'month').toString();
        await grantProUser(email, plan: plan);
        break;
      }
    }
    if (found) {
      await saveLocalOrders(orders);
    }
    return found;
  }

  /// Admin từ chối đơn hàng
  static Future<bool> rejectOrder(dynamic id) async {
    final orders = await loadLocalOrders();
    bool found = false;
    for (var o in orders) {
      if (o['id'].toString() == id.toString()) {
        o['status'] = 'rejected';
        found = true;
        break;
      }
    }
    if (found) {
      await saveLocalOrders(orders);
    }
    return found;
  }

  /// Kích hoạt quyền Pro trực tiếp cho Username hoặc Email
  static Future<void> grantProUser(String usernameOrEmail, {String plan = 'month'}) async {
    final clean = usernameOrEmail.trim().toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kProUsersKey);
    Map<String, dynamic> proMap = {};
    if (raw != null && raw.isNotEmpty) {
      try {
        proMap = Map<String, dynamic>.from(jsonDecode(raw));
      } catch (_) {}
    }
    final duration = plan == 'year' ? const Duration(days: 365) : const Duration(days: 30);
    final expiry = DateTime.now().add(duration).toIso8601String();
    proMap[clean] = {'isPro': true, 'expiresAt': expiry, 'plan': plan};
    if (!clean.contains('@')) {
      proMap['$clean@signeye.vn'] = {'isPro': true, 'expiresAt': expiry, 'plan': plan};
    }
    await prefs.setString(_kProUsersKey, jsonEncode(proMap));
  }

  /// Kiểm tra tài khoản có được cấp Pro hay không
  static Future<Map<String, dynamic>?> checkUserPro(String usernameOrEmail) async {
    final clean = usernameOrEmail.trim().toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kProUsersKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final proMap = Map<String, dynamic>.from(jsonDecode(raw));
      final info = proMap[clean] ?? proMap['$clean@signeye.vn'];
      if (info != null && info is Map) {
        return Map<String, dynamic>.from(info);
      }
    } catch (_) {}
    return null;
  }

  /// Tính toán số liệu thống kê đơn hàng
  static Map<String, dynamic> calculateSummary(List<dynamic> orders) {
    int purchases = 0;
    int monthly = 0;
    int yearly = 0;
    int revenue = 0;
    final Set<String> buyers = {};

    for (var o in orders) {
      if (o['status'] == 'paid') {
        purchases++;
        final plan = o['plan']?.toString() ?? 'month';
        if (plan == 'year') {
          yearly++;
        } else {
          monthly++;
        }
        final amt = int.tryParse(o['amount']?.toString() ?? '0') ?? 0;
        revenue += amt;
        final email = o['email']?.toString() ?? '';
        if (email.isNotEmpty) buyers.add(email.toLowerCase());
      }
    }
    return {
      'buyers': buyers.length.toString(),
      'purchases': purchases.toString(),
      'monthly': monthly.toString(),
      'yearly': yearly.toString(),
      'revenue': revenue.toString(),
    };
  }
}
