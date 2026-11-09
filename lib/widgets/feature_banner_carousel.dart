import 'dart:async';
import 'package:flutter/material.dart';

import '../screens/scan_screen.dart';
import '../screens/chatbot_screen.dart';
import '../screens/exam_home_screen.dart';
import '../screens/puzzle_game_screen.dart';
import '../screens/user_guide_screen.dart';

class FeatureBannerItem {
  final String title;
  final String badge;
  final String description;
  final String actionLabel;
  final IconData actionIcon;
  final String emoji;
  final List<Color> gradient;
  final Color badgeColor;
  final VoidCallback onTap;

  const FeatureBannerItem({
    required this.title,
    required this.badge,
    required this.description,
    required this.actionLabel,
    required this.actionIcon,
    required this.emoji,
    required this.gradient,
    required this.badgeColor,
    required this.onTap,
  });
}

class FeatureBannerCarousel extends StatefulWidget {
  const FeatureBannerCarousel({super.key});

  @override
  State<FeatureBannerCarousel> createState() => _FeatureBannerCarouselState();
}

class _FeatureBannerCarouselState extends State<FeatureBannerCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      final nextPage = (_currentPage + 1) % 5;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  List<FeatureBannerItem> _buildItems(BuildContext context) {
    return [
      FeatureBannerItem(
        title: 'Quét Biển Báo AI Tức Thì',
        badge: '⚡ CÔNG NGHỆ AI',
        description:
            'Chụp hoặc tải ảnh biển báo để nhận diện mã biển, quy định cấm, mức phạt & điểm trừ GPLX theo Nghị định 168/2024.',
        actionLabel: 'Quét ngay',
        actionIcon: Icons.camera_alt_rounded,
        emoji: '📸',
        gradient: const [Color(0xFF0D9488), Color(0xFF0F766E)],
        badgeColor: const Color(0xFF2DD4BF),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const ScanScreen())),
      ),
      FeatureBannerItem(
        title: 'Trợ Lý AI Luật Giao Thông',
        badge: '🤖 HỖ TRỢ 24/7',
        description:
            'Hỏi đáp luật giao thông, giải đáp tình huống phạt nguội và hỗ trợ gửi ảnh biển báo để trợ lý AI phân tích trực quan.',
        actionLabel: 'Chat cùng AI',
        actionIcon: Icons.chat_bubble_outline_rounded,
        emoji: '🤖',
        gradient: const [Color(0xFF059669), Color(0xFF047857)],
        badgeColor: const Color(0xFF6EE7B7),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const AiChatbotScreen())),
      ),
      FeatureBannerItem(
        title: 'Luyện Thi Sát Hạch GPLX',
        badge: '🚗 ĐỀ THI CHUẨN',
        description:
            'Ôn tập bộ câu hỏi nhận diện biển báo thường gặp trong kỳ thi sát hạch lái xe máy (A1, A2) và ô tô (B1, B2).',
        actionLabel: 'Vào thi ngay',
        actionIcon: Icons.fact_check_rounded,
        emoji: '🚗',
        gradient: const [Color(0xFF4F46E5), Color(0xFF4338CA)],
        badgeColor: const Color(0xFFA5B4FC),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const ExamHomeScreen())),
      ),
      FeatureBannerItem(
        title: 'Ghép Hình & Đố Vui Nhận Xu',
        badge: '🧩 +10 XU/HÌNH',
        description:
            'Ghép đúng 25 mảnh biển báo hoặc đố vui tích lũy xu để đổi gói SignEye Pro 1-2 tháng hoàn toàn miễn phí!',
        actionLabel: 'Chơi ngay',
        actionIcon: Icons.extension_rounded,
        emoji: '🧩',
        gradient: const [Color(0xFFD97706), Color(0xFFB45309)],
        badgeColor: const Color(0xFFFDE68A),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const PuzzleGameScreen())),
      ),
      FeatureBannerItem(
        title: 'Hướng Dẫn Sử Dụng Chi Tiết',
        badge: '📖 CẨM NANG',
        description:
            'Xem hướng dẫn từng bước từ cách quét ảnh, tra cứu 386 biển, so sánh biển báo đến kinh nghiệm thi đỗ GPLX.',
        actionLabel: 'Xem hướng dẫn',
        actionIcon: Icons.menu_book_rounded,
        emoji: '📖',
        gradient: const [Color(0xFF7C3AED), Color(0xFF6D28D9)],
        badgeColor: const Color(0xFFC4B5FD),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const UserGuideScreen())),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildItems(context);

    return Column(
      children: [
        SizedBox(
          height: 168,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: item.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: item.gradient.first.withOpacity(0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: item.badgeColor.withOpacity(0.6)),
                          ),
                          child: Text(
                            item.badge,
                            style: TextStyle(
                              color: item.badgeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(item.emoji, style: const TextStyle(fontSize: 22)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        item.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: item.onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: item.gradient.first,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(item.actionIcon, size: 14),
                        label: Text(
                          item.actionLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(items.length, (index) {
            final active = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF0D9488)
                    : Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}
