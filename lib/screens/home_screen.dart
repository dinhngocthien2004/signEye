import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/traffic_sign.dart';
import '../services/app_state.dart';
import '../services/data_service.dart';
import '../theme.dart';
import '../widgets/sign_detail_sheet.dart';
import 'scan_screen.dart';
import 'search_screen.dart';
import 'learning_screen.dart';
import 'exam_home_screen.dart';
import 'compare_screen.dart';
import 'handbook_screen.dart';
import 'account_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TrafficSign> _signs = [];

  @override
  void initState() {
    super.initState();
    DataService.instance.loadSigns().then((s) => setState(() => _signs = s));
  }

  List<TrafficSign> get _quickPicks => _signs.take(10).toList();

  void _openGroup(String group) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SearchScreen(initialGroup: group)));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final planLabel = state.isPro ? 'gói Pro · Không giới hạn quét' : 'gói Free · Còn ${state.scansRemainingToday} lượt quét hôm nay';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.remove_red_eye_rounded, color: AppColors.primary),
            SizedBox(width: 6),
            Text('SignEye'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AccountScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primary2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Xin chào 👋', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(state.userName.isEmpty ? 'Người dùng' : state.userName,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text('Tiếp tục với $planLabel',
                              style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white24,
                      child: Text(
                        state.userName.isNotEmpty ? state.userName[0].toUpperCase() : 'U',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const ScanScreen())),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                    ),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Quét biển báo ngay'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _sectionHeader('Nhóm biển báo'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.6,
            children: [
              _categoryCard('Cấm', 'Nhóm P · Đỏ', Icons.block_rounded, AppColors.danger,
                  () => _openGroup('Biển báo cấm')),
              _categoryCard('Nguy hiểm', 'Nhóm W · Vàng', Icons.warning_amber_rounded, AppColors.warning,
                  () => _openGroup('Biển báo nguy hiểm')),
              _categoryCard('Hiệu lệnh', 'Nhóm R · Xanh dương', Icons.info_rounded, AppColors.blue,
                  () => _openGroup('Biển hiệu lệnh')),
              _categoryCard('Chỉ dẫn', 'Nhóm I · Xanh dương', Icons.signpost_rounded, AppColors.primary2,
                  () => _openGroup('Biển chỉ dẫn')),
            ],
          ),
          const SizedBox(height: 22),
          _sectionHeader('Tra cứu nhanh', action: 'Xem tất cả', onAction: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const SearchScreen()))),
          const SizedBox(height: 10),
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _quickPicks.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final s = _quickPicks[i];
                return GestureDetector(
                  onTap: () => showSignDetailSheet(context, s, allSigns: _signs),
                  child: Container(
                    width: 84,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Image.asset(s.image,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined)),
                        ),
                        const SizedBox(height: 4),
                        Text(s.maBien,
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 22),
          _sectionHeader('Tiện ích GPLX'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.92,
            children: [
              _moduleButton('📖', 'Học GPLX', 'Lưu tiến độ',
                  () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LearningScreen()))),
              _moduleButton('📝', 'Thi GPLX', '25 câu',
                  () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExamHomeScreen()))),
              _moduleButton('⚖️', 'So sánh', '3 biển',
                  () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CompareScreen()))),
              _moduleButton('📰', 'Cẩm nang', 'Mẹo lái xe',
                  () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HandbookScreen()))),
              _moduleButton('🕘', 'Lịch sử', 'Quét và thi',
                  () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen()))),
              _moduleButton('👤', 'Tài khoản', 'Free / Pro',
                  () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AccountScreen()))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, {String? action, VoidCallback? onAction}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action, style: const TextStyle(fontSize: 12))),
      ],
    );
  }

  Widget _categoryCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  Text(subtitle, style: const TextStyle(fontSize: 10.5, color: AppColors.text2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moduleButton(String emoji, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            const SizedBox(height: 2),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
