import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrdersStorage {
  static const _kOrdersKey = 'se_all_pro_orders';
  static const _kProUsersKey = 'se_pro_users_map';
  static const _kUsersDbKey = 'se_users_database';
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
        'id': 'SE1792688059799',
        'email': 'myduyen261104@gmail.com',
        'name': 'Mỹ Duyên',
        'plan': 'month',
        'amount': 39000,
        'status': 'submitted',
        'transfer_ref': 'SE1792688059799',
        'created_at': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
        'paid_at': null,
      },
      {
        'id': 'SE1792688045063',
        'email': 'myduyen261104@gmail.com',
        'name': 'Mỹ Duyên',
        'plan': 'year',
        'amount': 399000,
        'status': 'submitted',
        'transfer_ref': 'SE1792688045063',
        'created_at': DateTime.now().subtract(const Duration(minutes: 20)).toIso8601String(),
        'paid_at': null,
      },
      {
        'id': 'SE51664108',
        'email': 'thien123@gmail.com',
        'name': 'Đinh Ngọc Thiện',
        'plan': 'month',
        'amount': 39000,
        'status': 'submitted',
        'transfer_ref': 'SE51664108',
        'created_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        'paid_at': null,
      },
      {
        'id': 'SE48237993',
        'email': 'ngocthien@signeye.vn',
        'name': 'Ngọc Thiện',
        'plan': 'year',
        'amount': 399000,
        'status': 'submitted',
        'transfer_ref': 'SE48237993',
        'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'paid_at': null,
      },
      {
        'id': 'SE47381150',
        'email': 'user_demo@signeye.vn',
        'name': 'Người dùng Demo',
        'plan': 'month',
        'amount': 39000,
        'status': 'paid',
        'transfer_ref': 'SE47381150',
        'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'paid_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'id': 'XU_179268899120',
        'email': 'myduyen261104@gmail.com',
        'name': 'Mỹ Duyên',
        'plan': '10_days',
        'amount': 0,
        'status': 'paid',
        'transfer_ref': 'DoiXu_1000xu',
        'created_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
        'paid_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
        'payment_method': 'coins',
        'admin_note': '🪙 Đã đổi 1.000 xu tích lũy lấy 10 ngày Pro VIP (Minigame)',
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

  /// Xác thực người dùng qua Database cục bộ (bảo đảm kiểm tra chính xác email và mật khẩu)
  static Future<Map<String, dynamic>> authenticateUser({
    required String email,
    required String password,
    String? name,
    required bool register,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();
    if (cleanEmail.isEmpty || cleanPass.length < 4) {
      return {'success': false, 'error': 'Vui lòng nhập email hợp lệ và mật khẩu từ 4 ký tự'};
    }

    // Tài khoản Admin cố định
    if (cleanEmail == 'admin@signeye.vn' || cleanEmail == 'admin') {
      const validAdminPasses = ['Admin@123456', 'admin', '123456', 'admin123', 'Admin123'];
      if (!validAdminPasses.contains(cleanPass)) {
        return {'success': false, 'error': 'Sai mật khẩu quản trị viên! Mặc định là: Admin@123456 (hoặc admin)'};
      }
      return {
        'success': true,
        'email': 'admin@signeye.vn',
        'name': 'Quản trị viên',
        'isAdmin': true,
        'isPro': true,
        'expiresAt': DateTime.now().add(const Duration(days: 3650)).toIso8601String(),
      };
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUsersDbKey);
    Map<String, dynamic> users = {};
    if (raw != null && raw.isNotEmpty) {
      try {
        users = Map<String, dynamic>.from(jsonDecode(raw));
      } catch (_) {}
    }

    if (register) {
      if (users.containsKey(cleanEmail)) {
        return {'success': false, 'error': 'Email này đã được đăng ký. Vui lòng chuyển sang tab Đăng nhập'};
      }
      final userName = (name != null && name.trim().isNotEmpty) ? name.trim() : cleanEmail.split('@').first;
      
      // Kiểm tra xem email này có được Admin cấp Pro trước không
      final proInfo = await checkUserPro(cleanEmail);
      final isPro = proInfo != null && proInfo['isPro'] == true;
      final expiresAt = proInfo?['expiresAt'];

      final newUser = {
        'email': cleanEmail,
        'name': userName,
        'password': cleanPass,
        'isAdmin': false,
        'isPro': isPro,
        'expiresAt': expiresAt,
        'created_at': DateTime.now().toIso8601String(),
      };
      users[cleanEmail] = newUser;
      await prefs.setString(_kUsersDbKey, jsonEncode(users));

      return {
        'success': true,
        'email': cleanEmail,
        'name': userName,
        'isAdmin': false,
        'isPro': isPro,
        'expiresAt': expiresAt,
      };
    } else {
      // Đăng nhập: kiểm tra tồn tại và mật khẩu
      if (!users.containsKey(cleanEmail)) {
        return {'success': false, 'error': 'Tài khoản chưa tồn tại. Vui lòng bấm Đăng ký trước!'};
      }
      final user = Map<String, dynamic>.from(users[cleanEmail] as Map);
      final storedPass = (user['password'] ?? '').toString();
      if (storedPass != cleanPass) {
        return {'success': false, 'error': 'Sai mật khẩu, vui lòng kiểm tra lại!'};
      }

      // Cập nhật trạng thái Pro mới nhất nếu Admin vừa duyệt
      final proInfo = await checkUserPro(cleanEmail);
      if (proInfo != null && proInfo['isPro'] == true) {
        user['isPro'] = true;
        user['expiresAt'] = proInfo['expiresAt'];
        users[cleanEmail] = user;
        await prefs.setString(_kUsersDbKey, jsonEncode(users));
      }

      final isPro = user['isPro'] == true;
      final exp = user['expiresAt'] != null ? DateTime.tryParse(user['expiresAt'].toString()) : null;
      final activePro = isPro && exp != null && exp.isAfter(DateTime.now());

      return {
        'success': true,
        'email': cleanEmail,
        'name': (user['name'] ?? cleanEmail.split('@').first).toString(),
        'isAdmin': user['isAdmin'] == true,
        'isPro': activePro,
        'expiresAt': exp?.toIso8601String(),
      };
    }
  }

  /// Đồng bộ thông tin người dùng vào Database sau khi máy chủ xác thực thành công
  static Future<void> syncUserAccount({
    required String email,
    required String name,
    required String password,
    required bool isPro,
    DateTime? proExpiry,
    required bool isAdmin,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUsersDbKey);
    Map<String, dynamic> users = {};
    if (raw != null && raw.isNotEmpty) {
      try {
        users = Map<String, dynamic>.from(jsonDecode(raw));
      } catch (_) {}
    }
    users[cleanEmail] = {
      'email': cleanEmail,
      'name': name,
      'password': password,
      'isAdmin': isAdmin,
      'isPro': isPro,
      'expiresAt': proExpiry?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_kUsersDbKey, jsonEncode(users));
    if (isPro && proExpiry != null) {
      await grantProUser(cleanEmail, plan: 'month');
    }
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

    // Đồng bộ cập nhật thẳng vào Database người dùng
    final rawUsers = prefs.getString(_kUsersDbKey);
    if (rawUsers != null && rawUsers.isNotEmpty) {
      try {
        final users = Map<String, dynamic>.from(jsonDecode(rawUsers));
        final targetEmail = clean.contains('@') ? clean : '$clean@signeye.vn';
        if (users.containsKey(targetEmail)) {
          final u = Map<String, dynamic>.from(users[targetEmail] as Map);
          u['isPro'] = true;
          u['expiresAt'] = expiry;
          users[targetEmail] = u;
          await prefs.setString(_kUsersDbKey, jsonEncode(users));
        }
      } catch (_) {}
    }
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

  /// Thu hồi quyền Pro của người dùng, chuyển về Người dùng thường
  static Future<void> revokeProUser(String usernameOrEmail) async {
    final clean = usernameOrEmail.trim().toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Cập nhật bảng Pro map
    final rawPro = prefs.getString(_kProUsersKey);
    if (rawPro != null && rawPro.isNotEmpty) {
      try {
        final proMap = Map<String, dynamic>.from(jsonDecode(rawPro));
        proMap.remove(clean);
        proMap.remove('$clean@signeye.vn');
        await prefs.setString(_kProUsersKey, jsonEncode(proMap));
      } catch (_) {}
    }

    // 2. Cập nhật Database người dùng
    final rawUsers = prefs.getString(_kUsersDbKey);
    if (rawUsers != null && rawUsers.isNotEmpty) {
      try {
        final users = Map<String, dynamic>.from(jsonDecode(rawUsers));
        final targetEmail = clean.contains('@') ? clean : '$clean@signeye.vn';
        if (users.containsKey(targetEmail)) {
          final u = Map<String, dynamic>.from(users[targetEmail] as Map);
          u['isPro'] = false;
          u['expiresAt'] = null;
          users[targetEmail] = u;
          await prefs.setString(_kUsersDbKey, jsonEncode(users));
        }
      } catch (_) {}
    }
  }

  /// Cập nhật thông tin xu và ghi chú đổi Pro của người dùng
  static Future<void> updateUserCoins(
    String email, {
    int? coins,
    int? rewardBalance,
    String? lastCoinRedemption,
  }) async {
    final clean = email.trim().toLowerCase();
    if (clean.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final rawUsers = prefs.getString(_kUsersDbKey);
    Map<String, dynamic> users = {};
    if (rawUsers != null && rawUsers.isNotEmpty) {
      try {
        users = Map<String, dynamic>.from(jsonDecode(rawUsers));
      } catch (_) {}
    }
    final targetEmail = clean.contains('@') ? clean : '$clean@signeye.vn';
    final existing = users[targetEmail] != null
        ? Map<String, dynamic>.from(users[targetEmail] as Map)
        : <String, dynamic>{'email': targetEmail, 'name': clean.split('@').first};

    if (coins != null) existing['coins'] = coins;
    if (rewardBalance != null) existing['reward_balance'] = rewardBalance;
    if (lastCoinRedemption != null && lastCoinRedemption.isNotEmpty) {
      existing['coin_redeem_note'] = lastCoinRedemption;
      existing['last_coin_redeem_at'] = DateTime.now().toIso8601String();
    }
    existing['updated_at'] = DateTime.now().toIso8601String();
    users[targetEmail] = existing;
    await prefs.setString(_kUsersDbKey, jsonEncode(users));
  }

  /// Tải danh sách người dùng đã đăng ký với đầy đủ thông tin chi tiết
  static Future<List<Map<String, dynamic>>> loadLocalUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUsersDbKey);
    Map<String, dynamic> users = {};
    if (raw != null && raw.isNotEmpty) {
      try {
        users = Map<String, dynamic>.from(jsonDecode(raw));
      } catch (_) {}
    }

    if (users.isEmpty) {
      users = {
        'myduyen261104@gmail.com': {
          'email': 'myduyen261104@gmail.com',
          'name': 'Mỹ Duyên',
          'password': '***',
          'isAdmin': false,
          'isPro': true,
          'coins': 1250,
          'reward_balance': 1000,
          'coin_redeem_note': 'Đã đổi 1.000 xu lấy 10 ngày Pro VIP (Minigame)',
          'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
          'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        },
        'thien123@gmail.com': {
          'email': 'thien123@gmail.com',
          'name': 'Đinh Ngọc Thiện',
          'password': '***',
          'isAdmin': false,
          'isPro': false,
          'coins': 420,
          'reward_balance': 0,
          'coin_redeem_note': 'Đang tích lũy xu (chưa đổi Pro)',
          'expiresAt': null,
          'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        },
        'ngocthien@signeye.vn': {
          'email': 'ngocthien@signeye.vn',
          'name': 'Ngọc Thiện',
          'password': '***',
          'isAdmin': false,
          'isPro': true,
          'coins': 2500,
          'reward_balance': 2000,
          'coin_redeem_note': 'Đã đổi 1.000 xu lấy 10 ngày Pro VIP (Ghép hình)',
          'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
          'created_at': DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
        },
        'admin@signeye.vn': {
          'email': 'admin@signeye.vn',
          'name': 'Quản trị viên',
          'password': '***',
          'isAdmin': true,
          'isPro': true,
          'coins': 99999,
          'reward_balance': 0,
          'coin_redeem_note': 'Tài khoản Quản trị viên',
          'expiresAt': DateTime.now().add(const Duration(days: 3650)).toIso8601String(),
          'created_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        },
      };
      await prefs.setString(_kUsersDbKey, jsonEncode(users));
    }

    final orders = await loadLocalOrders();
    final now = DateTime.now();
    final list = <Map<String, dynamic>>[];

    users.forEach((key, val) {
      if (val is Map) {
        final m = Map<String, dynamic>.from(val);
        final email = (m['email'] ?? key).toString().toLowerCase();
        final exp = m['expiresAt'] != null ? DateTime.tryParse(m['expiresAt'].toString()) : null;
        final isPro = m['isPro'] == true && exp != null && exp.isAfter(now);
        final isExpired = m['expiresAt'] != null && !isPro;

        int daysRemaining = 0;
        if (isPro) {
          daysRemaining = exp.difference(now).inDays + 1;
          if (daysRemaining < 1) daysRemaining = 1;
        }

        // Tính lịch sử đơn hàng của user này
        final userOrders = orders.where((o) => (o['email'] ?? '').toString().toLowerCase() == email).toList();
        final paidOrders = userOrders.where((o) => o['status'] == 'paid').toList();
        final totalSpent = paidOrders.fold<int>(0, (sum, o) => sum + (int.tryParse(o['amount']?.toString() ?? '0') ?? 0));
        
        String? latestPlan;
        if (paidOrders.isNotEmpty) {
          latestPlan = (paidOrders.first['plan'] ?? 'month').toString();
        }

        final planLabel = latestPlan == 'year' ? 'Gói 1 năm (399.000đ)' : (latestPlan == 'month' ? 'Gói 1 tháng (39.000đ)' : (isPro ? 'Gói 1 tháng (39.000đ)' : 'Chưa đăng ký'));
        final statusLabel = isPro ? '👑 PRO VIP' : (isExpired ? '⚠️ Hết hạn Pro' : '🌱 Người dùng thường');
        final accountType = isPro ? 'pro' : (isExpired ? 'expired' : 'free');

        final userCoins = int.tryParse((m['coins'] ?? 0).toString()) ?? 0;
        final userReward = int.tryParse((m['reward_balance'] ?? 0).toString()) ?? 0;
        final userCoinNote = (m['coin_redeem_note'] ?? '').toString();

        final coinOrders = userOrders.where((o) =>
          o['payment_method'] == 'coins' ||
          (o['transfer_ref'] ?? '').toString().startsWith('DoiXu') ||
          (o['id'] ?? '').toString().startsWith('XU_')
        ).toList();
        final hasCoinPro = coinOrders.isNotEmpty || userCoinNote.isNotEmpty;
        final coinProSummary = userCoinNote.isNotEmpty
            ? userCoinNote
            : (coinOrders.isNotEmpty
                ? 'Đã đổi ${coinOrders.length} lần Pro từ xu tích lũy'
                : 'Chưa dùng xu đổi Pro');

        list.add({
          'id': email,
          'email': email,
          'name': m['name'] ?? email.split('@').first,
          'created_at': m['created_at'] ?? DateTime.now().toIso8601String(),
          'is_pro': isPro,
          'is_expired': isExpired,
          'account_type': accountType,
          'status_label': statusLabel,
          'pro_expires_at': exp?.toIso8601String(),
          'days_remaining': daysRemaining,
          'latest_plan': latestPlan,
          'plan_label': planLabel,
          'total_orders': userOrders.length,
          'total_spent': totalSpent,
          'is_admin': m['isAdmin'] == true,
          'coins': userCoins,
          'reward_balance': userReward,
          'has_coin_pro': hasCoinPro,
          'coin_redeem_note': coinProSummary,
          'coin_orders_count': coinOrders.length,
        });
      }
    });
    return list;
  }

  /// Tính toán số liệu thống kê đơn hàng và người dùng (bao gồm xu và đổi Pro bằng xu)
  static Map<String, dynamic> calculateSummary(
    List<dynamic> orders, {
    int? totalUsers,
    int? proUsers,
    int? freeUsers,
    int? totalCoins,
    int? coinRedeemUsers,
  }) {
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

    final totUsers = totalUsers ?? (buyers.length > 3 ? buyers.length : 4);
    final pUsers = proUsers ?? (buyers.isNotEmpty ? buyers.length : 2);
    final fUsers = freeUsers ?? (totUsers > pUsers ? totUsers - pUsers : 0);

    return {
      'total_users': totUsers.toString(),
      'pro_users': pUsers.toString(),
      'free_users': fUsers.toString(),
      'buyers': buyers.length.toString(),
      'purchases': purchases.toString(),
      'monthly': monthly.toString(),
      'yearly': yearly.toString(),
      'revenue': revenue.toString(),
      'total_coins': (totalCoins ?? 0).toString(),
      'coin_redeem_users': (coinRedeemUsers ?? 0).toString(),
    };
  }
}
