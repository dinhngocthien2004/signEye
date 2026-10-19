import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/traffic_sign.dart';
import '../services/app_state.dart';
import '../services/data_service.dart';
import '../theme.dart';
import 'puzzle_game_screen.dart';

class GameQuestion {
  final TrafficSign targetSign;
  final List<String> options;
  final int correctIndex;

  const GameQuestion({
    required this.targetSign,
    required this.options,
    required this.correctIndex,
  });
}

class TrafficSignGameScreen extends StatefulWidget {
  const TrafficSignGameScreen({super.key});

  @override
  State<TrafficSignGameScreen> createState() => _TrafficSignGameScreenState();
}

class _TrafficSignGameScreenState extends State<TrafficSignGameScreen>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();
  List<TrafficSign> _allSigns = [];
  GameQuestion? _currentQuestion;

  int? _selectedIndex;
  bool _isAnswered = false;
  int _streak = 0;
  int _correctCount = 0;
  int _totalAnswered = 0;
  int _sessionCoinsEarned = 0;

  late AnimationController _animCtrl;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut));

    _loadGameData();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGameData() async {
    final signs = await DataService.instance.loadSigns();
    if (!mounted) return;
    setState(() {
      _allSigns = signs.where((s) => s.tenBien.trim().isNotEmpty).toList();
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (_allSigns.length < 4) return;

    // Pick 1 random sign as target
    final target = _allSigns[_random.nextInt(_allSigns.length)];

    // Pick 3 random distractor signs with distinct names
    final distractors = <String>{};
    int attempts = 0;
    while (distractors.length < 3 && attempts < 100) {
      attempts++;
      final candidate = _allSigns[_random.nextInt(_allSigns.length)];
      if (candidate.tenBien != target.tenBien && candidate.tenBien.isNotEmpty) {
        distractors.add(candidate.tenBien);
      }
    }

    final options = [target.tenBien, ...distractors]..shuffle(_random);
    final correctIndex = options.indexOf(target.tenBien);

    setState(() {
      _currentQuestion = GameQuestion(
        targetSign: target,
        options: options,
        correctIndex: correctIndex,
      );
      _selectedIndex = null;
      _isAnswered = false;
    });
  }

  void _handleSelectAnswer(int index) {
    if (_isAnswered || _currentQuestion == null) return;

    final isCorrect = index == _currentQuestion!.correctIndex;
    final state = context.read<AppState>();

    setState(() {
      _selectedIndex = index;
      _isAnswered = true;
      _totalAnswered++;

      if (isCorrect) {
        _correctCount++;
        _streak++;
        _sessionCoinsEarned += 5;
        state.addCoins(5);
        _animCtrl.forward(from: 0.0);
      } else {
        _streak = 0;
      }
    });

    // If user hit 1000 coins milestone for the first time, show reward hint
    if (state.coins >= 1000 && isCorrect && state.coins - 5 < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '🎉 Chúc mừng bạn đã tích lũy đủ 1.000 xu! Có thể đổi sang 1.000đ mua gói Pro ngay!'),
          duration: Duration(seconds: 4),
          backgroundColor: Color(0xFFD97706),
        ),
      );
    }
  }

  void _openRedeemSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RedeemProSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final q = _currentQuestion;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đố Vui Biển Báo'),
        actions: [
          // Coin balance pill with tap to redeem
          GestureDetector(
            onTap: _openRedeemSheet,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                margin: const EdgeInsets.only(right: 14),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      '${state.coins} xu',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF92400E),
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, size: 10, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: q == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Stats bar (Streak, Score, Exchange CTA)
                  Row(
                    children: [
                      _statPill(
                        icon: Icons.local_fire_department_rounded,
                        color: Colors.deepOrange,
                        label: 'Chuỗi: $_streak',
                      ),
                      const SizedBox(width: 8),
                      _statPill(
                        icon: Icons.check_circle_outline_rounded,
                        color: Colors.green,
                        label: 'Đúng: $_correctCount/$_totalAnswered',
                      ),
                      const Spacer(),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: _openRedeemSheet,
                        icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                        label: const Text('Đổi gói Pro',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Quick switch to Puzzle Game
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PuzzleGameScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF8B5CF6)),
                      ),
                      child: Row(
                        children: [
                          const Text('🧩', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chơi Ghép Hình Biển Báo (> 20 mảnh)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: Color(0xFF4C1D95),
                                  ),
                                ),
                                Text(
                                  'Ghép đúng nhận ngay 10 xu & giải thích chi tiết!',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6D28D9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF8B5CF6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_forward_rounded,
                                size: 14, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Question Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.line),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryPale,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                q.targetSign.nhomBien.isNotEmpty
                                    ? q.targetSign.nhomBien
                                    : 'Biển báo giao thông',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            if (q.targetSign.maBien.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surface2,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Mã: ${q.targetSign.maBien}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Traffic Sign Image
                        Container(
                          width: 140,
                          height: 140,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Image.asset(
                            q.targetSign.image,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.traffic_rounded,
                              size: 48,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          'Đây là biển báo gì?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Chọn đúng để nhận ngay +5 xu 🪙',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4 Answer Options
                  ...List.generate(q.options.length, (i) {
                    return _buildOptionButton(i, q.options[i], q.correctIndex);
                  }),

                  // Post-answer feedback & Explanation
                  if (_isAnswered) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _selectedIndex == q.correctIndex
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedIndex == q.correctIndex
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _selectedIndex == q.correctIndex
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                color: _selectedIndex == q.correctIndex
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFDC2626),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedIndex == q.correctIndex
                                      ? 'Chính xác! Bạn được cộng +5 xu 🎉'
                                      : 'Chưa chính xác! Đáp án đúng: "${q.targetSign.tenBien}"',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: _selectedIndex == q.correctIndex
                                        ? const Color(0xFF065F46)
                                        : const Color(0xFF991B1B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (q.targetSign.yNghia.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              '💡 Ý nghĩa: ${q.targetSign.yNghia}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.text2,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Next question button
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _nextQuestion,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Câu hỏi tiếp theo',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _statPill({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(int index, String optionText, int correctIndex) {
    final letters = ['A', 'B', 'C', 'D'];
    Color bg = AppColors.surface;
    Color border = AppColors.line;
    Color textCol = AppColors.text;
    IconData? icon;

    if (_isAnswered) {
      if (index == correctIndex) {
        bg = const Color(0xFFD1FAE5);
        border = const Color(0xFF10B981);
        textCol = const Color(0xFF065F46);
        icon = Icons.check_circle_rounded;
      } else if (index == _selectedIndex) {
        bg = const Color(0xFFFEE2E2);
        border = const Color(0xFFEF4444);
        textCol = const Color(0xFF991B1B);
        icon = Icons.cancel_rounded;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _handleSelectAnswer(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _isAnswered && index == correctIndex
                      ? const Color(0xFF10B981)
                      : (_isAnswered && index == _selectedIndex
                          ? const Color(0xFFEF4444)
                          : AppColors.surface2),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  letters[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _isAnswered &&
                            (index == correctIndex || index == _selectedIndex)
                        ? Colors.white
                        : AppColors.text2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  optionText,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: textCol,
                    height: 1.3,
                  ),
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 6),
                Icon(
                  icon,
                  size: 20,
                  color: index == correctIndex
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal bottom sheet for exchanging coins to cash and redeeming Pro packages
class RedeemProSheet extends StatefulWidget {
  const RedeemProSheet({super.key});

  @override
  State<RedeemProSheet> createState() => _RedeemProSheetState();
}

class _RedeemProSheetState extends State<RedeemProSheet> {
  final nf = NumberFormat('#,###', 'vi');

  void _exchange1000Coins(AppState state) async {
    if (state.coins < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn cần tích lũy tối thiểu 1.000 xu để đổi tiền!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final success = await state.exchangeCoinsToCash(coinsToExchange: 1000);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Đã đổi 1.000 xu thành công sang 1.000đ tiền thưởng!'),
          backgroundColor: Color(0xFF059669),
        ),
      );
    }
  }

  void _exchangeAllCoins(AppState state) async {
    final availableThousands = (state.coins ~/ 1000) * 1000;
    if (availableThousands < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn cần tối thiểu 1.000 xu để thực hiện đổi!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final success =
        await state.exchangeCoinsToCash(coinsToExchange: availableThousands);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '🎉 Đã đổi $availableThousands xu sang ${nf.format(availableThousands)}đ thành công!'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    }
  }

  void _redeemProWithCoins({
    required BuildContext context,
    required AppState state,
    required int days,
    required int costCoins,
    required String title,
  }) async {
    if (state.coins < costCoins) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Bạn chưa đủ xu ($costCoins xu). Hãy chơi game để tích lũy thêm!'),
        ),
      );
      return;
    }

    final success =
        await state.buyProWithCoins(days: days, costCoins: costCoins);
    if (!context.mounted) return;
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Đổi thành công $title! Bạn đã được kích hoạt Pro!'),
          backgroundColor: const Color(0xFF059669),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _redeemProWithCash({
    required BuildContext context,
    required AppState state,
    required int days,
    required int costVnd,
    required String title,
  }) async {
    if (state.rewardBalance < costVnd) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Số dư tiền đổi từ xu chưa đủ (${nf.format(costVnd)}đ). Hãy đổi thêm xu!'),
        ),
      );
      return;
    }

    final success =
        await state.buyProWithRewardBalance(days: days, costVnd: costVnd);
    if (!context.mounted) return;
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Đổi thành công $title từ số dư tiền thưởng!'),
          backgroundColor: const Color(0xFF059669),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Đổi Xu & Mua Gói Pro',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Balances summary card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Số xu hiện có',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF92400E))),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('🪙 ', style: TextStyle(fontSize: 18)),
                            Text(
                              '${state.coins} xu',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF78350F),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tiền quy đổi (VNĐ)',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF92400E))),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('💵 ', style: TextStyle(fontSize: 18)),
                            Text(
                              '${nf.format(state.rewardBalance)}đ',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF78350F),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Exchange coins to cash action
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tỷ lệ quy đổi: 1.000 xu = 1.000 VNĐ',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Cứ tích lũy đủ 1.000 xu từ các câu hỏi đúng, bạn có thể đổi thành tiền VNĐ hoặc dùng trực tiếp để mở gói Pro.',
                    style: TextStyle(fontSize: 11.5, color: AppColors.text2, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: state.coins >= 1000
                              ? () => _exchange1000Coins(state)
                              : null,
                          child: const Text('Đổi 1.000 xu ➔ 1.000đ'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: state.coins >= 1000
                              ? () => _exchangeAllCoins(state)
                              : null,
                          child: const Text('Đổi tất cả xu'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            const Text(
              'Dùng Xu / Tiền Thưởng Mua Gói Pro',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            const SizedBox(height: 8),

            // Pro Package 1: 1 Day trial
            _proPackageCard(
              title: 'Gói Pro 1 Ngày (Trải nghiệm)',
              subtitle: 'Mở khóa toàn bộ tính năng và quét AI không giới hạn trong 24h',
              priceText: '1.000 xu hoặc 1.000đ',
              badge: 'Tiết kiệm',
              hasCoins: state.coins >= 1000,
              hasCash: state.rewardBalance >= 1000,
              onRedeemCoins: () => _redeemProWithCoins(
                context: context,
                state: state,
                days: 1,
                costCoins: 1000,
                title: 'Gói Pro 1 Ngày',
              ),
              onRedeemCash: () => _redeemProWithCash(
                context: context,
                state: state,
                days: 1,
                costVnd: 1000,
                title: 'Gói Pro 1 Ngày',
              ),
            ),
            const SizedBox(height: 10),

            // Pro Package 2: 7 Days
            _proPackageCard(
              title: 'Gói Pro 1 Tuần',
              subtitle: 'Sử dụng trọn vẹn 7 ngày, thoải mái học và ôn thi GPLX',
              priceText: '10.000 xu hoặc 10.000đ',
              badge: 'Phổ biến',
              hasCoins: state.coins >= 10000,
              hasCash: state.rewardBalance >= 10000,
              onRedeemCoins: () => _redeemProWithCoins(
                context: context,
                state: state,
                days: 7,
                costCoins: 10000,
                title: 'Gói Pro 1 Tuần',
              ),
              onRedeemCash: () => _redeemProWithCash(
                context: context,
                state: state,
                days: 7,
                costVnd: 10000,
                title: 'Gói Pro 1 Tuần',
              ),
            ),
            const SizedBox(height: 10),

            // Pro Package 3: 1 Month
            _proPackageCard(
              title: 'Gói Pro 1 Tháng (Chuẩn VIP)',
              subtitle: 'Mở khóa toàn bộ 30 ngày: Quét AI không giới hạn, cẩm nang, không quảng cáo',
              priceText: '39.000 xu hoặc 39.000đ',
              badge: 'VIP 1 Tháng',
              hasCoins: state.coins >= 39000,
              hasCash: state.rewardBalance >= 39000,
              onRedeemCoins: () => _redeemProWithCoins(
                context: context,
                state: state,
                days: 30,
                costCoins: 39000,
                title: 'Gói Pro 1 Tháng',
              ),
              onRedeemCash: () => _redeemProWithCash(
                context: context,
                state: state,
                days: 30,
                costVnd: 39000,
                title: 'Gói Pro 1 Tháng',
              ),
            ),
            const SizedBox(height: 10),

            // Pro Package 4: 2 Months
            _proPackageCard(
              title: 'Gói Pro 2 Tháng (Siêu Tiết Kiệm)',
              subtitle: 'Mở khóa toàn bộ 60 ngày liên tục, tiết kiệm hơn khi đổi xu hoặc tiền thưởng',
              priceText: '75.000 xu hoặc 75.000đ',
              badge: 'VIP 2 Tháng',
              hasCoins: state.coins >= 75000,
              hasCash: state.rewardBalance >= 75000,
              onRedeemCoins: () => _redeemProWithCoins(
                context: context,
                state: state,
                days: 60,
                costCoins: 75000,
                title: 'Gói Pro 2 Tháng',
              ),
              onRedeemCash: () => _redeemProWithCash(
                context: context,
                state: state,
                days: 60,
                costVnd: 75000,
                title: 'Gói Pro 2 Tháng',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _proPackageCard({
    required String title,
    required String subtitle,
    required String priceText,
    required String badge,
    required bool hasCoins,
    required bool hasCash,
    required VoidCallback onRedeemCoins,
    required VoidCallback onRedeemCash,
  }) {
    final canAfford = hasCoins || hasCash;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canAfford ? AppColors.primary : AppColors.line,
          width: canAfford ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13.5)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryPale,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(fontSize: 11.5, color: AppColors.text2, height: 1.3)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  priceText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Color(0xFFD97706),
                  ),
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: hasCoins ? onRedeemCoins : null,
                    child: const Text('🪙 Đổi xu', style: TextStyle(fontSize: 11.5)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: hasCash ? onRedeemCash : null,
                    child: const Text('💵 Mua tiền', style: TextStyle(fontSize: 11.5)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
