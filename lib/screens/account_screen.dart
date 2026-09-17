import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme.dart';

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
    String paymentMethod = 'qr';

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
                                    setSheetState(() => yearly = false),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _planOption(
                                label: '1 năm',
                                price: '399.000đ',
                                selected: yearly,
                                onTap: () => setSheetState(() => yearly = true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _paymentMethodOption(
                                  label: 'Mã QR',
                                  icon: Icons.qr_code_2_rounded,
                                  selected: paymentMethod == 'qr',
                                  onTap: () =>
                                      setSheetState(() => paymentMethod = 'qr'),
                                ),
                              ),
                              Expanded(
                                child: _paymentMethodOption(
                                  label: 'Tiền mặt',
                                  icon: Icons.payments_outlined,
                                  selected: paymentMethod == 'cash',
                                  onTap: () => setSheetState(
                                      () => paymentMethod = 'cash'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (paymentMethod == 'qr') ...[
                          const SizedBox(height: 8),
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
                                      _qrCodePreview(),
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
                                  'STK: 0764365448',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.text,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Tên ngân hàng: Momo',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Tên: LE THI HONG DUYEN',
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
                        ] else ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Thanh toán bằng tiền mặt',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: AppColors.text,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '• Đến quầy hoặc người hỗ trợ để nộp tiền mặt.\n• Sau khi đã thanh toán, nhấn nút xác nhận bên dưới.\n• Nếu chưa thanh toán, hệ thống sẽ giữ trạng thái Free.',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.text2,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        const Text(
                          'Vui lòng xác nhận sau khi đã thanh toán thành công.',
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
                            onPressed: () {
                              context
                                  .read<AppState>()
                                  .upgradeToPro(yearly: yearly);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    paymentMethod == 'qr'
                                        ? 'Đã xác nhận thanh toán bằng mã QR 🎉'
                                        : 'Đã xác nhận thanh toán bằng tiền mặt 🎉',
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              paymentMethod == 'qr'
                                  ? 'Xác nhận đã thanh toán bằng QR'
                                  : 'Xác nhận đã thanh toán tiền mặt',
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

  Widget _paymentMethodOption({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryPale : Colors.transparent,
          border: Border(
            right: const BorderSide(color: AppColors.line),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.primary : AppColors.text2,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.primary : AppColors.text2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
