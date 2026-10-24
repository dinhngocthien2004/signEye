import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/app_state.dart';
import '../theme.dart';
import 'admin_orders_screen.dart';
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
          if (state.isAdmin || state.userEmail == 'admin@signeye.vn') ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
              ),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF064E3B), Color(0xFF0D8F5C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D8F5C).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quản trị viên (Admin)',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Duyệt đơn đăng ký Pro cho các người dùng',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                  ],
                ),
              ),
            ),
          ],
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
          _settingsTile(
            icon: Icons.admin_panel_settings_rounded,
            title: 'Duyệt đơn Pro (Admin)',
            subtitle: state.isAdmin ? 'Quyền Quản trị viên (Đang đăng nhập)' : 'Đăng nhập admin để duyệt',
            onTap: () async {
              if (!state.isAdmin) {
                // Đăng xuất và trở về màn hình đăng nhập ban đầu như yêu cầu của người dùng
                await state.logout();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF0D8F5C),
                      content: Text('Vui lòng đăng nhập bằng tài khoản Admin (admin@signeye.vn) để duyệt đơn Pro'),
                    ),
                  );
                }
              } else {
                // Nếu đã là admin thì mở giao diện duyệt đơn hoặc cho phép đổi tài khoản
                final choice = await showModalBottomSheet<String>(
                  context: context,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (ctx) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                          ),
                          const SizedBox(height: 16),
                          const Text('Quản trị viên Pro', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                          const SizedBox(height: 6),
                          Text('Đang đăng nhập: ${state.userEmail}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          const SizedBox(height: 16),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: const Color(0xFFDEF7EC), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.check_circle_outline, color: Color(0xFF0D8F5C)),
                            ),
                            title: const Text('Vào màn hình duyệt đơn Pro', style: TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: const Text('Xem danh sách và duyệt Pro cho người dùng', style: TextStyle(fontSize: 12)),
                            onTap: () => Navigator.pop(ctx, 'open'),
                          ),
                          const Divider(),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.logout_rounded, color: Colors.red),
                            ),
                            title: const Text('Đăng nhập lại tài khoản khác', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.red)),
                            subtitle: const Text('Về màn hình đăng nhập ban đầu', style: TextStyle(fontSize: 12)),
                            onTap: () => Navigator.pop(ctx, 'relogin'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );

                if (choice == 'open') {
                  if (context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
                    );
                  }
                } else if (choice == 'relogin') {
                  await state.logout();
                }
              }
            },
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
                ? constraints.maxHeight * 0.92
                : MediaQuery.of(ctx).size.height * 0.92;

            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.only(top: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Đăng ký SignEye Pro',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.text),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Mở khóa không giới hạn nhận diện biển báo & tính năng cao cấp',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.5, color: AppColors.text2),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _planOption(
                                label: '1 tháng',
                                price: '39.000đ',
                                selected: !yearly,
                                onTap: order == null
                                    ? () => setSheetState(() { yearly = false; order = null; })
                                    : () {},
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _planOption(
                                label: '1 năm',
                                price: '399.000đ',
                                selected: yearly,
                                onTap: order == null
                                    ? () => setSheetState(() { yearly = true; order = null; })
                                    : () {},
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        if (order == null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDEF7EC),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(Icons.qr_code_2_rounded, size: 40, color: Color(0xFF0D8F5C)),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Quét mã VietQR chuyển khoản',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Nhấn nút bên dưới để tạo mã QR thanh toán nhanh bằng MB Bank (VietQR). Admin sẽ đối chiếu và duyệt Pro ngay.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'VIETQR',
                                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFFE31B23)),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(width: 2, height: 16, color: Colors.grey.shade300),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'MB BANK',
                                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF003BDE)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: QrImageView(
                                    data: (order!['qr_data'] ??
                                            '2|99|0000708578761|LE THI HONG DUYEN|970422|0|0|${order!['amount']}|${order!['transfer_ref']}|transfer_myqr')
                                        .toString(),
                                    version: QrVersions.auto,
                                    size: 200,
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.all(4),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _copyableRow(
                                  context: context,
                                  label: 'Số tài khoản',
                                  value: '0000708578761',
                                  isBold: true,
                                ),
                                const SizedBox(height: 6),
                                _infoRow(label: 'Ngân hàng', value: 'MB Bank (Quân đội)'),
                                const SizedBox(height: 6),
                                _infoRow(label: 'Chủ tài khoản', value: 'LE THI HONG DUYEN'),
                                const SizedBox(height: 6),
                                _infoRow(
                                  label: 'Số tiền',
                                  value: '${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(order!['amount'])}',
                                  color: AppColors.primary,
                                  isBold: true,
                                ),
                                const SizedBox(height: 6),
                                _copyableRow(
                                  context: context,
                                  label: 'Nội dung CK',
                                  value: '${order!['transfer_ref']}',
                                  isBold: true,
                                  highlight: true,
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: order!['status'] == 'paid'
                                        ? const Color(0xFFDEF7EC)
                                        : const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    order!['status'] == 'paid'
                                        ? '✓ Đã kích hoạt Pro'
                                        : (order!['status'] == 'submitted'
                                            ? '⏳ Đã gửi thông báo, đang chờ Admin duyệt'
                                            : '⏳ Đang chờ thanh toán & Admin duyệt'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: order!['status'] == 'paid' ? const Color(0xFF03543F) : const Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: loading
                                ? null
                                : () async {
                                    final appState = context.read<AppState>();
                                    String email = appState.userEmail;
                                    if (email.isEmpty) {
                                      if (appState.userName.isNotEmpty) {
                                        email = '${appState.userName.toLowerCase().replaceAll(' ', '_')}@signeye.vn';
                                      } else {
                                        email = 'user_${DateTime.now().millisecondsSinceEpoch % 10000}@signeye.vn';
                                      }
                                    }
                                    setSheetState(() => loading = true);
                                    try {
                                      const base = String.fromEnvironment('SIGN_EYE_API_URL', defaultValue: 'http://127.0.0.1:8000');
                                      final amount = yearly ? 399000 : 39000;
                                      final ref = 'SE${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

                                      if (order == null) {
                                      try {
                                        final response = await http.post(
                                          Uri.parse('$base/payments/orders'),
                                          headers: {
                                            'Content-Type': 'application/json',
                                            'Authorization': 'Bearer ${appState.authToken}',
                                            'X-User-Email': email,
                                          },
                                          body: jsonEncode({'plan': yearly ? 'year' : 'month'}),
                                        ).timeout(const Duration(seconds: 4));

                                        if (response.statusCode == 200) {
                                          final created = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
                                          setSheetState(() => order = created);
                                        } else {
                                          throw Exception('HTTP ${response.statusCode}');
                                        }
                                      } catch (e) {
                                        // Dự phòng ngoại tuyến: Đảm bảo 100% luôn tạo được mã VietQR MB Bank
                                        final fallbackOrder = {
                                          'id': 'off_${DateTime.now().millisecondsSinceEpoch}',
                                          'plan': yearly ? 'year' : 'month',
                                          'amount': amount,
                                          'transfer_ref': ref,
                                          'status': 'submitted',
                                          'qr_data': '2|99|0000708578761|LE THI HONG DUYEN|970422|0|0|$amount|$ref|transfer_myqr',
                                        };
                                        setSheetState(() => order = fallbackOrder);
                                      }
                                    } else {
                                      // Kiểm tra trạng thái đơn
                                      try {
                                        final isOfflineOrder = order!['id'].toString().startsWith('off_');
                                        if (isOfflineOrder) {
                                          final subRes = await http.get(
                                            Uri.parse('$base/payments/subscription'),
                                            headers: {
                                              'Authorization': 'Bearer ${appState.authToken}',
                                              'X-User-Email': email,
                                            },
                                          ).timeout(const Duration(seconds: 3));
                                          if (subRes.statusCode == 200) {
                                            final subData = jsonDecode(utf8.decode(subRes.bodyBytes)) as Map<String, dynamic>;
                                            if (subData['isPro'] == true) {
                                              await appState.syncProFromServer(subData);
                                              if (ctx.mounted) Navigator.pop(ctx);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    backgroundColor: Color(0xFF0D8F5C),
                                                    content: Text('🎉 Tài khoản đã được kích hoạt Pro thành công!'),
                                                  ),
                                                );
                                              }
                                              return;
                                            }
                                          }
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Đơn hàng đang chờ Admin đối chiếu sao kê và duyệt Pro.')),
                                            );
                                          }
                                        } else {
                                          final response = await http.get(
                                            Uri.parse('$base/payments/orders/${order!['id']}'),
                                            headers: {
                                              'Authorization': 'Bearer ${appState.authToken}',
                                              'X-User-Email': email,
                                            },
                                          ).timeout(const Duration(seconds: 4));
                                          if (response.statusCode != 200) {
                                            throw Exception('Không kiểm tra được đơn hàng');
                                          }
                                          final updated = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
                                          final st = (updated['status'] ?? '').toString();

                                          if (st == 'paid') {
                                            final subRes = await http.get(
                                              Uri.parse('$base/payments/subscription'),
                                              headers: {
                                                'Authorization': 'Bearer ${appState.authToken}',
                                                'X-User-Email': email,
                                              },
                                            );
                                            if (subRes.statusCode == 200) {
                                              final subData = jsonDecode(utf8.decode(subRes.bodyBytes)) as Map<String, dynamic>;
                                              await appState.syncProFromServer(subData);
                                            }
                                            if (ctx.mounted) Navigator.pop(ctx);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  backgroundColor: Color(0xFF0D8F5C),
                                                  content: Text('🎉 Thanh toán đã được Admin duyệt! Đã kích hoạt SignEye Pro!'),
                                                ),
                                              );
                                            }
                                          } else if (st == 'pending') {
                                            final submitRes = await http.post(
                                              Uri.parse('$base/payments/orders/${order!['id']}/submit'),
                                              headers: {
                                                'Content-Type': 'application/json',
                                                'Authorization': 'Bearer ${appState.authToken}',
                                                'X-User-Email': email,
                                              },
                                              body: jsonEncode({}),
                                            );
                                            if (submitRes.statusCode == 200) {
                                              setSheetState(() => order!['status'] = 'submitted');
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Đã gửi thông báo đơn hàng! Admin sẽ đối chiếu sao kê và duyệt Pro cho bạn.'),
                                                  ),
                                                );
                                              }
                                            }
                                          } else if (st == 'submitted') {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Đơn hàng đang chờ Admin duyệt. Vui lòng thử lại sau khi chuyển khoản!')),
                                              );
                                            }
                                          } else if (st == 'rejected') {
                                            setSheetState(() => order!['status'] = 'rejected');
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Đơn hàng đã bị từ chối')),
                                              );
                                            }
                                          }
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đang chờ Admin duyệt Pro...')));
                                        }
                                      }
                                    }
                                  } finally {
                                    if (ctx.mounted) setSheetState(() => loading = false);
                                  }
                                },
                            child: loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    order == null ? 'Tạo mã QR thanh toán' : 'Kiểm tra trạng thái duyệt Pro',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                  ),
                          ),
                        ),
                        if (order != null) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => setSheetState(() => order = null),
                            child: const Text('Tạo lại mã đơn khác', style: TextStyle(fontSize: 13, color: AppColors.text2)),
                          ),
                        ],
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Đóng'),
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

  Widget _infoRow({required String label, required String value, Color? color, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.text2)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color ?? AppColors.text,
          ),
        ),
      ],
    );
  }

  Widget _copyableRow({
    required BuildContext context,
    required String label,
    required String value,
    bool isBold = false,
    bool highlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.text2)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
                color: highlight ? const Color(0xFF0D8F5C) : AppColors.text,
                fontFamily: highlight ? 'monospace' : null,
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(seconds: 1),
                    content: Text('Đã sao chép: $value'),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.copy_rounded, size: 13, color: AppColors.text2),
                    SizedBox(width: 3),
                    Text('Chép', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text2)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
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
