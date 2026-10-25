import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/app_state.dart';
import '../services/orders_storage.dart';
import '../theme.dart';
import 'admin_orders_screen.dart';
import 'game_screen.dart';
import 'puzzle_game_screen.dart';
import 'scan_screen.dart';
import 'search_screen.dart';
import 'compare_screen.dart';
import 'exam_home_screen.dart';
import 'learning_screen.dart';
import 'chatbot_screen.dart';
import 'history_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final df = DateFormat('dd/MM/yyyy');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản & Cá nhân', style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
        centerTitle: false,
        actions: [
          if (state.isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primaryPale,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
                ),
                icon: const Icon(Icons.admin_panel_settings_rounded, size: 18),
                label: const Text('Admin', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ─── 1. Thẻ hồ sơ người dùng cao cấp (User Profile Card) ───
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [Colors.white, const Color(0xFFF8FAFC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: state.isPro ? const Color(0xFF818CF8).withValues(alpha: 0.5) : AppColors.line,
                width: state.isPro ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: state.isPro
                                  ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                                  : [AppColors.primary, AppColors.primary2],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (state.isPro ? const Color(0xFF6366F1) : AppColors.primary)
                                    .withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            state.userName.isNotEmpty ? state.userName[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                            ),
                          ),
                        ),
                        if (state.isPro)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF59E0B),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.star_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  state.userName.isEmpty ? 'Người dùng SignEye' : state.userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            state.userEmail,
                            style: const TextStyle(
                              color: AppColors.text2,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (state.isAdmin)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                                  ),
                                  child: const Text(
                                    '👑 Quản trị viên',
                                    style: TextStyle(
                                      color: Color(0xFFDC2626),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: state.isPro
                                      ? const Color(0xFF6366F1).withValues(alpha: 0.12)
                                      : Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: state.isPro
                                        ? const Color(0xFF6366F1).withValues(alpha: 0.35)
                                        : Colors.grey.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Text(
                                  state.isPro ? '⭐ Thành viên VIP Pro' : 'Thành viên Free',
                                  style: TextStyle(
                                    color: state.isPro ? const Color(0xFF4F46E5) : AppColors.text2,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 0.7),
                const SizedBox(height: 14),

                // Thanh thống kê nhanh (Quick Highlights)
                Row(
                  children: [
                    _quickStatItem(
                      label: 'Biển báo',
                      value: '386 biển',
                      icon: Icons.traffic_rounded,
                      color: const Color(0xFF0EA5E9),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                    ),
                    Container(height: 28, width: 1, color: AppColors.line),
                    _quickStatItem(
                      label: 'Ví xu',
                      value: '${state.coins} xu',
                      icon: Icons.monetization_on_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                    Container(height: 28, width: 1, color: AppColors.line),
                    _quickStatItem(
                      label: 'Gói dùng',
                      value: state.isPro ? 'Gói Pro' : 'Miễn phí',
                      icon: Icons.verified_rounded,
                      color: state.isPro ? const Color(0xFF10B981) : AppColors.text2,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ─── Thanh công cụ tính năng trực quan (User Feature Actions Toolbar) ───
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.dashboard_customize_rounded, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Tiện ích & Tính năng nhanh',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: -0.2),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '8 tính năng',
                        style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.92,
                  children: [
                    _featureActionItem(
                      icon: Icons.camera_alt_rounded,
                      color: const Color(0xFF0D9488),
                      label: 'Quét AI',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen())),
                      isDark: isDark,
                    ),
                    _featureActionItem(
                      icon: Icons.search_rounded,
                      color: const Color(0xFF2563EB),
                      label: 'Tra cứu',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                      isDark: isDark,
                    ),
                    _featureActionItem(
                      icon: Icons.compare_arrows_rounded,
                      color: const Color(0xFF7C3AED),
                      label: 'So sánh',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompareScreen())),
                      isDark: isDark,
                    ),
                    _featureActionItem(
                      icon: Icons.school_rounded,
                      color: const Color(0xFFF59E0B),
                      label: 'Thi GPLX',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamHomeScreen())),
                      isDark: isDark,
                    ),
                    _featureActionItem(
                      icon: Icons.auto_stories_rounded,
                      color: const Color(0xFF10B981),
                      label: 'Học luật',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LearningScreen())),
                      isDark: isDark,
                    ),
                    _featureActionItem(
                      icon: Icons.smart_toy_rounded,
                      color: const Color(0xFF6366F1),
                      label: 'Trợ lý AI',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatbotScreen())),
                      isDark: isDark,
                    ),
                    _featureActionItem(
                      icon: Icons.history_rounded,
                      color: const Color(0xFFEC4899),
                      label: 'Lịch sử',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                      isDark: isDark,
                    ),
                    _featureActionItem(
                      icon: Icons.extension_rounded,
                      color: const Color(0xFFE11D48),
                      label: 'Đố vui',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PuzzleGameScreen())),
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ─── 2. Thẻ Đăng ký SignEye Pro (Premium Subscription Card) ───
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: state.isPro
                    ? [const Color(0xFF4338CA), const Color(0xFF6366F1)]
                    : isDark
                        ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
                        : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: state.isPro ? Colors.transparent : const Color(0xFFC7D2FE),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (state.isPro ? const Color(0xFF6366F1) : const Color(0xFF6366F1))
                      .withValues(alpha: isDark ? 0.25 : 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: state.isPro
                                ? Colors.white.withValues(alpha: 0.2)
                                : const Color(0xFF6366F1).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.workspace_premium_rounded,
                            color: state.isPro ? Colors.white : const Color(0xFF4F46E5),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.isPro ? 'SignEye Pro Đang Kích Hoạt' : 'Nâng cấp SignEye Pro',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15.5,
                                color: state.isPro ? Colors.white : const Color(0xFF1E1B4B),
                              ),
                            ),
                            Text(
                              state.isPro
                                  ? 'Đặc quyền thành viên cao cấp'
                                  : 'Chỉ từ 39.000đ / tháng',
                              style: TextStyle(
                                fontSize: 12,
                                color: state.isPro ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF4338CA),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (state.isPro)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'ĐANG DÙNG',
                          style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  state.isPro
                      ? 'Thời hạn sử dụng: ${state.proExpiry != null ? df.format(state.proExpiry!) : "Không thời hạn"}\nBạn có toàn quyền quét AI không giới hạn và nhận diện chuẩn xác mọi biển báo.'
                      : '✓ Quét AI nhận diện biển báo không giới hạn\n✓ Tìm kiếm thông minh bằng hình ảnh & giọng nói\n✓ Lưu trữ lịch sử học tập trọn đời & hỗ trợ ưu tiên',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: state.isPro ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF374151),
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                if (state.isPro)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _openPaymentSheet(context),
                          icon: const Icon(Icons.autorenew_rounded, size: 17),
                          label: const Text('Gia hạn thêm gói Pro', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Hủy gói',
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.white.withValues(alpha: 0.8),
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                        ),
                        onPressed: () => state.cancelPro(),
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _openPaymentSheet(context),
                      icon: const Icon(Icons.flash_on_rounded, size: 18),
                      label: const Text(
                        'Nâng cấp Pro ngay (Quét VietQR 39k)',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ─── 3. Thẻ Ví Xu Thưởng & Minigame (Gamification Card) ───
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF292524), const Color(0xFF1C1917)]
                    : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFDE68A)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.15 : 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('🪙', style: TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Ví Xu Thưởng SignEye',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: Color(0xFF78350F),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${state.coins} xu',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Đang tích lũy: ${state.coins} xu (Tương đương ${NumberFormat("#,###", "vi").format(state.coins)}đ)\nQuy đổi: 1.000 xu = 1.000 VNĐ. Chơi ghép hình nhận 10 xu, đố vui nhận 5 xu để đổi ngay gói Pro.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF92400E),
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PuzzleGameScreen()),
                        ),
                        icon: const Icon(Icons.extension_rounded, size: 17),
                        label: const Text('Ghép Hình (+10 xu)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFB45309),
                          side: const BorderSide(color: Color(0xFFD97706)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TrafficSignGameScreen()),
                        ),
                        icon: const Icon(Icons.videogame_asset_rounded, size: 17),
                        label: const Text('Đố Vui (+5 xu)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
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
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const RedeemProSheet(),
                    ),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: const Text(
                      'Đổi Xu Lấy Gói Pro (39.000 xu / tháng)',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // ─── 4. Cài đặt & Tiện ích mở rộng cho người dùng ───
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              'Cài đặt & Trợ giúp',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, letterSpacing: -0.2),
            ),
          ),
          const SizedBox(height: 6),

          _settingsTile(
            icon: Icons.dark_mode_outlined,
            title: 'Chế độ tối (Dark Mode)',
            subtitle: state.darkMode ? 'Giao diện tối dịu mắt' : 'Giao diện sáng tiêu chuẩn',
            trailing: Switch(
              value: state.darkMode,
              activeColor: AppColors.primary,
              onChanged: (v) => state.toggleDarkMode(v),
            ),
          ),

          _settingsTile(
            icon: Icons.key_rounded,
            title: 'Gemini API Key (cho quét AI)',
            subtitle: state.geminiApiKey.isEmpty
                ? 'Chưa thiết lập (Dùng khóa hệ thống)'
                : 'Đã lưu: ${state.geminiApiKey.length > 8 ? "${state.geminiApiKey.substring(0, 4)}...${state.geminiApiKey.substring(state.geminiApiKey.length - 4)}" : "••••••••"}',
            trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.text2),
            onTap: () => _showGeminiApiKeyDialog(context, state),
          ),

          _settingsTile(
            icon: Icons.menu_book_rounded,
            title: 'Quy chuẩn QCVN 41:2019/BGTVT',
            subtitle: 'Tra cứu 386 biển báo và mức phạt Nghị định 168/2024',
            onTap: () => _showRegulationDialog(context),
          ),

          _settingsTile(
            icon: Icons.info_outline_rounded,
            title: 'Thông tin ứng dụng',
            subtitle: 'SignEye AI v2.5.0 Pro · Giấy phép GPLX Việt Nam',
            onTap: () => _showAboutDialog(context),
          ),

          _settingsTile(
            icon: Icons.support_agent_rounded,
            title: 'Hỗ trợ & Hướng dẫn sử dụng',
            subtitle: 'Giải đáp thắc mắc, phản hồi chất lượng',
            onTap: () => _showSupportDialog(context),
          ),

          if (state.isAdmin) ...[
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF87171)),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                tileColor: const Color(0xFFFEF2F2),
                leading: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFDC2626)),
                title: const Text(
                  'Bảng điều khiển Quản trị (Admin)',
                  style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF991B1B), fontSize: 13.5),
                ),
                subtitle: const Text(
                  'Duyệt đơn, quản lý người dùng & thống kê doanh thu',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFFB91C1C)),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFDC2626)),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ─── 5. Nút Đăng xuất an toàn ───
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context, state),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Đăng xuất tài khoản', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _quickStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final content = Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600),
        ),
      ],
    );

    return Expanded(
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: content,
              ),
            )
          : content,
    );
  }

  Widget _featureActionItem({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: isDark ? 0.3 : 0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
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
          borderRadius: BorderRadius.circular(14),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.primaryPale.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 19),
          ),
          title: Text(
            title,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                )
              : null,
          trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.text2) : null),
        ),
      ),
    );
  }

  void _showRegulationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.menu_book_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Quy chuẩn QCVN 41:2019', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Theo Điều 15 Quy chuẩn kỹ thuật quốc gia QCVN 41:2019/BGTVT, Việt Nam có hơn 382 loại biển báo giao thông được chia thành 5 nhóm cơ bản:',
                style: TextStyle(fontSize: 13, height: 1.45),
              ),
              SizedBox(height: 10),
              Text('1. Biển báo cấm (64 loại):', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFFDC2626))),
              Text('Dạng hình tròn, viền đỏ, nền trắng, hình vẽ màu đen thể hiện điều cấm mà người tham gia giao thông không được vi phạm.', style: TextStyle(fontSize: 12, height: 1.4)),
              SizedBox(height: 8),
              Text('2. Biển hiệu lệnh (66 loại):', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF2563EB))),
              Text('Dạng hình tròn, nền xanh lam, hình vẽ màu trắng báo hiệu các hiệu lệnh bắt buộc phải chấp hành.', style: TextStyle(fontSize: 12, height: 1.4)),
              SizedBox(height: 8),
              Text('3. Biển báo nguy hiểm và cảnh báo (84 loại):', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFFD97706))),
              Text('Dạng hình tam giác đều, viền đỏ, nền vàng, hình vẽ màu đen mô tả sự việc cần chủ động phòng ngừa kịp thời.', style: TextStyle(fontSize: 12, height: 1.4)),
              SizedBox(height: 8),
              Text('4. Biển chỉ dẫn (136 loại):', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0D9488))),
              Text('Hình chữ nhật hoặc hình vuông nền xanh, cung cấp thông tin và hướng dẫn cần thiết trên đường.', style: TextStyle(fontSize: 12, height: 1.4)),
              SizedBox(height: 8),
              Text('5. Biển phụ & biển viết bằng chữ (32 loại):', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF4B5563))),
              Text('Thuyết minh bổ sung nội dung cho 4 nhóm biển chính hoặc sử dụng độc lập.', style: TextStyle(fontSize: 12, height: 1.4)),
              SizedBox(height: 8),
              Text('6. Hệ thống Vạch kẻ đường:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF7C3AED))),
              Text('Bao gồm vạch phân chia làn (vạch liền, vạch đứt), vạch mắt võng, vạch quả trám, vạch nhường đường, vạch dừng xe công cộng...', style: TextStyle(fontSize: 12, height: 1.4)),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: Text(
                  '💡 SignEye đã số hóa đầy đủ các biển báo trọng tâm xuất hiện trong 600 câu hỏi sát hạch GPLX và lưu thông hàng ngày.',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF3730A3), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã hiểu', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Về SignEye AI', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SignEye là ứng dụng thông minh hỗ trợ người tham gia giao thông và ôn thi giấy phép lái xe (GPLX):', style: TextStyle(fontSize: 13, height: 1.4)),
            SizedBox(height: 8),
            Text('• Quét & nhận diện biển báo giao thông thời gian thực', style: TextStyle(fontSize: 12.5)),
            Text('• Tra cứu mức phạt chi tiết xe máy & ô tô', style: TextStyle(fontSize: 12.5)),
            Text('• Ôn thi sát hạch lý thuyết GPLX mọi hạng', style: TextStyle(fontSize: 12.5)),
            Text('• Minigame đố vui và ghép hình nhận xu tích lũy', style: TextStyle(fontSize: 12.5)),
            SizedBox(height: 10),
            Text('Phiên bản: 2.5.0 Pro (2026)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.primary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.help_center_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Hỗ trợ người dùng', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nếu cần hỗ trợ kỹ thuật hoặc kích hoạt gói Pro:', style: TextStyle(fontSize: 13, height: 1.4)),
            SizedBox(height: 8),
            Text('• Email: hotro@signeye.vn', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            Text('• Thời gian hỗ trợ: 24/7', style: TextStyle(fontSize: 12.5, color: AppColors.text2)),
            SizedBox(height: 8),
            Text('Đơn hàng thanh toán Pro sẽ được hệ thống và Admin kiểm duyệt kích hoạt tự động.', style: TextStyle(fontSize: 12, color: AppColors.text2)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showGeminiApiKeyDialog(BuildContext context, AppState state) {
    final controller = TextEditingController(text: state.geminiApiKey);
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.key_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Gemini API Key (cho quét AI)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nhập Gemini API Key của bạn để sử dụng cho tính năng nhận diện ảnh AI (Quét biển báo). Khóa được lưu an toàn cục bộ trên thiết bị của bạn.',
                    style: TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.text2),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    obscureText: obscure,
                    style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      labelText: 'Gemini API Key',
                      hintText: 'AIzaSy...',
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      suffixIcon: IconButton(
                        icon: Icon(obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 20),
                        onPressed: () => setDialogState(() => obscure = !obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '💡 Cách lấy API Key miễn phí từ Google:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF3730A3)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '1. Truy cập https://aistudio.google.com/apikey\n2. Đăng nhập bằng tài khoản Google\n3. Nhấn "Create API key" và dán vào đây.',
                          style: TextStyle(fontSize: 11.5, height: 1.4, color: Color(0xFF4338CA)),
                        ),
                      ],
                    ),
                  ),
                  if (state.geminiApiKey.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                        onPressed: () async {
                          await state.setGeminiApiKey('');
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã xóa Gemini API Key, sử dụng khóa mặc định')),
                            );
                          }
                        },
                        icon: const Icon(Icons.delete_outline_rounded, size: 16),
                        label: const Text('Xóa khóa (Dùng mặc định)', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
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
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final key = controller.text.trim();
                  await state.setGeminiApiKey(key);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF0D8F5C),
                        content: Text(key.isEmpty
                            ? 'Đã đặt lại về khóa mặc định của hệ thống'
                            : 'Đã lưu Gemini API Key thành công!'),
                      ),
                    );
                  }
                },
                child: const Text('Lưu API Key', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmLogout(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận đăng xuất', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: AppColors.text2)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              state.logout();
            },
            child: const Text('Đăng xuất'),
          ),
        ],
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
                                       final base = await OrdersStorage.getApiBaseUrl();
                                       final amount = yearly ? 399000 : 39000;
                                       final ref = 'SE${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

                                       if (order == null) {
                                         if (base.isNotEmpty) {
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
                                           } catch (_) {
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

                                         // Đồng bộ vào OrdersStorage để Admin duyệt được ngay trên Vercel
                                         await OrdersStorage.addOrder({
                                           'id': order!['id'] ?? 'SE${DateTime.now().millisecondsSinceEpoch}',
                                           'email': email,
                                           'name': appState.userName.isNotEmpty ? appState.userName : email.split('@').first,
                                           'plan': yearly ? 'year' : 'month',
                                           'amount': amount,
                                           'status': 'submitted',
                                           'transfer_ref': order!['transfer_ref'] ?? ref,
                                           'created_at': DateTime.now().toIso8601String(),
                                           'paid_at': null,
                                         });
                                       } else {
                                         // Kiểm tra trạng thái đơn: ưu tiên kiểm tra OrdersStorage trước
                                         final proCheck = await OrdersStorage.checkUserPro(email);
                                         if (proCheck != null && proCheck['isPro'] == true) {
                                           final exp = DateTime.tryParse(proCheck['expiresAt']?.toString() ?? '');
                                           if (exp != null) {
                                             await appState.applyApprovedPro(exp);
                                             if (ctx.mounted) Navigator.pop(ctx);
                                             if (context.mounted) {
                                               ScaffoldMessenger.of(context).showSnackBar(
                                                 const SnackBar(
                                                   backgroundColor: Color(0xFF0D8F5C),
                                                   content: Text('🎉 Thanh toán đã được Admin duyệt! Đã kích hoạt SignEye Pro!'),
                                                 ),
                                               );
                                             }
                                             return;
                                           }
                                         }

                                         // Nếu chưa có local thì kiểm tra server nếu có kết nối
                                         try {
                                           if (base.isNotEmpty) {
                                             final isOfflineOrder = order!['id'].toString().startsWith('off_');
                                             if (!isOfflineOrder) {
                                               try {
                                                 await http.post(
                                                   Uri.parse('$base/payments/orders/${order!['id']}/submit'),
                                                   headers: {
                                                     'Authorization': 'Bearer ${appState.authToken}',
                                                     'X-User-Email': email,
                                                   },
                                                 ).timeout(const Duration(seconds: 3));
                                               } catch (_) {}

                                               final response = await http.get(
                                                 Uri.parse('$base/payments/orders/${order!['id']}'),
                                                 headers: {
                                                   'Authorization': 'Bearer ${appState.authToken}',
                                                   'X-User-Email': email,
                                                 },
                                               ).timeout(const Duration(seconds: 4));
                                               if (response.statusCode == 200) {
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
                                                   return;
                                                 }
                                               }
                                             }
                                           }
                                         } catch (_) {}

                                         if (context.mounted) {
                                           ScaffoldMessenger.of(context).showSnackBar(
                                             const SnackBar(content: Text('Đơn hàng đang chờ Admin đối chiếu sao kê và duyệt Pro.')),
                                           );
                                         }
                                       }
                                     } catch (e) {
                                       if (context.mounted) {
                                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đang chờ Admin duyệt Pro...')));
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
                                    order == null ? 'Tạo mã QR thanh toán' : 'Đã chuyển khoản / Kiểm tra duyệt Pro',
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