import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../services/orders_storage.dart';
import '../theme.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _summary;
  List<dynamic> _orders = [];
  List<dynamic> _users = [];
  String _selectedTab = 'orders'; // 'orders' or 'users'
  String _filter = 'all'; // 'all', 'pending', 'paid', 'rejected'
  String _userFilter = 'all'; // 'all', 'pro', 'free', 'expired'
  String _searchQuery = '';
  bool _isVercelMode = false;
  String _currentApiUrl = '';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final base = await OrdersStorage.getApiBaseUrl();
    _currentApiUrl = base;

    if (base.isEmpty) {
      final localOrders = await OrdersStorage.loadLocalOrders();
      final localUsers = await OrdersStorage.loadLocalUsers();
      if (!mounted) return;
      final proCount = localUsers.where((u) => u['is_pro'] == true).length;
      final freeCount = localUsers.length - proCount;
      final totalCoins = localUsers.fold<int>(0, (sum, u) => sum + (int.tryParse(u['coins']?.toString() ?? '0') ?? 0));
      final coinRedeemUsers = localUsers.where((u) {
        final note = (u['coin_redeem_note'] ?? '').toString();
        return u['has_coin_pro'] == true || (note.isNotEmpty && note != 'Chưa dùng xu đổi Pro' && note != 'Đang tích lũy xu (chưa đổi Pro)');
      }).length;
      setState(() {
        _isVercelMode = true;
        _orders = localOrders;
        _users = localUsers;
        _summary = OrdersStorage.calculateSummary(
          localOrders,
          totalUsers: localUsers.length,
          proUsers: proCount,
          freeUsers: freeCount,
          totalCoins: totalCoins,
          coinRedeemUsers: coinRedeemUsers,
        );
        _loading = false;
      });
      return;
    }

    if (!mounted) return;
    const demoEmails = {
      'demo@signeye.vn',
      'user_demo@signeye.vn',
      'signeye.test2026@gmail.com',
      'thien123@gmail.com',
      'myduyen261104@gmail.com',
      'student.signeye@gmail.com',
      'ngocthien@signeye.vn',
    };

    try {
      final token = context.read<AppState>().authToken;
      final headers = {
        'Authorization': 'Bearer $token',
        'X-Admin-Key': 'Admin@123456',
      };

      // Tải đồng thời thống kê đơn hàng và danh sách người dùng
      final payFuture = http.get(Uri.parse('$base/admin/payments'), headers: headers).timeout(const Duration(seconds: 4));
      final usersFuture = http.get(Uri.parse('$base/admin/users'), headers: headers).timeout(const Duration(seconds: 4));

      final payResponse = await payFuture;
      List<dynamic> loadedUsers = [];

      try {
        final usersResponse = await usersFuture;
        if (usersResponse.statusCode == 200) {
          final uData = jsonDecode(utf8.decode(usersResponse.bodyBytes)) as Map<String, dynamic>;
          loadedUsers = uData['users'] as List<dynamic>? ?? [];
        } else {
          loadedUsers = await OrdersStorage.loadLocalUsers();
        }
      } catch (_) {
        loadedUsers = await OrdersStorage.loadLocalUsers();
      }

      if (loadedUsers.isEmpty) {
        loadedUsers = await OrdersStorage.loadLocalUsers();
      }
      loadedUsers = loadedUsers.where((u) => !demoEmails.contains((u['email'] ?? '').toString().toLowerCase())).toList();

      if (payResponse.statusCode == 200) {
        final data = jsonDecode(utf8.decode(payResponse.bodyBytes)) as Map<String, dynamic>;
        final rawOrders = data['orders'] as List<dynamic>? ?? [];
        final ordersList = rawOrders.where((o) => !demoEmails.contains((o['email'] ?? '').toString().toLowerCase())).toList();
        final summaryData = data['summary'] as Map<String, dynamic>? ?? {};

        // Đồng bộ các đơn hàng từ server về local
        if (ordersList.isNotEmpty) {
          final typedOrders = ordersList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          await OrdersStorage.saveLocalOrders(typedOrders);
        }

        if (mounted) {
          final usersListFinal = loadedUsers.isNotEmpty ? loadedUsers : _deriveUsersFromOrders(ordersList);
          final proCount = usersListFinal.where((u) => u['is_pro'] == true).length;
          final freeCount = usersListFinal.where((u) => u['is_pro'] != true && u['is_expired'] != true).length;
          final updatedSummary = Map<String, dynamic>.from(summaryData);
          updatedSummary['total_users'] = usersListFinal.length;
          updatedSummary['pro_users'] = proCount;
          updatedSummary['free_users'] = freeCount;
          setState(() {
            _isVercelMode = false;
            _summary = updatedSummary;
            _orders = ordersList;
            _users = usersListFinal;
          });
        }
      } else {
        final localOrders = await OrdersStorage.loadLocalOrders();
        final localUsers = await OrdersStorage.loadLocalUsers();
        if (mounted) {
          final proCount = localUsers.where((u) => u['is_pro'] == true).length;
          final freeCount = localUsers.length - proCount;
          final totalCoins = localUsers.fold<int>(0, (sum, u) => sum + (int.tryParse(u['coins']?.toString() ?? '0') ?? 0));
          final coinRedeemUsers = localUsers.where((u) {
            final note = (u['coin_redeem_note'] ?? '').toString();
            return u['has_coin_pro'] == true || (note.isNotEmpty && note != 'Chưa dùng xu đổi Pro' && note != 'Đang tích lũy xu (chưa đổi Pro)');
          }).length;
          setState(() {
            _isVercelMode = true;
            _orders = localOrders;
            _users = localUsers;
            _summary = OrdersStorage.calculateSummary(
              localOrders,
              totalUsers: localUsers.length,
              proUsers: proCount,
              freeUsers: freeCount,
              totalCoins: totalCoins,
              coinRedeemUsers: coinRedeemUsers,
            );
          });
        }
      }
    } catch (_) {
      final localOrders = await OrdersStorage.loadLocalOrders();
      final localUsers = await OrdersStorage.loadLocalUsers();
      if (mounted) {
        final proCount = localUsers.where((u) => u['is_pro'] == true).length;
        final freeCount = localUsers.length - proCount;
        final totalCoins = localUsers.fold<int>(0, (sum, u) => sum + (int.tryParse(u['coins']?.toString() ?? '0') ?? 0));
        final coinRedeemUsers = localUsers.where((u) {
          final note = (u['coin_redeem_note'] ?? '').toString();
          return u['has_coin_pro'] == true || (note.isNotEmpty && note != 'Chưa dùng xu đổi Pro' && note != 'Đang tích lũy xu (chưa đổi Pro)');
        }).length;
        setState(() {
          _isVercelMode = true;
          _orders = localOrders;
          _users = localUsers;
          _summary = OrdersStorage.calculateSummary(
            localOrders,
            totalUsers: localUsers.length,
            proUsers: proCount,
            freeUsers: freeCount,
            totalCoins: totalCoins,
            coinRedeemUsers: coinRedeemUsers,
          );
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> _deriveUsersFromOrders(List<dynamic> orders) {
    final seen = <String>{};
    final users = <Map<String, dynamic>>[];
    for (var o in orders) {
      final email = (o['email'] ?? '').toString();
      if (email.isNotEmpty && !seen.contains(email.toLowerCase())) {
        seen.add(email.toLowerCase());
        final isPro = o['status'] == 'paid';
        users.add({
          'id': email,
          'email': email,
          'name': (o['name'] ?? email.split('@').first).toString(),
          'created_at': o['created_at'],
          'is_pro': isPro,
          'is_expired': false,
          'account_type': isPro ? 'pro' : 'free',
          'status_label': isPro ? '👑 PRO VIP' : '🌱 Người dùng thường',
          'pro_expires_at': o['expiry_at'],
          'days_remaining': isPro ? 30 : 0,
          'latest_plan': o['plan'],
          'plan_label': o['plan'] == 'year' ? 'Gói 1 năm (399.000đ)' : 'Gói 1 tháng (39.000đ)',
          'total_orders': 1,
          'total_spent': isPro ? (int.tryParse(o['amount']?.toString() ?? '0') ?? 0) : 0,
        });
      }
    }
    return users;
  }

  Future<void> _decideOrder(dynamic id, String email, String name, bool approve) async {
    final strId = id.toString();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? 'Xác nhận duyệt Pro' : 'Xác nhận từ chối'),
        content: Text(
          approve
              ? 'Bạn có chắc chắn muốn kích hoạt gói Pro cho tài khoản:\n\n• Người dùng: $name\n• Email: $email\n• Mã đơn: #$strId\n\n(Vui lòng đảm bảo tiền đã về tài khoản ngân hàng thực tế)'
              : 'Bạn có chắc chắn muốn từ chối đơn hàng #$strId của $email?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? const Color(0xFF0D8F5C) : Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(approve ? 'Duyệt Pro ngay' : 'Từ chối'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 1. Luôn cập nhật local storage
    if (approve) {
      await OrdersStorage.approveOrder(strId);
    } else {
      await OrdersStorage.rejectOrder(strId);
    }

    // 2. Nếu có máy chủ backend, đồng bộ lên server
    if (_currentApiUrl.isNotEmpty && mounted) {
      try {
        final token = context.read<AppState>().authToken;
        final endpoint = approve ? 'confirm' : 'reject';
        await http.post(
          Uri.parse('$_currentApiUrl/admin/payments/$strId/$endpoint'),
          headers: {
            'Authorization': 'Bearer $token',
            'X-Admin-Key': 'Admin@123456',
          },
        ).timeout(const Duration(seconds: 4));
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: approve ? const Color(0xFF0D8F5C) : Colors.red,
          content: Text(approve ? '🎉 Đã duyệt Pro thành công cho $name ($email)!' : 'Đã từ chối đơn #$strId'),
        ),
      );
    }
    await _loadOrders();
  }

  Future<void> _grantProToUser(String usernameOrEmail, String plan) async {
    final clean = usernameOrEmail.trim().toLowerCase();
    final cleanEmail = clean.contains('@') ? clean : '$clean@signeye.vn';

    // 1. Cập nhật local storage
    await OrdersStorage.grantProUser(clean, plan: plan);
    final newOrder = {
      'id': 'SE${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      'email': cleanEmail,
      'name': clean.split('@').first,
      'plan': plan,
      'amount': plan == 'year' ? 399000 : 39000,
      'status': 'paid',
      'transfer_ref': 'SE${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      'created_at': DateTime.now().toIso8601String(),
      'paid_at': DateTime.now().toIso8601String(),
    };
    await OrdersStorage.addOrder(newOrder);

    // 2. Đồng bộ lên máy chủ nếu có kết nối
    if (_currentApiUrl.isNotEmpty && mounted) {
      try {
        final token = context.read<AppState>().authToken;
        await http.post(
          Uri.parse('$_currentApiUrl/admin/grant-pro'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'X-Admin-Key': 'Admin@123456',
          },
          body: jsonEncode({
            'username': clean,
            'plan': plan,
          }),
        ).timeout(const Duration(seconds: 4));
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0D8F5C),
          content: Text('🎉 Đã cấp quyền Pro (${plan == 'year' ? '1 năm' : '1 tháng'}) thành công cho $cleanEmail!'),
        ),
      );
    }
    await _loadOrders();
  }

  Future<void> _revokePro(String email, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Thu hồi quyền Pro', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn thu hồi quyền Pro của tài khoản:\n\n• Người dùng: $name\n• Email: $email\n\nTài khoản này sẽ chuyển về Người dùng thường (Free).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Thu hồi Pro ngay'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 1. Cập nhật local
    await OrdersStorage.revokeProUser(email);

    // 2. Đồng bộ server nếu có
    if (_currentApiUrl.isNotEmpty && mounted) {
      try {
        final token = context.read<AppState>().authToken;
        await http.post(
          Uri.parse('$_currentApiUrl/admin/revoke-pro'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'X-Admin-Key': 'Admin@123456',
          },
          body: jsonEncode({'username': email}),
        ).timeout(const Duration(seconds: 4));
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange.shade800,
          content: Text('Đã thu hồi quyền Pro của $name ($email), chuyển về Người dùng thường!'),
        ),
      );
    }
    await _loadOrders();
  }

  Future<void> _deleteUser(String email, String name) async {
    final clean = email.trim().toLowerCase();
    if (clean == 'admin@signeye.vn' || clean == 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.red, content: Text('Không thể xóa tài khoản Quản trị viên hệ thống!')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Xóa tài khoản người dùng', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        content: Text('Bạn có chắc chắn muốn xóa vĩnh viễn tài khoản:\n\n• Người dùng: $name\n• Email: $email\n\nToàn bộ dữ liệu của người dùng này sẽ bị xóa khỏi hệ thống.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa người dùng'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 1. Cập nhật local
    await OrdersStorage.deleteUser(clean);

    // 2. Cập nhật server nếu có
    if (_currentApiUrl.isNotEmpty && mounted) {
      try {
        final token = context.read<AppState>().authToken;
        await http.delete(
          Uri.parse('$_currentApiUrl/admin/users/$clean'),
          headers: {
            'Authorization': 'Bearer $token',
            'X-Admin-Key': 'Admin@123456',
          },
        ).timeout(const Duration(seconds: 4));
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xóa tài khoản $name ($email)')),
      );
    }
    await _loadOrders();
  }

  void _showCreateUserDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: '123456');
    final coinsCtrl = TextEditingController(text: '0');
    bool isPro = false;
    String plan = 'month';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF0D8F5C)),
              SizedBox(width: 8),
              Text('Thêm Người Dùng Mới', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Họ và tên', hintText: 'VD: Nguyễn Văn A', prefixIcon: Icon(Icons.badge_outlined)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email đăng nhập', hintText: 'VD: user@signeye.vn', prefixIcon: Icon(Icons.email_outlined)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passCtrl,
                  decoration: const InputDecoration(labelText: 'Mật khẩu', hintText: 'Mặc định: 123456', prefixIcon: Icon(Icons.lock_outline)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: coinsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Số xu ban đầu', hintText: '0', prefixIcon: Icon(Icons.monetization_on_outlined)),
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Kích hoạt Pro ngay', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  subtitle: const Text('Cấp ngay đặc quyền Pro VIP', style: TextStyle(fontSize: 12)),
                  value: isPro,
                  activeColor: const Color(0xFF0D8F5C),
                  onChanged: (val) => setDlgState(() => isPro = val),
                ),
                if (isPro) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('1 Tháng (39k)')),
                          selected: plan == 'month',
                          selectedColor: const Color(0xFFDEF7EC),
                          onSelected: (val) {
                            if (val) setDlgState(() => plan = 'month');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('1 Năm (399k)')),
                          selected: plan == 'year',
                          selectedColor: const Color(0xFFDEF7EC),
                          onSelected: (val) {
                            if (val) setDlgState(() => plan = 'year');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D8F5C), foregroundColor: Colors.white),
              onPressed: () async {
                final email = emailCtrl.text.trim().toLowerCase();
                final name = nameCtrl.text.trim();
                final pass = passCtrl.text.trim();
                final coins = int.tryParse(coinsCtrl.text.trim()) ?? 0;

                if (email.isEmpty || !email.contains('@')) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập email hợp lệ!')));
                  return;
                }

                Navigator.pop(ctx);

                // 1. Lưu local
                await OrdersStorage.createUser(
                  email: email,
                  name: name.isNotEmpty ? name : email.split('@').first,
                  password: pass.isNotEmpty ? pass : '123456',
                  isPro: isPro,
                  plan: plan,
                  coins: coins,
                );

                // 2. Lưu server nếu có kết nối
                if (_currentApiUrl.isNotEmpty && mounted) {
                  try {
                    final token = context.read<AppState>().authToken;
                    await http.post(
                      Uri.parse('$_currentApiUrl/admin/users'),
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Bearer $token',
                        'X-Admin-Key': 'Admin@123456',
                      },
                      body: jsonEncode({
                        'email': email,
                        'name': name.isNotEmpty ? name : email.split('@').first,
                        'password': pass.isNotEmpty ? pass : '123456',
                        'is_pro': isPro,
                        'plan': plan,
                        'coins': coins,
                      }),
                    ).timeout(const Duration(seconds: 4));
                  } catch (_) {}
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(backgroundColor: const Color(0xFF0D8F5C), content: Text('🎉 Đã thêm người dùng $name ($email)!')),
                  );
                }
                await _loadOrders();
              },
              child: const Text('Tạo tài khoản'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> u) {
    final email = (u['email'] ?? '').toString();
    final nameCtrl = TextEditingController(text: (u['name'] ?? '').toString());
    final coinsCtrl = TextEditingController(text: (u['coins'] ?? '0').toString());
    bool isPro = u['is_pro'] == true;
    String plan = 'month';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Sửa Thông Tin: $email', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Họ và tên', prefixIcon: Icon(Icons.badge_outlined)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: coinsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Số xu tích lũy', prefixIcon: Icon(Icons.monetization_on_outlined)),
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Trạng thái Pro VIP', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  subtitle: Text(isPro ? 'Đang bật Pro VIP' : 'Người dùng thường (Free)', style: const TextStyle(fontSize: 12)),
                  value: isPro,
                  activeColor: const Color(0xFF0D8F5C),
                  onChanged: (val) => setDlgState(() => isPro = val),
                ),
                if (isPro) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Gói 1 Tháng')),
                          selected: plan == 'month',
                          selectedColor: const Color(0xFFDEF7EC),
                          onSelected: (val) {
                            if (val) setDlgState(() => plan = 'month');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Gói 1 Năm')),
                          selected: plan == 'year',
                          selectedColor: const Color(0xFFDEF7EC),
                          onSelected: (val) {
                            if (val) setDlgState(() => plan = 'year');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final coins = int.tryParse(coinsCtrl.text.trim()) ?? 0;

                Navigator.pop(ctx);

                // 1. Cập nhật local
                await OrdersStorage.updateUser(
                  email: email,
                  name: name,
                  coins: coins,
                  isPro: isPro,
                  plan: plan,
                );

                // 2. Cập nhật server nếu có
                if (_currentApiUrl.isNotEmpty && mounted) {
                  try {
                    final token = context.read<AppState>().authToken;
                    await http.put(
                      Uri.parse('$_currentApiUrl/admin/users/$email'),
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Bearer $token',
                        'X-Admin-Key': 'Admin@123456',
                      },
                      body: jsonEncode({
                        'name': name,
                        'coins': coins,
                        'is_pro': isPro,
                        'plan': plan,
                      }),
                    ).timeout(const Duration(seconds: 4));
                  } catch (_) {}
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(backgroundColor: const Color(0xFF2563EB), content: Text('Đã cập nhật thông tin người dùng $name ($email)!')),
                  );
                }
                await _loadOrders();
              },
              child: const Text('Lưu thay đổi'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGrantProDialog([String? defaultUser]) {
    String selectedEmail = defaultUser ?? '';
    final searchCtrl = TextEditingController(text: defaultUser ?? '');
    String selectedPlan = 'month';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final query = searchCtrl.text.trim().toLowerCase();
          final matchingUsers = _users.where((u) {
            final email = (u['email'] ?? '').toString().toLowerCase();
            final name = (u['name'] ?? '').toString().toLowerCase();
            if (query.isEmpty) return true;
            return email.contains(query) || name.contains(query);
          }).toList();

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.workspace_premium_rounded, color: Color(0xFF0D8F5C)),
                SizedBox(width: 8),
                Text('Cấp quyền SignEye Pro', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chọn người dùng đã đăng ký để cấp / gia hạn Pro:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Tìm theo tên hoặc email đã đăng ký...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onChanged: (val) {
                      setDlgState(() {});
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Danh sách tài khoản đề xuất (nhấn để chọn):',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: matchingUsers.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                '⚠️ Không tìm thấy người dùng đã đăng ký phù hợp.\nChỉ có thể cấp Pro cho tài khoản đã có trên hệ thống.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: matchingUsers.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                            itemBuilder: (ctx, i) {
                              final u = matchingUsers[i];
                              final email = (u['email'] ?? '').toString();
                              final name = (u['name'] ?? email.split('@').first).toString();
                              final isPro = u['is_pro'] == true;
                              final isSelected = selectedEmail.toLowerCase() == email.toLowerCase();

                              return ListTile(
                                dense: true,
                                selected: isSelected,
                                selectedTileColor: const Color(0xFFDEF7EC),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: isPro ? const Color(0xFFDEF7EC) : const Color(0xFFE2E8F0),
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isPro ? const Color(0xFF0D8F5C) : Colors.black87),
                                  ),
                                ),
                                title: Text(name, style: TextStyle(fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, fontSize: 13)),
                                subtitle: Text(email, style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isPro ? const Color(0xFFDEF7EC) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isPro ? '👑 Pro' : '🌱 Thường',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isPro ? const Color(0xFF0D8F5C) : Colors.black54),
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 6),
                                      const Icon(Icons.check_circle_rounded, color: Color(0xFF0D8F5C), size: 18),
                                    ],
                                  ],
                                ),
                                onTap: () {
                                  setDlgState(() {
                                    selectedEmail = email;
                                    searchCtrl.text = email;
                                  });
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Chọn thời hạn kích hoạt Pro:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('1 Tháng (39k)')),
                          selected: selectedPlan == 'month',
                          selectedColor: const Color(0xFFDEF7EC),
                          labelStyle: TextStyle(fontWeight: FontWeight.w700, color: selectedPlan == 'month' ? const Color(0xFF0D8F5C) : Colors.black87),
                          onSelected: (val) {
                            if (val) setDlgState(() => selectedPlan = 'month');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('1 Năm (399k)')),
                          selected: selectedPlan == 'year',
                          selectedColor: const Color(0xFFDEF7EC),
                          labelStyle: TextStyle(fontWeight: FontWeight.w700, color: selectedPlan == 'year' ? const Color(0xFF0D8F5C) : Colors.black87),
                          onSelected: (val) {
                            if (val) setDlgState(() => selectedPlan = 'year');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D8F5C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  final target = (selectedEmail.isNotEmpty ? selectedEmail : searchCtrl.text).trim();
                  if (target.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng chọn một tài khoản người dùng đã đăng ký')),
                    );
                    return;
                  }

                  // Kiểm tra tài khoản có nằm trong danh sách đã đăng ký không
                  final clean = target.toLowerCase();
                  final userExists = _users.any((u) {
                    final e = (u['email'] ?? '').toString().toLowerCase();
                    return e == clean || e == '$clean@signeye.vn';
                  });

                  if (!userExists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.red.shade700,
                        content: Text('⚠️ Tài khoản "$target" chưa đăng ký! Chỉ có thể cấp Pro cho người dùng đã đăng ký tài khoản (hoặc hãy nhấn "Thêm User" trước).'),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(ctx);
                  _grantProToUser(target, selectedPlan);
                },
                child: const Text('Kích hoạt Pro ngay'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showApiConfigDialog() async {
    final current = await OrdersStorage.getApiBaseUrl();
    final ctrl = TextEditingController(text: current);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.settings_ethernet_rounded, color: Color(0xFF0D8F5C)),
            SizedBox(width: 8),
            Text('Cấu hình URL Máy chủ API', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Máy chủ backend chính thức hiện tại là: https://signeye.onrender.com. Bạn có thể nhập URL khác nếu muốn kiểm thử local.',
              style: TextStyle(fontSize: 12.5, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: InputDecoration(
                hintText: 'https://signeye.onrender.com',
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D8F5C),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await OrdersStorage.setApiBaseUrl(ctrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              _loadOrders();
            },
            child: const Text('Lưu cấu hình'),
          ),
        ],
      ),
    );
  }

  String _formatMoney(dynamic amount) {
    final numVal = int.tryParse(amount?.toString() ?? '0') ?? 0;
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(numVal);
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _orders.where((o) {
      final status = (o['status'] ?? '').toString();
      if (_filter == 'pending' && !(status == 'pending' || status == 'submitted')) return false;
      if (_filter == 'paid' && status != 'paid') return false;
      if (_filter == 'rejected' && status != 'rejected') return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (o['name'] ?? '').toString().toLowerCase();
        final email = (o['email'] ?? '').toString().toLowerCase();
        final ref = (o['transfer_ref'] ?? '').toString().toLowerCase();
        final id = (o['id'] ?? '').toString().toLowerCase();
        if (!name.contains(q) && !email.contains(q) && !ref.contains(q) && !id.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    final filteredUsers = _users.where((u) {
      final emailClean = (u['email'] ?? '').toString().toLowerCase();
      if (emailClean == 'admin@signeye.vn' || emailClean == 'admin' || emailClean.startsWith('admin@')) return false;
      final isPro = u['is_pro'] == true;
      final isExpired = u['is_expired'] == true;
      final note = (u['coin_redeem_note'] ?? '').toString();
      final hasCoinPro = u['has_coin_pro'] == true ||
          (note.isNotEmpty &&
              note != 'Chưa dùng xu đổi Pro' &&
              note != 'Đang tích lũy xu (chưa đổi Pro)');
      if (_userFilter == 'pro' && !isPro) return false;
      if (_userFilter == 'free' && (isPro || isExpired)) return false;
      if (_userFilter == 'expired' && !isExpired) return false;
      if (_userFilter == 'coin_redeem' && !hasCoinPro) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (u['name'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        return name.contains(q) || email.contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        title: const Text('Quản trị SignEye Pro', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
            label: const Text('+ Thêm User'),
            onPressed: _showCreateUserDialog,
          ),
          const SizedBox(width: 6),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D8F5C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            icon: const Icon(Icons.flash_on_rounded, size: 16),
            label: const Text('Cấp Pro'),
            onPressed: () => _showGrantProDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_ethernet_rounded),
            tooltip: 'Cấu hình API Backend',
            onPressed: _showApiConfigDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
            onPressed: _loading ? null : _loadOrders,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Đăng xuất Admin',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Đăng xuất Quản trị viên'),
                  content: const Text('Bạn có chắc chắn muốn đăng xuất tài khoản Admin?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Đăng xuất'),
                    ),
                  ],
                ),
              );
              if (confirm == true && mounted) {
                await context.read<AppState>().logout();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isVercelMode)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.cloud_done_rounded, color: Color(0xFF2563EB), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chế độ Vercel / Hoạt động độc lập',
                            style: TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Duyệt đơn và quản lý người dùng trực tiếp trên trình duyệt thiết bị.',
                            style: TextStyle(color: Color(0xFF3B82F6), fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: _showApiConfigDialog,
                      child: const Text('Cấu hình API', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            if (_summary != null) _buildSummaryCards(),
            const SizedBox(height: 16),
            _buildTabSelector(),
            const SizedBox(height: 12),
            _buildSearchAndFilters(),
            const SizedBox(height: 16),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                  ],
                ),
              ),
            if (_loading && _orders.isEmpty && _users.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_selectedTab == 'orders') ...[
              if (filteredOrders.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.inbox_outlined, size: 54, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'Không tìm thấy đơn hàng nào',
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                )
              else
                for (final o in filteredOrders) _buildOrderCard(o),
            ] else ...[
              if (filteredUsers.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.people_outline, size: 54, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'Không tìm thấy người dùng nào',
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                )
              else
                for (final u in filteredUsers) _buildUserCard(Map<String, dynamic>.from(u as Map)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final purchases = _summary?['purchases'] ?? '0';
    final revenue = _formatMoney(_summary?['revenue']);
    final pendingCount = _orders.where((o) => o['status'] == 'pending' || o['status'] == 'submitted').length;
    final totalUsers = (_summary?['total_users'] ?? _users.length.toString()).toString();
    final proUsers = (_summary?['pro_users'] ?? _users.where((u) => u['is_pro'] == true).length.toString()).toString();
    final freeUsers = (_summary?['free_users'] ?? _users.where((u) => u['is_pro'] != true).length.toString()).toString();

    final totalCoins = _users.fold<int>(0, (sum, u) => sum + (int.tryParse(u['coins']?.toString() ?? '0') ?? 0));
    final coinRedeemUsers = _users.where((u) => u['has_coin_pro'] == true).length;

    final items = [
      _summaryBox('Tổng người dùng', totalUsers, const Color(0xFF2563EB), const Color(0xFFEFF6FF), Icons.people_alt_rounded),
      _summaryBox('👑 Người dùng Pro', proUsers, const Color(0xFF0D8F5C), const Color(0xFFDEF7EC), Icons.workspace_premium_rounded),
      _summaryBox('🌱 Người dùng thường', freeUsers, const Color(0xFF475569), const Color(0xFFF1F5F9), Icons.person_outline_rounded),
      _summaryBox('Chờ duyệt Pro', '$pendingCount', const Color(0xFFD97706), const Color(0xFFFEF3C7), Icons.hourglass_top_rounded),
      _summaryBox('Đơn đã duyệt', '$purchases', const Color(0xFF059669), const Color(0xFFECFDF5), Icons.verified_rounded),
      _summaryBox('Tổng doanh thu', revenue, const Color(0xFF4F46E5), const Color(0xFFEEF2FF), Icons.payments_rounded),
      _summaryBox('🪙 Xu tích lũy toàn hệ thống', '${NumberFormat("#,###", "vi").format(totalCoins)} xu', const Color(0xFFD97706), const Color(0xFFFEF3C7), Icons.monetization_on_rounded),
      _summaryBox('🪙 Đã đổi Pro bằng xu', '$coinRedeemUsers tài khoản', const Color(0xFF0D8F5C), const Color(0xFFDEF7EC), Icons.redeem_rounded),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final int crossAxisCount = w < 620 ? 2 : (w < 980 ? 3 : 4);
        final double itemWidth = (w - (crossAxisCount - 1) * 10) / crossAxisCount;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.map((widget) => SizedBox(width: itemWidth, child: widget)).toList(),
        );
      },
    );
  }

  Widget _summaryBox(String title, String value, Color textCol, Color bgCol, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: bgCol,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: textCol.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: textCol, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: textCol.withOpacity(0.85), fontSize: 11.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(color: textCol, fontSize: 16, fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = 'orders'),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 'orders' ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedTab == 'orders'
                      ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Center(
                  child: Text(
                    '📋 Đơn hàng (${_orders.length})',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: _selectedTab == 'orders' ? AppColors.primary : AppColors.text2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = 'users'),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 'users' ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedTab == 'users'
                      ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Center(
                  child: Text(
                    '👥 Người dùng (${_users.length})',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: _selectedTab == 'users' ? AppColors.primary : AppColors.text2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    final proCount = _users.where((u) => u['is_pro'] == true).length;
    final freeCount = _users.where((u) => u['is_pro'] != true && u['is_expired'] != true).length;
    final expiredCount = _users.where((u) => u['is_expired'] == true).length;

    final coinRedeemCount = _users.where((u) {
      final note = (u['coin_redeem_note'] ?? '').toString();
      return u['has_coin_pro'] == true ||
          (note.isNotEmpty &&
              note != 'Chưa dùng xu đổi Pro' &&
              note != 'Đang tích lũy xu (chưa đổi Pro)');
    }).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: _selectedTab == 'orders' ? 'Tìm theo Tên, Email, Mã chuyển khoản...' : 'Tìm theo Họ tên hoặc Email người dùng...',
            prefixIcon: const Icon(Icons.search, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
          onChanged: (v) => setState(() => _searchQuery = v.trim()),
        ),
        const SizedBox(height: 10),
        if (_selectedTab == 'orders')
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('Tất cả', 'all'),
                const SizedBox(width: 8),
                _filterChip('Chờ duyệt', 'pending'),
                const SizedBox(width: 8),
                _filterChip('Đã duyệt Pro', 'paid'),
                const SizedBox(width: 8),
                _filterChip('Từ chối', 'rejected'),
              ],
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _userFilterChip('Tất cả (${_users.length})', 'all'),
                const SizedBox(width: 8),
                _userFilterChip('👑 Người dùng Pro ($proCount)', 'pro'),
                const SizedBox(width: 8),
                _userFilterChip('🌱 Người dùng Thường ($freeCount)', 'free'),
                const SizedBox(width: 8),
                _userFilterChip('🪙 Đổi Pro bằng xu ($coinRedeemCount)', 'coin_redeem'),
                if (expiredCount > 0) ...[
                  const SizedBox(width: 8),
                  _userFilterChip('⚠️ Hết hạn Pro ($expiredCount)', 'expired'),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _userFilterChip(String label, String value) {
    final active = _userFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: active,
      labelStyle: TextStyle(
        color: active ? Colors.white : AppColors.text,
        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFE2E8F0))),
      onSelected: (_) => setState(() => _userFilter = value),
    );
  }

  Widget _filterChip(String label, String value) {
    final active = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: active,
      labelStyle: TextStyle(
        color: active ? Colors.white : AppColors.text,
        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFE2E8F0))),
      onSelected: (_) => setState(() => _filter = value),
    );
  }

  Widget _buildOrderCard(dynamic o) {
    final rawId = o['id'];
    final id = (rawId ?? '').toString();
    final status = (o['status'] ?? '').toString();
    final name = (o['name'] ?? 'Người dùng').toString();
    final email = (o['email'] ?? '').toString();
    final plan = (o['plan'] ?? 'month').toString();
    final amount = o['amount'];
    final ref = (o['transfer_ref'] ?? id).toString();
    final createdAt = (o['created_at'] ?? '').toString();

    final isPaid = status == 'paid';
    final isPending = status == 'pending' || status == 'submitted';
    final isCoinOrder = (o['payment_method'] == 'coins' || ref.startsWith('DoiXu') || id.startsWith('XU_'));
    final adminNote = (o['admin_note'] ?? '').toString();

    Color badgeBg;
    Color badgeText;
    String statusLabel;

    if (isCoinOrder) {
      badgeBg = const Color(0xFFFEF3C7);
      badgeText = const Color(0xFFB45309);
      statusLabel = '🪙 Đổi bằng xu';
    } else if (isPaid) {
      badgeBg = const Color(0xFFDEF7EC);
      badgeText = const Color(0xFF03543F);
      statusLabel = 'Đã duyệt Pro';
    } else if (status == 'submitted') {
      badgeBg = const Color(0xFFFEF3C7);
      badgeText = const Color(0xFF92400E);
      statusLabel = 'Chờ Admin duyệt';
    } else if (status == 'pending') {
      badgeBg = const Color(0xFFFEF08A);
      badgeText = const Color(0xFF854D0E);
      statusLabel = 'Chờ thanh toán';
    } else {
      badgeBg = const Color(0xFFFEE2E2);
      badgeText = const Color(0xFF991B1B);
      statusLabel = 'Từ chối';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isCoinOrder ? const Color(0xFFFDE68A) : (isPending ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Đơn #$id', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(12)),
                child: Text(statusLabel, style: TextStyle(color: badgeText, fontWeight: FontWeight.w800, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Người mua: ',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
              ),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.email_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                'Email: ',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              Expanded(
                child: Text(email, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(isCoinOrder ? Icons.monetization_on : Icons.card_membership, size: 16, color: isCoinOrder ? const Color(0xFFD97706) : Colors.indigo),
              const SizedBox(width: 6),
              Text(
                isCoinOrder
                    ? 'Hình thức: Đổi từ xu minigame (${plan.replaceAll('_days', ' ngày').replaceAll('_ngay', ' ngày')})'
                    : 'Gói: ${plan == 'year' ? '1 năm' : '1 tháng'} · ${_formatMoney(amount)}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isCoinOrder ? const Color(0xFFB45309) : const Color(0xFF4F46E5)),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.qr_code, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text('Nội dung: ', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFEDF2F7), borderRadius: BorderRadius.circular(6)),
                child: Text(ref, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, fontFamily: 'monospace', color: Colors.black87)),
              ),
            ],
          ),
          if (adminNote.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Text(
                '📝 Ghi chú: $adminNote',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                createdAt.length >= 16 ? createdAt.substring(0, 16).replaceAll('T', ' ') : createdAt,
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
              ),
              if (isPending)
                Row(
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () => _decideOrder(id, email, name, false),
                      child: const Text('Từ chối', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D8F5C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () => _decideOrder(id, email, name, true),
                      child: const Text('Duyệt Pro', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                    ),
                  ],
                )
              else if (isPaid)
                const Text('✓ Đã cấp Pro cho user', style: TextStyle(color: Color(0xFF0D8F5C), fontWeight: FontWeight.w800, fontSize: 12))
              else
                const Text('Đã từ chối', style: TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> u) {
    final name = (u['name'] ?? 'Người dùng').toString();
    final email = (u['email'] ?? '').toString();
    final isPro = u['is_pro'] == true;
    final isExpired = u['is_expired'] == true;
    final createdAt = (u['created_at'] ?? '').toString();
    final proExpiry = (u['pro_expires_at'] ?? '').toString();
    final daysRemaining = int.tryParse(u['days_remaining']?.toString() ?? '0') ?? 0;
    final totalSpent = int.tryParse(u['total_spent']?.toString() ?? '0') ?? 0;
    final totalOrders = int.tryParse(u['total_orders']?.toString() ?? '0') ?? 0;
    final planLabel = (u['plan_label'] ?? (isPro ? 'Gói 1 tháng (39.000đ)' : 'Chưa đăng ký')).toString();
    final coins = int.tryParse(u['coins']?.toString() ?? '0') ?? 0;
    final rewardBalance = int.tryParse(u['reward_balance']?.toString() ?? '0') ?? 0;
    final coinNote = (u['coin_redeem_note'] ?? '').toString();
    final hasCoinPro = u['has_coin_pro'] == true;

    Color cardBorder;
    Color badgeBg;
    Color badgeText;
    String badgeTitle;

    if (isPro) {
      cardBorder = const Color(0xFF10B981);
      badgeBg = const Color(0xFFDEF7EC);
      badgeText = const Color(0xFF03543F);
      badgeTitle = '👑 PRO VIP';
    } else if (isExpired) {
      cardBorder = const Color(0xFFF97316);
      badgeBg = const Color(0xFFFEF3C7);
      badgeText = const Color(0xFF92400E);
      badgeTitle = '⚠️ Hết hạn Pro';
    } else {
      cardBorder = const Color(0xFFE2E8F0);
      badgeBg = const Color(0xFFF1F5F9);
      badgeText = const Color(0xFF64748B);
      badgeTitle = '🌱 Người dùng thường';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: isPro ? 1.5 : 1.0),
        boxShadow: [
          BoxShadow(
            color: isPro ? const Color(0xFF0D8F5C).withOpacity(0.06) : Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: isPro ? const Color(0xFFDEF7EC) : const Color(0xFFF1F5F9),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isPro ? const Color(0xFF0D8F5C) : const Color(0xFF64748B),
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (isPro)
                    const Positioned(
                      right: -2,
                      top: -4,
                      child: Text('👑', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badgeTitle,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: badgeText,
                            ),
                          ),
                        ),
                        if (hasCoinPro) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: const Text(
                              '🪙 Đổi Pro bằng xu',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.text2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      isPro ? Icons.workspace_premium_rounded : Icons.star_border_rounded,
                      size: 15,
                      color: isPro ? const Color(0xFF0D8F5C) : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Gói dịch vụ: ',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                    ),
                    Expanded(
                      child: Text(
                        isPro ? planLabel : (isExpired ? 'Đã hết hạn Pro' : 'Tài khoản miễn phí (Free)'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isPro ? const Color(0xFF0D8F5C) : (isExpired ? const Color(0xFFD97706) : Colors.black87),
                        ),
                      ),
                    ),
                  ],
                ),
                if (isPro && proExpiry.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 15, color: Color(0xFF0D8F5C)),
                      const SizedBox(width: 6),
                      Text('Thời hạn còn lại: ', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      Expanded(
                        child: Text(
                          'Còn $daysRemaining ngày (Hết hạn: ${proExpiry.length >= 10 ? proExpiry.substring(0, 10) : proExpiry})',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0D8F5C)),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 15, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text('Lịch sử nạp: ', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    Expanded(
                      child: Text(
                        totalSpent > 0 ? '${_formatMoney(totalSpent)} ($totalOrders đơn hàng)' : 'Chưa phát sinh giao dịch (0đ)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: totalSpent > 0 ? const Color(0xFF4F46E5) : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (createdAt.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text('Ngày tham gia: ', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      Expanded(
                        child: Text(
                          createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt,
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.monetization_on_rounded, size: 15, color: Color(0xFFD97706)),
                    const SizedBox(width: 6),
                    Text('Xu tích lũy: ', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    Expanded(
                      child: Text(
                        '${NumberFormat("#,###", "vi").format(coins)} xu${rewardBalance > 0 ? " (Đã đổi ${NumberFormat("#,###", "vi").format(rewardBalance)}đ)" : ""}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ],
                ),
                if (hasCoinPro && coinNote.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🪙 ', style: TextStyle(fontSize: 13)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ghi chú đổi Pro bằng xu:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                coinNote,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF78350F),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text('Sửa'),
                onPressed: () => _showEditUserDialog(u),
              ),
              if (email.toLowerCase() != 'admin@signeye.vn')
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 14),
                  label: const Text('Xóa'),
                  onPressed: () => _deleteUser(email, name),
                ),
              if (isPro)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade800,
                    side: const BorderSide(color: Color(0xFFFED7AA)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                  icon: const Icon(Icons.remove_circle_outline, size: 14),
                  label: const Text('Thu hồi Pro'),
                  onPressed: () => _revokePro(email, name),
                ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPro ? const Color(0xFFEFF6FF) : const Color(0xFF0D8F5C),
                  foregroundColor: isPro ? const Color(0xFF2563EB) : Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
                icon: Icon(isPro ? Icons.autorenew_rounded : Icons.flash_on_rounded, size: 14),
                label: Text(isPro ? 'Gia hạn Pro' : '⚡ Kích hoạt Pro'),
                onPressed: () => _showGrantProDialog(email),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
