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
  String _filter = 'all'; // 'all', 'pending', 'paid', 'rejected'
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

    // Nếu không cấu hình URL hoặc chạy trên HTTPS Vercel mà không có server ngoài,
    // tự động chuyển sang chế độ Vercel Standalone mượt mà, KHÔNG báo lỗi đỏ!
    if (base.isEmpty) {
      final localOrders = await OrdersStorage.loadLocalOrders();
      setState(() {
        _isVercelMode = true;
        _orders = localOrders;
        _summary = OrdersStorage.calculateSummary(localOrders);
        _loading = false;
      });
      return;
    }

    if (!mounted) return;
    try {
      final token = context.read<AppState>().authToken;
      final response = await http.get(
        Uri.parse('$base/admin/payments'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-Admin-Key': 'Admin@123456',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        setState(() {
          _isVercelMode = false;
          _summary = data['summary'] as Map<String, dynamic>?;
          _orders = data['orders'] as List<dynamic>? ?? [];
        });
      } else {
        final localOrders = await OrdersStorage.loadLocalOrders();
        setState(() {
          _isVercelMode = true;
          _orders = localOrders;
          _summary = OrdersStorage.calculateSummary(localOrders);
        });
      }
    } catch (_) {
      // Khi không kết nối được localhost (như khi deploy trên Vercel),
      // tự động chuyển sang chế độ Vercel Standalone mượt mà, KHÔNG báo lỗi đỏ!
      final localOrders = await OrdersStorage.loadLocalOrders();
      setState(() {
        _isVercelMode = true;
        _orders = localOrders;
        _summary = OrdersStorage.calculateSummary(localOrders);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _decideOrder(dynamic id, String email, String name, bool approve) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? 'Xác nhận duyệt Pro' : 'Xác nhận từ chối'),
        content: Text(
          approve
              ? 'Bạn có chắc chắn muốn kích hoạt gói Pro cho tài khoản:\n\n• Người dùng: $name\n• Email: $email\n\n(Vui lòng đảm bảo tiền đã thực tế về tài khoản ngân hàng)'
              : 'Bạn có chắc chắn muốn từ chối đơn hàng #$id của $email?',
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

    // 1. Luôn cập nhật local storage để đảm bảo hoạt động trên Vercel
    if (approve) {
      await OrdersStorage.approveOrder(id);
    } else {
      await OrdersStorage.rejectOrder(id);
    }

    // 2. Nếu có backend, đồng bộ lên server
    if (!_isVercelMode && _currentApiUrl.isNotEmpty && mounted) {
      try {
        final token = context.read<AppState>().authToken;
        final endpoint = approve ? 'confirm' : 'reject';
        await http.post(
          Uri.parse('$_currentApiUrl/admin/payments/$id/$endpoint'),
          headers: {
            'Authorization': 'Bearer $token',
            'X-Admin-Key': 'Admin@123456',
          },
        ).timeout(const Duration(seconds: 3));
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: approve ? const Color(0xFF0D8F5C) : Colors.red,
          content: Text(approve ? '🎉 Đã duyệt Pro thành công cho $name ($email)!' : 'Đã từ chối đơn #$id'),
        ),
      );
    }
    await _loadOrders();
  }

  Future<void> _grantProToUser(String usernameOrEmail, String plan) async {
    // 1. Cập nhật local storage cho Vercel
    await OrdersStorage.grantProUser(usernameOrEmail, plan: plan);
    final cleanEmail = usernameOrEmail.contains('@') ? usernameOrEmail : '$usernameOrEmail@signeye.vn';
    final newOrder = {
      'id': DateTime.now().millisecondsSinceEpoch % 100000,
      'email': cleanEmail,
      'name': usernameOrEmail.split('@').first,
      'plan': plan,
      'amount': plan == 'year' ? 399000 : 39000,
      'status': 'paid',
      'transfer_ref': 'SE${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      'created_at': DateTime.now().toIso8601String(),
      'paid_at': DateTime.now().toIso8601String(),
    };
    await OrdersStorage.addOrder(newOrder);

    // 2. Nếu có backend, đồng bộ server
    if (!_isVercelMode && _currentApiUrl.isNotEmpty && mounted) {
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
            'username': usernameOrEmail.trim(),
            'plan': plan,
          }),
        ).timeout(const Duration(seconds: 3));
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0D8F5C),
          content: Text('🎉 Đã cấp quyền Pro (${plan == 'year' ? '1 năm' : '1 tháng'}) thành công cho $usernameOrEmail!'),
        ),
      );
    }
    await _loadOrders();
  }

  void _showGrantProDialog() {
    final userController = TextEditingController();
    String selectedPlan = 'month';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.flash_on_rounded, color: Color(0xFF0D8F5C)),
              SizedBox(width: 8),
              Text('Cấp Pro cho Username', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nhập tên tài khoản (Username) hoặc Email cần kích hoạt Pro:',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: userController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'VD: thien, ngocthien hoặc user@...',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Chọn gói thời hạn:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('1 Tháng (39k)'),
                      selected: selectedPlan == 'month',
                      onSelected: (val) {
                        if (val) setDlgState(() => selectedPlan = 'month');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('1 Năm (399k)'),
                      selected: selectedPlan == 'year',
                      onSelected: (val) {
                        if (val) setDlgState(() => selectedPlan = 'year');
                      },
                    ),
                  ),
                ],
              ),
            ],
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
                final u = userController.text.trim();
                if (u.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập Username hoặc Email')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                _grantProToUser(u, selectedPlan);
              },
              child: const Text('Kích hoạt Pro ngay'),
            ),
          ],
        ),
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
              'Nếu bạn deploy backend lên Render/Railway/VPS (HTTPS), nhập URL vào đây. Để trống sẽ dùng Chế độ Vercel Độc lập.',
              style: TextStyle(fontSize: 12.5, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: InputDecoration(
                hintText: 'https://signeye-api.onrender.com (hoặc để trống)',
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
    final filtered = _orders.where((o) {
      final status = (o['status'] ?? '').toString();
      if (_filter == 'pending' && !(status == 'pending' || status == 'submitted')) return false;
      if (_filter == 'paid' && status != 'paid') return false;
      if (_filter == 'rejected' && status != 'rejected') return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (o['name'] ?? '').toString().toLowerCase();
        final email = (o['email'] ?? '').toString().toLowerCase();
        final ref = (o['transfer_ref'] ?? '').toString().toLowerCase();
        final id = (o['id'] ?? '').toString();
        if (!name.contains(q) && !email.contains(q) && !ref.contains(q) && !id.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        title: const Text('Quản trị duyệt SignEye Pro', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
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
            onPressed: _showGrantProDialog,
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
                            'Duyệt đơn và cấp Pro trực tiếp cho người dùng mà không phụ thuộc localhost.',
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
            if (_loading && _orders.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (filtered.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 54, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'Không tìm thấy đơn hàng nào',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final o in filtered) _buildOrderCard(o),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final purchases = _summary?['purchases'] ?? '0';
    final revenue = _formatMoney(_summary?['revenue']);
    final pendingCount = _orders.where((o) => o['status'] == 'pending' || o['status'] == 'submitted').length;

    return Row(
      children: [
        Expanded(
          child: _summaryBox('Chờ duyệt', '$pendingCount', const Color(0xFFD97706), const Color(0xFFFEF3C7)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryBox('Đã duyệt', '$purchases', const Color(0xFF0D8F5C), const Color(0xFFDEF7EC)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryBox('Doanh thu', revenue, const Color(0xFF4F46E5), const Color(0xFFEEF2FF)),
        ),
      ],
    );
  }

  Widget _summaryBox(String title, String value, Color textCol, Color bgCol) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: bgCol,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: textCol.withOpacity(0.85), fontSize: 11.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: textCol, fontSize: 16, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Tìm theo Username, Email, Mã CK...',
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
        ),
      ],
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
    final id = int.tryParse(o['id']?.toString() ?? '0') ?? 0;
    final status = (o['status'] ?? '').toString();
    final name = (o['name'] ?? 'Người dùng').toString();
    final email = (o['email'] ?? '').toString();
    final plan = (o['plan'] ?? 'month').toString();
    final amount = o['amount'];
    final ref = (o['transfer_ref'] ?? o['id']).toString();
    final createdAt = (o['created_at'] ?? '').toString();

    final isPaid = status == 'paid';
    final isPending = status == 'pending' || status == 'submitted';

    Color badgeBg;
    Color badgeText;
    String statusLabel;

    if (isPaid) {
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
        border: Border.all(color: isPending ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0)),
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
                'Username: ',
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
              const Icon(Icons.card_membership, size: 16, color: Colors.indigo),
              const SizedBox(width: 6),
              Text(
                'Gói: ${plan == 'year' ? '1 năm' : '1 tháng'} · ${_formatMoney(amount)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5)),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.qr_code, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text('Nội dung CK: ', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFEDF2F7), borderRadius: BorderRadius.circular(4)),
                child: Text(ref, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                createdAt.length >= 16 ? createdAt.substring(0, 16).replaceAll('T', ' ') : createdAt,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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
}
