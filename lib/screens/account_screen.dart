import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme.dart';
import 'game_screen.dart';
import 'puzzle_game_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final df = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primaryPale,
                  child: Text(
                    state.userName.isNotEmpty
                        ? state.userName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          state.userName.isEmpty
                              ? 'Người dùng'
                              : state.userName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(state.userEmail,
                          style: const TextStyle(
                              color: AppColors.text2, fontSize: 12.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: state.isPro
                    ? [AppColors.primary, AppColors.primary2]
                    : [AppColors.surface2, AppColors.surface2],
              ),
              borderRadius: BorderRadius.circular(16),
              border: state.isPro ? null : Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.workspace_premium_rounded,
                        color: state.isPro ? Colors.white : AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      state.isPro ? 'Đã đăng ký SignEye Pro' : 'Gói Free',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: state.isPro ? Colors.white : AppColors.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  state.isPro
                      ? 'Hết hạn: ${state.proExpiry != null ? df.format(state.proExpiry!) : "—"}'
                      : 'Tối đa ${AppState.freeDailyScanLimit} lượt quét AI/ngày · lưu ${AppState.freeHistoryLimit} lịch sử gần nhất.\nHọc GPLX, thi thử và cẩm nang vẫn dùng miễn phí.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: state.isPro ? Colors.white70 : AppColors.text2,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                if (state.isPro)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                    ),
                    onPressed: () => state.cancelPro(),
                    child: const Text('Hủy gói Pro'),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _openPaymentSheet(context),
                      child: const Text('Nâng cấp Pro'),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Game coin wallet & redeem card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Text('🪙', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 6),
                        Text(
                          'Ví Xu Thưởng Minigame',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                            color: Color(0xFF78350F),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${state.coins} xu',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Đang có ${state.coins} xu · Đã đổi: ${NumberFormat("#,###", "vi").format(state.rewardBalance)}đ\n(1.000 xu = 1.000 VNĐ · Chơi ghép hình nhận 10 xu, đố vui nhận 5 xu để tích lũy mua gói Pro 1 hoặc 2 tháng)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF92400E),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const PuzzleGameScreen()),
                        ),
                        icon: const Icon(Icons.extension_rounded, size: 18),
                        label: const Text('Ghép Hình (+10 xu)',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFB45309),
                          side: const BorderSide(color: Color(0xFFD97706)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const TrafficSignGameScreen()),
                        ),
                        icon: const Icon(Icons.videogame_asset_rounded, size: 18),
                        label: const Text('Đố Vui (+5 xu)',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const RedeemProSheet(),
                    ),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: const Text('Đổi Xu Ra Tiền & Mua Pro (1 - 2 tháng)',
                        style: TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Cài đặt',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 8),
          _settingsTile(
            icon: Icons.dark_mode_outlined,
            title: 'Chế độ tối',
            trailing: Switch(
              value: state.darkMode,
              activeColor: AppColors.primary,
              onChanged: (v) => state.toggleDarkMode(v),
            ),
          ),
          _settingsTile(
            icon: Icons.smart_toy_outlined,
            title: 'Gemini API Key (cho quét AI)',
            subtitle:
                state.geminiApiKey.isEmpty ? 'Chưa thiết lập' : '•••• đã lưu',
            onTap: () => _openApiKeySheet(context, state),
          ),
          _settingsTile(
            icon: Icons.help_outline_rounded,
            title: 'Trợ giúp & phản hồi',
            onTap: () {},
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => state.logout(),
              style:
                  OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Đăng xuất'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: AppColors.text2, size: 20),
          title: Text(title,
              style:
                  const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
          subtitle: subtitle != null
              ? Text(subtitle,
                  style:
                      const TextStyle(fontSize: 11.5, color: AppColors.muted))
              : null,
          trailing: trailing ??
              (onTap != null ? const Icon(Icons.chevron_right_rounded) : null),
        ),
      ),
    );
  }

  void _openApiKeySheet(BuildContext context, AppState state) {
    final ctrl = TextEditingController(text: state.geminiApiKey);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gemini API Key',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 6),
            const Text(
              'Dùng để nhận diện biển báo trong tính năng Quét. Khóa được lưu cục bộ trên thiết bị, không gửi tới máy chủ SignEye.',
              style:
                  TextStyle(fontSize: 12, color: AppColors.text2, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(hintText: 'AIza...'),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  state.setGeminiApiKey(ctrl.text);
                  Navigator.pop(ctx);
                },
                child: const Text('Lưu'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPaymentSheet(BuildContext context) {
    bool yearly = false;
    Map<String, dynamic>? order;
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = constraints.maxHeight > 0
                ? constraints.maxHeight * 0.9
                : MediaQuery.of(ctx).size.height * 0.9;

            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.only(top: 48),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4E9EC),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Đăng ký SignEye Pro',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 24),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _planOption(
                                label: '1 tháng',
                                price: '39.000đ',
                                selected: !yearly,
                                onTap: () =>
                                    setSheetState(() { yearly = false; order = null; }),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _planOption(
                                label: '1 năm',
                                price: '399.000đ',
                                selected: yearly,
                                onTap: () => setSheetState(() { yearly = true; order = null; }),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: 320,
                          padding: const EdgeInsets.only(top: 18, bottom: 12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF4E1E7),
                          ),
                          child: Column(
                            children: [
                              const SizedBox(
                                width: 180,
                                child: Text(
                                  'mo\nmo',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFB1006A),
                                    height: 0.7,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: 300,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                      color: const Color(0xFFE8B7CC),
                                      width: 2),
                                ),
                                child: Column(
                                  children: [
                                    if (order == null)
                                      const Text('Tạo đơn hàng để hiển thị mã QR thanh toán')
                                    else if (const String.fromEnvironment('VIETQR_BANK_ID', defaultValue: '970422').isEmpty || const String.fromEnvironment('VIETQR_ACCOUNT_NO', defaultValue: '0000708578761').isEmpty)
                                      const Text('Chưa cấu hình ngân hàng nhận thanh toán')
                                    else
                                      Image.network(
                                        'https://img.vietqr.io/image/${const String.fromEnvironment('VIETQR_BANK_ID', defaultValue: '970422')}-${const String.fromEnvironment('VIETQR_ACCOUNT_NO', defaultValue: '0000708578761')}-compact2.png?amount=${order!['amount']}&addInfo=${order!['transfer_ref']}&accountName=${Uri.encodeComponent(const String.fromEnvironment('VIETQR_ACCOUNT_NAME', defaultValue: 'LE THI HONG DUYEN'))}',
                                        width: 220, height: 220,
                                        errorBuilder: (_, __, ___) => const Text('Không tải được mã QR'),
                                      ),
                                    const SizedBox(height: 12),
                                    const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'VIETQR',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 22,
                                            color: Color(0xFFE31B23),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'napas 247',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 22,
                                            color: Color(0xFF0D8F5C),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 22),
                              const Text(
                                'STK: ${const String.fromEnvironment('VIETQR_ACCOUNT_NO', defaultValue: '0000708578761')}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Ngân hàng: MB Bank',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Tên: ${const String.fromEnvironment('VIETQR_ACCOUNT_NAME', defaultValue: 'LE THI HONG DUYEN')}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if(order != null) Text('Nội dung chuyển khoản: ${order!['transfer_ref']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 18),
                        const Text(
                          'Chuyển khoản đúng số tiền và nội dung đơn hàng. Pro chỉ kích hoạt sau khi Admin xác nhận đã nhận tiền.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.text2,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: loading ? null : () async {
                              final email=context.read<AppState>().userEmail;
                              if(email.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Vui lòng đăng nhập trước khi mua Pro')));
                                return;
                              }
                              if(const String.fromEnvironment('VIETQR_BANK_ID', defaultValue: '970422').isEmpty || const String.fromEnvironment('VIETQR_ACCOUNT_NO', defaultValue: '0000708578761').isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Chưa cấu hình tài khoản nhận thanh toán')));
                                return;
                              }
                              setSheetState(()=>loading=true);
                              try {
                                final base=const String.fromEnvironment('SIGN_EYE_API_URL',defaultValue:'http://127.0.0.1:8000');
                                if(order==null) {
                                  final response=await http.post(Uri.parse('$base/payments/orders'),headers:{'Content-Type':'application/json','Authorization':'Bearer ${context.read<AppState>().authToken}'},body:jsonEncode({'plan':yearly?'year':'month'}));
                                  if(response.statusCode!=200) throw Exception('Không tạo được đơn hàng');
                                  setSheetState(()=>order=jsonDecode(response.body) as Map<String,dynamic>);
                                } else {
                                  final response=await http.get(Uri.parse('$base/payments/orders/${order!['id']}'),headers:{'Authorization':'Bearer ${context.read<AppState>().authToken}' });
                                  if(response.statusCode!=200) throw Exception('Không kiểm tra được đơn hàng');
                                  final status=(jsonDecode(response.body) as Map<String,dynamic>)['status'];
                                  if(status=='paid') {
                                    final sub=await http.get(Uri.parse('$base/payments/subscription'),headers:{'Authorization':'Bearer ${context.read<AppState>().authToken}' });
                                    if(sub.statusCode!=200) throw Exception('Không đồng bộ được quyền Pro');
                                    final subscription=jsonDecode(sub.body) as Map<String,dynamic>;
                                    await context.read<AppState>().syncProFromServer(subscription);
                                    if(ctx.mounted) Navigator.pop(ctx);
                                    if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Thanh toán đã được xác nhận. Đã kích hoạt Pro!')));
                                  } else if(status=='pending') {
                                    final submitted=await http.post(Uri.parse('$base/payments/orders/${order!['id']}/submit'),headers:{'Content-Type':'application/json','Authorization':'Bearer ${context.read<AppState>().authToken}'},body:jsonEncode({}));
                                    if(submitted.statusCode!=200) throw Exception('Không gửi được yêu cầu xác nhận');
                                    if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Đã gửi yêu cầu. Admin sẽ kiểm tra giao dịch.')));
                                  } else {
                                    if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(status=='rejected'?'Đơn hàng đã bị từ chối':'Đơn hàng đang chờ Admin duyệt')));
                                  }
                                }
                              } catch(e) {
                                if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Lỗi: $e')));
                              } finally { if(ctx.mounted) setSheetState(()=>loading=false); }
                            },
                            child: Text(
                              order == null ? 'Tạo mã QR thanh toán' : 'Gửi yêu cầu / kiểm tra thanh toán',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Hủy'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _qrCodePreview() {
    const size = 21;
    return Container(
      width: 220,
      height: 220,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: size,
          crossAxisSpacing: 1.5,
          mainAxisSpacing: 1.5,
        ),
        itemCount: size * size,
        itemBuilder: (context, index) {
          final row = index ~/ size;
          final col = index % size;

          final finder1 = (row < 7 && col < 7);
          final finder2 = (row < 7 && col > 13);
          final finder3 = (row > 13 && col < 7);
          final center = row > 7 && row < 14 && col > 7 && col < 14;

          bool filled = false;
          if (finder1 || finder2 || finder3) {
            filled = (row == 0 || row == 6 || col == 0 || col == 6) ||
                ((row > 0 && row < 6 && col > 0 && col < 6) &&
                    ((row + col) % 2 == 0));
          } else if (center) {
            filled = ((row + col) % 3 == 0) || ((row * 2 + col) % 5 == 0);
          } else {
            filled = ((row * 7 + col * 11) % 5 == 0) ||
                ((row * 3 + col * 2) % 7 == 0);
          }

          return Container(
            decoration: BoxDecoration(
              color: filled ? Colors.black : Colors.transparent,
              borderRadius: BorderRadius.circular(1),
            ),
          );
        },
      ),
    );
  }

  Widget _planOption({
    required String label,
    required String price,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryPale : AppColors.surface,
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.line,
              width: selected ? 1.4 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 2),
            Text(price,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: selected ? AppColors.primary : AppColors.text)),
          ],
        ),
      ),
    );
  }
}
