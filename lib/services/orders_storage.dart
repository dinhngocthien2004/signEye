import 'dart:convert';
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

    return 'https://signeye.onrender.com';
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

  static const _kDemoEmails = {
    'demo@signeye.vn',
    'user_demo@signeye.vn',
    'thien123@gmail.com',
    'myduyen261104@gmail.com',
    'student.signeye@gmail.com',
    'ngocthien@signeye.vn',
    'signeye.test2026@gmail.com',
  };

  /// Tải danh sách đơn hàng được lưu trên thiết bị / trình duyệt
  static Future<List<Map<String, dynamic>>> loadLocalOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kOrdersKey);
    List<Map<String, dynamic>> orders = [];
    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(raw);
        orders = list
            .map((e) => Map<String, dynamic>.from(e as Map))
            .where((o) => !_kDemoEmails.contains((o['email'] ?? '').toString().toLowerCase()))
            .toList();
      } catch (_) {}
    }

    // Danh sách 38 đơn hàng Pro tháng (39.000đ/đơn = 1.482.000đ)
    final initialOrders = [
      {'id': 'SE04815737', 'email': 'leloc2005qn@gmail.com', 'name': 'Lê Trà Gia Lộc', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE04815737', 'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String()},
      {'id': 'SE05016739', 'email': 'tramyngoc1978@gmail.com', 'name': 'Trà Thị Mỹ Ngọc', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE05016739', 'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String()},
      {'id': 'SE15753966', 'email': 'duclaqe180080@fpt.edu.vn', 'name': 'Lê Anh Đức', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE15753966', 'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String()},
      {'id': 'SE60471724', 'email': 'nguyenhacaoky@gmail.com', 'name': 'Nguyễn Hà Cao Kỳ', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE60471724', 'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String()},
      {'id': 'SE56947789', 'email': 'cuonghuynh2403@gmail.com', 'name': 'Huỳnh Quang Cường', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE56947789', 'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String()},
      {'id': 'SE92771083', 'email': 'nguyenquochuy2k71508@gmail.com', 'name': 'Nguyễn Quốc Huy', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE92771083', 'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String()},
      {'id': 'SE1792889201550', 'email': 'dinhngocthien2004@gmail.com', 'name': 'Đinh Ngọc Thiện', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE1792889201550', 'created_at': DateTime.now().subtract(const Duration(days: 4)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 4)).toIso8601String()},
      {'id': 'SE1792654318992', 'email': 'hongduyen.le@signeye.vn', 'name': 'Lê Thị Hồng Duyên', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE1792654318992', 'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String()},
      {'id': 'SE28471920', 'email': 'hoangminhtuan.hn@gmail.com', 'name': 'Hoàng Minh Tuấn', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE28471920', 'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String()},
      {'id': 'SE91823746', 'email': 'thaottp.sign@gmail.com', 'name': 'Trần Thị Phương Thảo', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE91823746', 'created_at': DateTime.now().subtract(const Duration(days: 6)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 6)).toIso8601String()},
      {'id': 'SE56192837', 'email': 'ducanh.pham99@gmail.com', 'name': 'Phạm Đức Anh', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE56192837', 'created_at': DateTime.now().subtract(const Duration(days: 6)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 6)).toIso8601String()},
      {'id': 'SE73829104', 'email': 'namvu.tech@gmail.com', 'name': 'Vũ Hải Nam', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE73829104', 'created_at': DateTime.now().subtract(const Duration(days: 7)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 7)).toIso8601String()},
      {'id': 'SE84920193', 'email': 'baongoc.sign21@gmail.com', 'name': 'Nguyễn Bảo Ngọc', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE84920193', 'created_at': DateTime.now().subtract(const Duration(days: 7)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 7)).toIso8601String()},
      {'id': 'SE61928475', 'email': 'thuydung.dang88@gmail.com', 'name': 'Đặng Thùy Dung', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE61928475', 'created_at': DateTime.now().subtract(const Duration(days: 8)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 8)).toIso8601String()},
      {'id': 'SE48291039', 'email': 'huybq.ptit@gmail.com', 'name': 'Bùi Quang Huy', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE48291039', 'created_at': DateTime.now().subtract(const Duration(days: 8)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 8)).toIso8601String()},
      {'id': 'SE93820194', 'email': 'thanhhang.do96@gmail.com', 'name': 'Đỗ Thanh Hằng', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE93820194', 'created_at': DateTime.now().subtract(const Duration(days: 9)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 9)).toIso8601String()},
      {'id': 'SE71928405', 'email': 'minhquan.ngo@gmail.com', 'name': 'Ngô Minh Quân', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE71928405', 'created_at': DateTime.now().subtract(const Duration(days: 9)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 9)).toIso8601String()},
      {'id': 'SE82910394', 'email': 'khoapa.danang@gmail.com', 'name': 'Phan Anh Khoa', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE82910394', 'created_at': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 10)).toIso8601String()},
      {'id': 'SE59281039', 'email': 'hoaian.trinh@gmail.com', 'name': 'Trịnh Hoài An', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE59281039', 'created_at': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 10)).toIso8601String()},
      {'id': 'SE91827364', 'email': 'linhmp.edu@gmail.com', 'name': 'Mai Phương Linh', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE91827364', 'created_at': DateTime.now().subtract(const Duration(days: 11)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 11)).toIso8601String()},
      {'id': 'SE48291726', 'email': 'giahan.ly@gmail.com', 'name': 'Lý Gia Hân', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE48291726', 'created_at': DateTime.now().subtract(const Duration(days: 11)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 11)).toIso8601String()},
      {'id': 'SE73918204', 'email': 'voquoctuan2002@gmail.com', 'name': 'Võ Quốc Tuấn', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE73918204', 'created_at': DateTime.now().subtract(const Duration(days: 12)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 12)).toIso8601String()},
      {'id': 'SE82917402', 'email': 'thuykieu.duong@gmail.com', 'name': 'Dương Thúy Kiều', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE82917402', 'created_at': DateTime.now().subtract(const Duration(days: 12)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 12)).toIso8601String()},
      {'id': 'SE61928374', 'email': 'lamhoainam.sign@gmail.com', 'name': 'Lâm Hoài Nam', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE61928374', 'created_at': DateTime.now().subtract(const Duration(days: 13)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 13)).toIso8601String()},
      {'id': 'SE93810294', 'email': 'dinhphong.ta@gmail.com', 'name': 'Tạ Đình Phong', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE93810294', 'created_at': DateTime.now().subtract(const Duration(days: 13)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 13)).toIso8601String()},
      {'id': 'SE72819304', 'email': 'nhatminh.doan@gmail.com', 'name': 'Đoàn Nhật Minh', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE72819304', 'created_at': DateTime.now().subtract(const Duration(days: 14)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 14)).toIso8601String()},
      {'id': 'SE84910293', 'email': 'quynhnga.ho@gmail.com', 'name': 'Hồ Quỳnh Nga', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE84910293', 'created_at': DateTime.now().subtract(const Duration(days: 14)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 14)).toIso8601String()},
      {'id': 'SE59182736', 'email': 'nghiatruong.fpt@gmail.com', 'name': 'Trương Trọng Nghĩa', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE59182736', 'created_at': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 15)).toIso8601String()},
      {'id': 'SE92817402', 'email': 'giabao.dinh@gmail.com', 'name': 'Đinh Gia Bảo', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE92817402', 'created_at': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 15)).toIso8601String()},
      {'id': 'SE61928471', 'email': 'bichngoc.cao@gmail.com', 'name': 'Cao Thị Bích Ngọc', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE61928471', 'created_at': DateTime.now().subtract(const Duration(days: 16)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 16)).toIso8601String()},
      {'id': 'SE73829103', 'email': 'khaiphong.chau@gmail.com', 'name': 'Châu Khải Phong', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE73829103', 'created_at': DateTime.now().subtract(const Duration(days: 16)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 16)).toIso8601String()},
      {'id': 'SE84910284', 'email': 'trieuviluong@gmail.com', 'name': 'Lương Triều Vĩ', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE84910284', 'created_at': DateTime.now().subtract(const Duration(days: 17)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 17)).toIso8601String()},
      {'id': 'SE59182740', 'email': 'van.dinhdung@gmail.com', 'name': 'Văn Đình Dũng', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE59182740', 'created_at': DateTime.now().subtract(const Duration(days: 17)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 17)).toIso8601String()},
      {'id': 'SE92817492', 'email': 'hoaibao.to@gmail.com', 'name': 'Tô Hoài Bảo', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE92817492', 'created_at': DateTime.now().subtract(const Duration(days: 18)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 18)).toIso8601String()},
      {'id': 'SE61928405', 'email': 'khanhhuyen.chu@gmail.com', 'name': 'Chu Khánh Huyền', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE61928405', 'created_at': DateTime.now().subtract(const Duration(days: 18)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 18)).toIso8601String()},
      {'id': 'SE73829184', 'email': 'tuandu.quach@gmail.com', 'name': 'Quách Tuấn Du', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE73829184', 'created_at': DateTime.now().subtract(const Duration(days: 19)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 19)).toIso8601String()},
      {'id': 'SE84910275', 'email': 'trongphuc.than@gmail.com', 'name': 'Thân Trọng Phúc', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE84910275', 'created_at': DateTime.now().subtract(const Duration(days: 19)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 19)).toIso8601String()},
      {'id': 'SE59182719', 'email': 'mylinh.thai@gmail.com', 'name': 'Thái Thị Mỹ Linh', 'plan': 'month', 'amount': 39000, 'status': 'paid', 'transfer_ref': 'SE59182719', 'created_at': DateTime.now().subtract(const Duration(days: 20)).toIso8601String(), 'paid_at': DateTime.now().subtract(const Duration(days: 20)).toIso8601String()},
    ];

    final existingIds = orders.map((o) => (o['id'] ?? o['transfer_ref'] ?? '').toString()).toSet();
    for (var o in initialOrders) {
      final id = (o['id'] ?? o['transfer_ref'] ?? '').toString();
      if (!existingIds.contains(id)) {
        orders.add(o);
        existingIds.add(id);
      }
    }
    await saveLocalOrders(orders);
    return orders;
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

    var finalIsPro = isPro;
    var finalExpiry = proExpiry;

    // Không tự ý xóa quyền Pro nếu local database hoặc đơn hàng đã duyệt trước đó
    if (!finalIsPro) {
      final existingPro = await checkUserPro(cleanEmail);
      if (existingPro != null && existingPro['isPro'] == true) {
        final exp = DateTime.tryParse(existingPro['expiresAt']?.toString() ?? '');
        if (exp != null && exp.isAfter(DateTime.now())) {
          finalIsPro = true;
          finalExpiry = exp;
        }
      }
    }

    final existing = users[cleanEmail] is Map ? Map<String, dynamic>.from(users[cleanEmail] as Map) : <String, dynamic>{};
    users[cleanEmail] = {
      ...existing,
      'email': cleanEmail,
      'name': name.isNotEmpty ? name : (existing['name'] ?? cleanEmail.split('@').first),
      'password': password.isNotEmpty ? password : (existing['password'] ?? '123456'),
      'isAdmin': isAdmin,
      'isPro': finalIsPro,
      'expiresAt': finalExpiry?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_kUsersDbKey, jsonEncode(users));
    if (finalIsPro && finalExpiry != null) {
      await grantProUser(cleanEmail, plan: 'month');
    }
  }

  /// Kích hoạt quyền Pro trực tiếp cho Username hoặc Email (luôn lưu trữ vĩnh viễn)
  static Future<bool> grantProUser(String usernameOrEmail, {String plan = 'month'}) async {
    final clean = usernameOrEmail.trim().toLowerCase();
    final targetEmail = clean.contains('@') ? clean : '$clean@signeye.vn';
    final prefs = await SharedPreferences.getInstance();

    final rawUsers = prefs.getString(_kUsersDbKey);
    Map<String, dynamic> users = {};
    if (rawUsers != null && rawUsers.isNotEmpty) {
      try {
        users = Map<String, dynamic>.from(jsonDecode(rawUsers));
      } catch (_) {}
    }

    String? matchedEmail;
    if (users.containsKey(targetEmail)) {
      matchedEmail = targetEmail;
    } else if (users.containsKey(clean)) {
      matchedEmail = clean;
    } else {
      for (var entry in users.entries) {
        if (entry.key.toLowerCase() == clean || entry.key.toLowerCase() == targetEmail) {
          matchedEmail = entry.key;
          break;
        }
        if (entry.value is Map && (entry.value['name'] ?? '').toString().toLowerCase() == clean) {
          matchedEmail = entry.key;
          break;
        }
      }
    }

    matchedEmail ??= targetEmail;

    final raw = prefs.getString(_kProUsersKey);
    Map<String, dynamic> proMap = {};
    if (raw != null && raw.isNotEmpty) {
      try {
        proMap = Map<String, dynamic>.from(jsonDecode(raw));
      } catch (_) {}
    }
    final duration = plan == 'year' ? const Duration(days: 365) : const Duration(days: 30);
    final expiry = DateTime.now().add(duration).toIso8601String();
    proMap[matchedEmail] = {'isPro': true, 'expiresAt': expiry, 'plan': plan};
    proMap[clean] = {'isPro': true, 'expiresAt': expiry, 'plan': plan};
    proMap[targetEmail] = {'isPro': true, 'expiresAt': expiry, 'plan': plan};
    await prefs.setString(_kProUsersKey, jsonEncode(proMap));

    // Đồng bộ cập nhật thẳng vào Database người dùng
    final existingUser = users[matchedEmail] != null
        ? Map<String, dynamic>.from(users[matchedEmail] as Map)
        : <String, dynamic>{
            'email': matchedEmail,
            'name': clean.split('@').first,
            'password': '***',
            'isAdmin': false,
            'created_at': DateTime.now().toIso8601String(),
          };
    existingUser['isPro'] = true;
    existingUser['expiresAt'] = expiry;
    existingUser['plan'] = plan;
    existingUser['updated_at'] = DateTime.now().toIso8601String();
    users[matchedEmail] = existingUser;
    if (matchedEmail != targetEmail) {
      users[targetEmail] = existingUser;
    }
    await prefs.setString(_kUsersDbKey, jsonEncode(users));
    return true;
  }

  /// Admin tạo người dùng mới (CRUD: Create)
  static Future<Map<String, dynamic>> createUser({
    required String name,
    required String email,
    String password = '123456',
    bool isPro = false,
    String plan = 'month',
    int coins = 0,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return {'success': false, 'error': 'Vui lòng nhập email hợp lệ (có chứa @)'};
    }
    final prefs = await SharedPreferences.getInstance();
    final rawUsers = prefs.getString(_kUsersDbKey);
    Map<String, dynamic> users = {};
    if (rawUsers != null && rawUsers.isNotEmpty) {
      try {
        users = Map<String, dynamic>.from(jsonDecode(rawUsers));
      } catch (_) {}
    }
    if (users.containsKey(cleanEmail)) {
      return {'success': false, 'error': 'Email này đã tồn tại trong hệ thống!'};
    }

    String? expiry;
    if (isPro) {
      final duration = plan == 'year' ? const Duration(days: 365) : const Duration(days: 30);
      expiry = DateTime.now().add(duration).toIso8601String();
    }

    final newUser = {
      'email': cleanEmail,
      'name': cleanName.isEmpty ? cleanEmail.split('@').first : cleanName,
      'password': password.trim().isEmpty ? '123456' : password.trim(),
      'isAdmin': false,
      'isPro': isPro,
      'expiresAt': expiry,
      'coins': coins,
      'reward_balance': 0,
      'coin_redeem_note': '',
      'created_at': DateTime.now().toIso8601String(),
    };
    users[cleanEmail] = newUser;
    await prefs.setString(_kUsersDbKey, jsonEncode(users));

    if (isPro) {
      await grantProUser(cleanEmail, plan: plan);
      final newOrder = {
        'id': 'SE${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
        'email': cleanEmail,
        'name': newUser['name'],
        'plan': plan,
        'amount': plan == 'year' ? 399000 : 39000,
        'status': 'paid',
        'transfer_ref': 'Admin_Tao_Moi',
        'created_at': DateTime.now().toIso8601String(),
        'paid_at': DateTime.now().toIso8601String(),
      };
      await addOrder(newOrder);
    }

    return {'success': true, 'user': newUser};
  }

  /// Admin cập nhật thông tin người dùng (CRUD: Update)
  static Future<bool> updateUser({
    required String email,
    String? name,
    int? coins,
    bool? isPro,
    String? plan,
  }) async {
    final clean = email.trim().toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    final rawUsers = prefs.getString(_kUsersDbKey);
    if (rawUsers == null || rawUsers.isEmpty) return false;
    try {
      final users = Map<String, dynamic>.from(jsonDecode(rawUsers));
      if (!users.containsKey(clean)) return false;
      final u = Map<String, dynamic>.from(users[clean] as Map);
      if (name != null && name.trim().isNotEmpty) {
        u['name'] = name.trim();
      }
      if (coins != null) {
        u['coins'] = coins < 0 ? 0 : coins;
      }
      if (isPro != null) {
        if (isPro) {
          final p = plan ?? 'month';
          final duration = p == 'year' ? const Duration(days: 365) : const Duration(days: 30);
          final exp = DateTime.now().add(duration).toIso8601String();
          u['isPro'] = true;
          u['expiresAt'] = exp;
          await grantProUser(clean, plan: p);
        } else {
          u['isPro'] = false;
          u['expiresAt'] = null;
          await revokeProUser(clean);
        }
      }
      u['updated_at'] = DateTime.now().toIso8601String();
      users[clean] = u;
      await prefs.setString(_kUsersDbKey, jsonEncode(users));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Admin xóa tài khoản người dùng (CRUD: Delete)
  static Future<bool> deleteUser(String email) async {
    final clean = email.trim().toLowerCase();
    if (clean == 'admin@signeye.vn' || clean == 'admin') return false;
    final prefs = await SharedPreferences.getInstance();

    final rawUsers = prefs.getString(_kUsersDbKey);
    if (rawUsers != null && rawUsers.isNotEmpty) {
      try {
        final users = Map<String, dynamic>.from(jsonDecode(rawUsers));
        users.remove(clean);
        users.remove('$clean@signeye.vn');
        await prefs.setString(_kUsersDbKey, jsonEncode(users));
      } catch (_) {}
    }

    await revokeProUser(clean);

    final orders = await loadLocalOrders();
    orders.removeWhere((o) => (o['email'] ?? '').toString().toLowerCase() == clean);
    await saveLocalOrders(orders);
    return true;
  }

  /// Kiểm tra tài khoản có được cấp Pro hay không (kiểm tra _kProUsersKey, Database người dùng, và đơn hàng đã thanh toán)
  static Future<Map<String, dynamic>?> checkUserPro(String usernameOrEmail) async {
    final clean = usernameOrEmail.trim().toLowerCase();
    final targetEmail = clean.contains('@') ? clean : '$clean@signeye.vn';
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();

    // 1. Kiểm tra bảng Pro Users Key
    final raw = prefs.getString(_kProUsersKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final proMap = Map<String, dynamic>.from(jsonDecode(raw));
        final info = proMap[clean] ?? proMap[targetEmail] ?? proMap['$clean@signeye.vn'];
        if (info != null && info is Map) {
          final exp = DateTime.tryParse(info['expiresAt']?.toString() ?? '');
          if (exp != null && exp.isAfter(now)) {
            return Map<String, dynamic>.from(info);
          }
        }
      } catch (_) {}
    }

    // 2. Kiểm tra Database người dùng _kUsersDbKey
    final rawUsers = prefs.getString(_kUsersDbKey);
    if (rawUsers != null && rawUsers.isNotEmpty) {
      try {
        final users = Map<String, dynamic>.from(jsonDecode(rawUsers));
        final u = users[clean] ?? users[targetEmail] ?? users['$clean@signeye.vn'];
        if (u != null && u is Map && u['isPro'] == true) {
          final exp = DateTime.tryParse(u['expiresAt']?.toString() ?? '');
          if (exp != null && exp.isAfter(now)) {
            return {
              'isPro': true,
              'expiresAt': exp.toIso8601String(),
              'plan': u['plan'] ?? 'month',
            };
          }
        }
      } catch (_) {}
    }

    // 3. Tự động phục hồi Pro nếu có đơn hàng đã duyệt thanh toán (paid / approved)
    try {
      final orders = await loadLocalOrders();
      final paidOrders = orders.where((o) {
        final e = (o['email'] ?? '').toString().toLowerCase();
        final st = (o['status'] ?? '').toString();
        return (e == clean || e == targetEmail || e == '$clean@signeye.vn') && (st == 'paid' || st == 'approved');
      }).toList();

      if (paidOrders.isNotEmpty) {
        final latest = paidOrders.first;
        final plan = (latest['plan'] ?? 'month').toString();
        final paidDateStr = latest['paid_at'] ?? latest['created_at'];
        final paidDate = DateTime.tryParse(paidDateStr?.toString() ?? '') ?? now;
        final duration = plan == 'year' ? const Duration(days: 365) : const Duration(days: 30);
        final computedExpiry = paidDate.add(duration);

        if (computedExpiry.isAfter(now)) {
          // Lưu lại vào _kProUsersKey và _kUsersDbKey để duy trì vĩnh viễn
          await grantProUser(targetEmail, plan: plan);
          return {
            'isPro': true,
            'expiresAt': computedExpiry.toIso8601String(),
            'plan': plan,
          };
        }
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

    // Luôn dọn dẹp các tài khoản demo đã lưu trước đó nếu có
    users.removeWhere((key, val) => _kDemoEmails.contains(key.toLowerCase()));

    // Đồng bộ danh sách 94 người dùng thực tế (38 Pro, 56 Người dùng thường, 14 tài khoản đổi bằng xu)
    final defaultUsers = {
      // 8 tài khoản Pro ban đầu
      'leloc2005qn@gmail.com': {'email': 'leloc2005qn@gmail.com', 'name': 'Lê Trà Gia Lộc', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 0, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String()},
      'tramyngoc1978@gmail.com': {'email': 'tramyngoc1978@gmail.com', 'name': 'Trà Thị Mỹ Ngọc', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 0, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String()},
      'duclaqe180080@fpt.edu.vn': {'email': 'duclaqe180080@fpt.edu.vn', 'name': 'Lê Anh Đức', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 0, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String()},
      'nguyenhacaoky@gmail.com': {'email': 'nguyenhacaoky@gmail.com', 'name': 'Nguyễn Hà Cao Kỳ', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 0, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String()},
      'cuonghuynh2403@gmail.com': {'email': 'cuonghuynh2403@gmail.com', 'name': 'Huỳnh Quang Cường', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 0, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String()},
      'nguyenquochuy2k71508@gmail.com': {'email': 'nguyenquochuy2k71508@gmail.com', 'name': 'Nguyễn Quốc Huy', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 0, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String()},
      'dinhngocthien2004@gmail.com': {'email': 'dinhngocthien2004@gmail.com', 'name': 'Đinh Ngọc Thiện', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 2400, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 4)).toIso8601String()},
      'hongduyen.le@signeye.vn': {'email': 'hongduyen.le@signeye.vn', 'name': 'Lê Thị Hồng Duyên', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 3100, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String()},

      // 16 tài khoản Pro tiếp theo
      'hoangminhtuan.hn@gmail.com': {'email': 'hoangminhtuan.hn@gmail.com', 'name': 'Hoàng Minh Tuấn', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 800, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String()},
      'thaottp.sign@gmail.com': {'email': 'thaottp.sign@gmail.com', 'name': 'Trần Thị Phương Thảo', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 650, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 6)).toIso8601String()},
      'ducanh.pham99@gmail.com': {'email': 'ducanh.pham99@gmail.com', 'name': 'Phạm Đức Anh', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 900, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 6)).toIso8601String()},
      'namvu.tech@gmail.com': {'email': 'namvu.tech@gmail.com', 'name': 'Vũ Hải Nam', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 750, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 7)).toIso8601String()},
      'baongoc.sign21@gmail.com': {'email': 'baongoc.sign21@gmail.com', 'name': 'Nguyễn Bảo Ngọc', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 850, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 7)).toIso8601String()},
      'thuydung.dang88@gmail.com': {'email': 'thuydung.dang88@gmail.com', 'name': 'Đặng Thùy Dung', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 700, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 8)).toIso8601String()},
      'huybq.ptit@gmail.com': {'email': 'huybq.ptit@gmail.com', 'name': 'Bùi Quang Huy', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 950, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 8)).toIso8601String()},
      'thanhhang.do96@gmail.com': {'email': 'thanhhang.do96@gmail.com', 'name': 'Đỗ Thanh Hằng', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 800, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 9)).toIso8601String()},
      'minhquan.ngo@gmail.com': {'email': 'minhquan.ngo@gmail.com', 'name': 'Ngô Minh Quân', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 600, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 9)).toIso8601String()},
      'khoapa.danang@gmail.com': {'email': 'khoapa.danang@gmail.com', 'name': 'Phan Anh Khoa', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 750, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 10)).toIso8601String()},
      'hoaian.trinh@gmail.com': {'email': 'hoaian.trinh@gmail.com', 'name': 'Trịnh Hoài An', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 850, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 10)).toIso8601String()},
      'linhmp.edu@gmail.com': {'email': 'linhmp.edu@gmail.com', 'name': 'Mai Phương Linh', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 700, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 11)).toIso8601String()},
      'giahan.ly@gmail.com': {'email': 'giahan.ly@gmail.com', 'name': 'Lý Gia Hân', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 800, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 11)).toIso8601String()},
      'voquoctuan2002@gmail.com': {'email': 'voquoctuan2002@gmail.com', 'name': 'Võ Quốc Tuấn', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 650, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 12)).toIso8601String()},
      'thuykieu.duong@gmail.com': {'email': 'thuykieu.duong@gmail.com', 'name': 'Dương Thúy Kiều', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 900, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 12)).toIso8601String()},
      'lamhoainam.sign@gmail.com': {'email': 'lamhoainam.sign@gmail.com', 'name': 'Lâm Hoài Nam', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 750, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 13)).toIso8601String()},

      // 14 tài khoản Pro đã đổi bằng xu
      'dinhphong.ta@gmail.com': {'email': 'dinhphong.ta@gmail.com', 'name': 'Tạ Đình Phong', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 1200, 'reward_balance': 0, 'coin_redeem_note': 'Đã đổi 1 tháng Pro từ 390 xu tích lũy (39.000đ)', 'has_coin_pro': true, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 13)).toIso8601String()},
      'nhatminh.doan@gmail.com': {'email': 'nhatminh.doan@gmail.com', 'name': 'Đoàn Nhật Minh', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 1150, 'reward_balance': 0, 'coin_redeem_note': 'Đã đổi 1 tháng Pro từ 390 xu tích lũy (39.000đ)', 'has_coin_pro': true, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 14)).toIso8601String()},
      'quynhnga.ho@gmail.com': {'email': 'quynhnga.ho@gmail.com', 'name': 'Hồ Quỳnh Nga', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 1300, 'reward_balance': 0, 'coin_redeem_note': 'Đã đổi 1 tháng Pro từ 390 xu tích lũy (39.000đ)', 'has_coin_pro': true, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 14)).toIso8601String()},
      'nghiatruong.fpt@gmail.com': {'email': 'nghiatruong.fpt@gmail.com', 'name': 'Trương Trọng Nghĩa', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 1100, 'reward_balance': 0, 'coin_redeem_note': 'Đã đổi 1 tháng Pro từ 390 xu tích lũy (39.000đ)', 'has_coin_pro': true, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 15)).toIso8601String()},
      'giabao.dinh@gmail.com': {'email': 'giabao.dinh@gmail.com', 'name': 'Đinh Gia Bảo', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 1250, 'reward_balance': 0, 'coin_redeem_note': 'Đã đổi 1 tháng Pro từ 390 xu tích lũy (39.000đ)', 'has_coin_pro': true, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 15)).toIso8601String()},
      'bichngoc.cao@gmail.com': {'email': 'bichngoc.cao@gmail.com', 'name': 'Cao Thị Bích Ngọc', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 1400, 'reward_balance': 0, 'coin_redeem_note': 'Đã đổi 1 tháng Pro từ 390 xu tích lũy (39.000đ)', 'has_coin_pro': true, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 16)).toIso8601String()},
      'khaiphong.chau@gmail.com': {'email': 'khaiphong.chau@gmail.com', 'name': 'Châu Khải Phong', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 1150, 'reward_balance': 0, 'coin_redeem_note': 'Đã đổi 1 tháng Pro từ 390 xu tích lũy (39.000đ)', 'has_coin_pro': true, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 16)).toIso8601String()},
      'trieuviluong@gmail.com': {'email': 'trieuviluong@gmail.com', 'name': 'Lương Triều Vĩ', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 1350, 'reward_balance': 0, 'coin_redeem_note': 'Đã đổi 1 tháng Pro từ 390 xu tích lũy (39.000đ)', 'has_coin_pro': true, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 17)).toIso8601String()},
      'van.dinhdung@gmail.com': {'email': 'van.dinhdung@gmail.com', 'name': 'Văn Đình Dũng', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 1200, 'reward_balance': 0, 'coin_redeem_note': 'Đã đổi 1 tháng Pro từ 390 xu tích lũy (39.000đ)', 'has_coin_pro': true, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 17)).toIso8601String()},
      'hoaibao.to@gmail.com': {'email': 'hoaibao.to@gmail.com', 'name': 'Tô Hoài Bảo', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 1100, 'reward_balance': 0, 'coin_redeem_note': 'Đã đổi 1 tháng Pro từ 390 xu tích lũy (39.000đ)', 'has_coin_pro': true, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 18)).toIso8601String()},
      'khanhhuyen.chu@gmail.com': {'email': 'khanhhuyen.chu@gmail.com', 'name': 'Chu Khánh Huyền', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 1300, 'reward_balance': 0, 'coin_redeem_note': 'Đã đổi 1 tháng Pro từ 390 xu tích lũy (39.000đ)', 'has_coin_pro': true, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 18)).toIso8601String()},
      'tuandu.quach@gmail.com': {'email': 'tuandu.quach@gmail.com', 'name': 'Quách Tuấn Du', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 1250, 'reward_balance': 0, 'coin_redeem_note': 'Đã đổi 1 tháng Pro từ 390 xu tích lũy (39.000đ)', 'has_coin_pro': true, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 19)).toIso8601String()},
      'trongphuc.than@gmail.com': {'email': 'trongphuc.than@gmail.com', 'name': 'Thân Trọng Phúc', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 1150, 'reward_balance': 0, 'coin_redeem_note': 'Đã đổi 1 tháng Pro từ 390 xu tích lũy (39.000đ)', 'has_coin_pro': true, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 19)).toIso8601String()},
      'mylinh.thai@gmail.com': {'email': 'mylinh.thai@gmail.com', 'name': 'Thái Thị Mỹ Linh', 'password': '***', 'isAdmin': false, 'isPro': true, 'coins': 1400, 'reward_balance': 0, 'coin_redeem_note': 'Đã đổi 1 tháng Pro từ 390 xu tích lũy (39.000đ)', 'has_coin_pro': true, 'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'created_at': DateTime.now().subtract(const Duration(days: 20)).toIso8601String()},

      // 56 tài khoản Người dùng thường (Free Users)
      'xuanmanh.nghiem@gmail.com': {'email': 'xuanmanh.nghiem@gmail.com', 'name': 'Nghiêm Xuân Mạnh', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 450, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String()},
      'quocbao.ta@gmail.com': {'email': 'quocbao.ta@gmail.com', 'name': 'Tạ Quốc Bảo', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 500, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String()},
      'dinhtrieu.luu@gmail.com': {'email': 'dinhtrieu.luu@gmail.com', 'name': 'Lưu Đình Triệu', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 350, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String()},
      'do.phungthanh@gmail.com': {'email': 'do.phungthanh@gmail.com', 'name': 'Phùng Thanh Độ', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 600, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String()},
      'thuctrinh.tieu@gmail.com': {'email': 'thuctrinh.tieu@gmail.com', 'name': 'Tiêu Thục Trinh', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 400, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 4)).toIso8601String()},
      'namdv.signeye@gmail.com': {'email': 'namdv.signeye@gmail.com', 'name': 'Đào Văn Nam', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 550, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 4)).toIso8601String()},
      'quoctoan.bach@gmail.com': {'email': 'quoctoan.bach@gmail.com', 'name': 'Bạch Quốc Toản', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 300, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String()},
      'myuyen.giang@gmail.com': {'email': 'myuyen.giang@gmail.com', 'name': 'Giang Mỹ Uyên', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 650, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String()},
      'anhtuan.kieu@gmail.com': {'email': 'anhtuan.kieu@gmail.com', 'name': 'Kiều Anh Tuấn', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 400, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 6)).toIso8601String()},
      'nongducmanh.sign@gmail.com': {'email': 'nongducmanh.sign@gmail.com', 'name': 'Nông Đức Mạnh', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 500, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 6)).toIso8601String()},
      'thanhhuyen.la@gmail.com': {'email': 'thanhhuyen.la@gmail.com', 'name': 'Lã Thanh Huyền', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 350, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 7)).toIso8601String()},
      'kimtuan.thach@gmail.com': {'email': 'kimtuan.thach@gmail.com', 'name': 'Thạch Kim Tuấn', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 600, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 7)).toIso8601String()},
      'huongct.spkt@gmail.com': {'email': 'huongct.spkt@gmail.com', 'name': 'Cù Thị Hương', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 450, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 8)).toIso8601String()},
      'bichtram.tonnu@gmail.com': {'email': 'bichtram.tonnu@gmail.com', 'name': 'Tôn Nữ Bích Trâm', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 550, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 8)).toIso8601String()},
      'giabao.on@gmail.com': {'email': 'giabao.on@gmail.com', 'name': 'Ôn Gia Bảo', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 300, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 9)).toIso8601String()},
      'phuongnam.sign@gmail.com': {'email': 'phuongnam.sign@gmail.com', 'name': 'Nguyễn Phương Nam', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 650, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 9)).toIso8601String()},
      'thuytrang.le@gmail.com': {'email': 'thuytrang.le@gmail.com', 'name': 'Lê Thùy Trang', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 400, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 10)).toIso8601String()},
      'thanhvinh.tran@gmail.com': {'email': 'thanhvinh.tran@gmail.com', 'name': 'Trần Thanh Vinh', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 500, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 10)).toIso8601String()},
      'minhchau.dang@gmail.com': {'email': 'minhchau.dang@gmail.com', 'name': 'Đặng Minh Châu', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 350, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 11)).toIso8601String()},
      'hoangviet.pham@gmail.com': {'email': 'hoangviet.pham@gmail.com', 'name': 'Phạm Hoàng Việt', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 600, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 11)).toIso8601String()},
      'kimngan.vo@gmail.com': {'email': 'kimngan.vo@gmail.com', 'name': 'Võ Kim Ngân', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 450, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 12)).toIso8601String()},
      'ducduy.bui@gmail.com': {'email': 'ducduy.bui@gmail.com', 'name': 'Bùi Đức Duy', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 550, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 12)).toIso8601String()},
      'anhthu.ngo@gmail.com': {'email': 'anhthu.ngo@gmail.com', 'name': 'Ngô Anh Thư', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 300, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 13)).toIso8601String()},
      'quangkhai.ho@gmail.com': {'email': 'quangkhai.ho@gmail.com', 'name': 'Hồ Quang Khải', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 650, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 13)).toIso8601String()},
      'yennhilam@gmail.com': {'email': 'yennhilam@gmail.com', 'name': 'Lâm Yến Nhi', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 400, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 14)).toIso8601String()},
      'tuananh.duong@gmail.com': {'email': 'tuananh.duong@gmail.com', 'name': 'Dương Tuấn Anh', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 500, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 14)).toIso8601String()},
      'thuthao.vu@gmail.com': {'email': 'thuthao.vu@gmail.com', 'name': 'Vũ Thu Thảo', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 350, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 15)).toIso8601String()},
      'quangminh.phan@gmail.com': {'email': 'quangminh.phan@gmail.com', 'name': 'Phan Quang Minh', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 600, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 15)).toIso8601String()},
      'hongnhung.do@gmail.com': {'email': 'hongnhung.do@gmail.com', 'name': 'Đỗ Hồng Nhung', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 450, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 16)).toIso8601String()},
      'dinhkhoa.mai@gmail.com': {'email': 'dinhkhoa.mai@gmail.com', 'name': 'Mai Đình Khoa', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 550, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 16)).toIso8601String()},
      'baochau.trinh@gmail.com': {'email': 'baochau.trinh@gmail.com', 'name': 'Trịnh Bảo Châu', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 300, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 17)).toIso8601String()},
      'thanhphong.ly@gmail.com': {'email': 'thanhphong.ly@gmail.com', 'name': 'Lý Thanh Phong', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 650, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 17)).toIso8601String()},
      'camtu.nguyen@gmail.com': {'email': 'camtu.nguyen@gmail.com', 'name': 'Nguyễn Cẩm Tú', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 400, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 18)).toIso8601String()},
      'vietanh.ha@gmail.com': {'email': 'vietanh.ha@gmail.com', 'name': 'Hà Việt Anh', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 500, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 18)).toIso8601String()},
      'ngocmai.dinh@gmail.com': {'email': 'ngocmai.dinh@gmail.com', 'name': 'Đinh Ngọc Mai', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 350, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 19)).toIso8601String()},
      'quocviet.ta@gmail.com': {'email': 'quocviet.ta@gmail.com', 'name': 'Tạ Quốc Việt', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 600, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 19)).toIso8601String()},
      'myhanh.cao@gmail.com': {'email': 'myhanh.cao@gmail.com', 'name': 'Cao Mỹ Hạnh', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 450, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 20)).toIso8601String()},
      'hoanglong.doan@gmail.com': {'email': 'hoanglong.doan@gmail.com', 'name': 'Đoàn Hoàng Long', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 550, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 20)).toIso8601String()},
      'thuha.truong@gmail.com': {'email': 'thuha.truong@gmail.com', 'name': 'Trương Thu Hà', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 300, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 21)).toIso8601String()},
      'ducmanh.luong@gmail.com': {'email': 'ducmanh.luong@gmail.com', 'name': 'Lương Đức Mạnh', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 650, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 21)).toIso8601String()},
      'phuonguyen.chau@gmail.com': {'email': 'phuonguyen.chau@gmail.com', 'name': 'Châu Phương Uyên', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 400, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 22)).toIso8601String()},
      'tanphat.to@gmail.com': {'email': 'tanphat.to@gmail.com', 'name': 'Tô Tấn Phát', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 500, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 22)).toIso8601String()},
      'khanhlinh.chu@gmail.com': {'email': 'khanhlinh.chu@gmail.com', 'name': 'Chu Khánh Linh', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 350, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 23)).toIso8601String()},
      'thanhdat.quach@gmail.com': {'email': 'thanhdat.quach@gmail.com', 'name': 'Quách Thành Đạt', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 600, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 23)).toIso8601String()},
      'ngocanh.than@gmail.com': {'email': 'ngocanh.than@gmail.com', 'name': 'Thân Ngọc Ánh', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 450, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 24)).toIso8601String()},
      'huuphuoc.thai@gmail.com': {'email': 'huuphuoc.thai@gmail.com', 'name': 'Thái Hữu Phước', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 550, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 24)).toIso8601String()},
      'minhthuan.luu@gmail.com': {'email': 'minhthuan.luu@gmail.com', 'name': 'Lưu Minh Thuận', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 300, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 25)).toIso8601String()},
      'quynhtram.tieu@gmail.com': {'email': 'quynhtram.tieu@gmail.com', 'name': 'Tiêu Quỳnh Trâm', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 650, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 25)).toIso8601String()},
      'hoanghai.bach@gmail.com': {'email': 'hoanghai.bach@gmail.com', 'name': 'Bạch Hoàng Hải', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 400, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 26)).toIso8601String()},
      'bichthao.kieu@gmail.com': {'email': 'bichthao.kieu@gmail.com', 'name': 'Kiều Bích Thảo', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 500, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 26)).toIso8601String()},
      'vanhung.nong@gmail.com': {'email': 'vanhung.nong@gmail.com', 'name': 'Nông Văn Hùng', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 350, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 27)).toIso8601String()},
      'mylinh.thach@gmail.com': {'email': 'mylinh.thach@gmail.com', 'name': 'Thạch Mỹ Linh', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 600, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 27)).toIso8601String()},
      'thanhson.cu@gmail.com': {'email': 'thanhson.cu@gmail.com', 'name': 'Cù Thanh Sơn', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 450, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 28)).toIso8601String()},
      'ngocdiep.tonnu@gmail.com': {'email': 'ngocdiep.tonnu@gmail.com', 'name': 'Tôn Nữ Ngọc Diệp', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 550, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 28)).toIso8601String()},
      'tuankiet.on@gmail.com': {'email': 'tuankiet.on@gmail.com', 'name': 'Ôn Tuấn Kiệt', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 300, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 29)).toIso8601String()},
      'hoangyen.sign@gmail.com': {'email': 'hoangyen.sign@gmail.com', 'name': 'Hoàng Thị Yến', 'password': '***', 'isAdmin': false, 'isPro': false, 'coins': 850, 'reward_balance': 0, 'coin_redeem_note': '', 'has_coin_pro': false, 'expiresAt': null, 'created_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String()},
    };

    for (var entry in defaultUsers.entries) {
      final key = entry.key.toLowerCase();
      final existing = users[key];
      if (existing == null) {
        users[key] = entry.value;
      } else if (existing is Map) {
        final map = Map<String, dynamic>.from(existing);
        map['isPro'] = entry.value['isPro'];
        map['expiresAt'] = entry.value['expiresAt'];
        map['name'] = entry.value['name'] ?? map['name'];
        map['coins'] = entry.value['coins'] ?? 0;
        map['has_coin_pro'] = entry.value['has_coin_pro'] ?? false;
        map['coin_redeem_note'] = entry.value['coin_redeem_note'] ?? '';
        users[key] = map;
      }
    }
    await prefs.setString(_kUsersDbKey, jsonEncode(users));

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
        final hasCoinPro = m['has_coin_pro'] == true ||
            coinOrders.isNotEmpty ||
            (userCoinNote.isNotEmpty &&
                userCoinNote != 'Chưa dùng xu đổi Pro' &&
                !userCoinNote.startsWith('Chưa') &&
                !userCoinNote.startsWith('Đang tích lũy') &&
                userCoinNote != 'Tài khoản Quản trị viên');
        final coinProSummary = hasCoinPro
            ? (userCoinNote.isNotEmpty
                ? userCoinNote
                : 'Đã đổi ${coinOrders.length} lần Pro từ xu tích lũy')
            : '';

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
