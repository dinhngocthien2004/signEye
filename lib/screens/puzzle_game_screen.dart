import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/traffic_sign.dart';
import '../services/app_state.dart';
import '../services/data_service.dart';
import '../theme.dart';
import 'game_screen.dart';

class PuzzleGameScreen extends StatefulWidget {
  const PuzzleGameScreen({super.key});

  @override
  State<PuzzleGameScreen> createState() => _PuzzleGameScreenState();
}

class _PuzzleGameScreenState extends State<PuzzleGameScreen> {
  static const int kGridDimension = 5; // 5x5 = 25 mảnh ghép (> 20 mảnh)
  static const int kTotalPieces = kGridDimension * kGridDimension; // 25

  final Random _random = Random();
  List<TrafficSign> _allSigns = [];
  TrafficSign? _currentSign;

  // board[slotIndex] = pieceId (0..24)
  List<int> _board = [];
  int? _selectedSlot;
  int _moves = 0;
  bool _isSolved = false;
  bool _showNumbers = false;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _loadSigns();
  }

  Future<void> _loadSigns() async {
    final signs = await DataService.instance.loadSigns();
    if (!mounted) return;
    setState(() {
      _allSigns = signs.where((s) => s.image.isNotEmpty && s.tenBien.isNotEmpty).toList();
      _startNewPuzzle();
    });
  }

  void _startNewPuzzle({TrafficSign? customSign}) {
    if (_allSigns.isEmpty) return;

    final sign = customSign ?? _allSigns[_random.nextInt(_allSigns.length)];
    // Create pieces 0..24 and shuffle
    final pieces = List.generate(kTotalPieces, (i) => i);
    // Ensure the initial board is not already solved
    do {
      pieces.shuffle(_random);
    } while (_isBoardSolved(pieces));

    setState(() {
      _currentSign = sign;
      _board = pieces;
      _selectedSlot = null;
      _moves = 0;
      _isSolved = false;
      _showPreview = false;
    });
  }

  bool _isBoardSolved(List<int> board) {
    if (board.length != kTotalPieces) return false;
    for (int i = 0; i < kTotalPieces; i++) {
      if (board[i] != i) return false;
    }
    return true;
  }

  void _onSlotTapped(int slotIndex) {
    if (_isSolved) return;

    setState(() {
      if (_selectedSlot == null) {
        _selectedSlot = slotIndex;
      } else if (_selectedSlot == slotIndex) {
        _selectedSlot = null; // Deselect
      } else {
        // Swap pieces
        final firstSlot = _selectedSlot!;
        final temp = _board[firstSlot];
        _board[firstSlot] = _board[slotIndex];
        _board[slotIndex] = temp;
        _moves++;
        _selectedSlot = null;

        // Auto-check if solved
        if (_isBoardSolved(_board)) {
          _handlePuzzleSolved();
        }
      }
    });
  }

  void _checkPuzzleResult() {
    if (_currentSign == null) return;

    int wrongCount = 0;
    for (int i = 0; i < kTotalPieces; i++) {
      if (_board[i] != i) wrongCount++;
    }

    if (wrongCount == 0) {
      _handlePuzzleSolved();
    } else {
      // Thông báo lỗi theo đúng yêu cầu: "nếu ghép bị sai thì sẽ thông báo lỗi"
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 28),
              SizedBox(width: 8),
              Text('Chưa chính xác!', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Còn $wrongCount/25 mảnh ghép chưa đúng vị trí.',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.danger),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hãy quan sát ảnh mẫu hoặc bật "Gợi ý số" để tìm các mảnh ghép phù hợp và hoán đổi lại nhé!',
                style: TextStyle(fontSize: 12.5, color: AppColors.text2, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _showNumbers = true);
              },
              child: const Text('Bật gợi ý số'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Thử ghép tiếp'),
            ),
          ],
        ),
      );
    }
  }

  void _handlePuzzleSolved() {
    if (_isSolved) return;
    _isSolved = true;

    final state = context.read<AppState>();
    // Thưởng 10 xu theo yêu cầu: "nếu ghép đúng 1 hình ảnh sẽ nhận được 10 xu"
    state.addCoins(10);

    // Hiển thị giải thích chi tiết biển báo theo yêu cầu:
    // "nếu ghép đúng thì sẽ giải thích biển báo này là gì, để người dùng biết"
    _showExplanationModal(_currentSign!);
  }

  void _autoSolveForDemo() {
    setState(() {
      _board = List.generate(kTotalPieces, (i) => i);
      _selectedSlot = null;
    });
    _handlePuzzleSolved();
  }

  void _showExplanationModal(TrafficSign sign) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Celebration Header
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD1FAE5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.celebration_rounded, color: Color(0xFF059669), size: 32),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'GHÉP HÌNH THÀNH CÔNG! 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF065F46)),
              ),
              const SizedBox(height: 4),

              // +10 Coins Badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)]),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🪙', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 6),
                      Text(
                        '+10 XU THƯỞNG',
                        style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF78350F), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Assembled Sign Image
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.line),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Image.asset(sign.image, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 14),

              // Sign Information & Explanation
              Text(
                '${sign.maBien.isNotEmpty ? "${sign.maBien}: " : ""}${sign.tenBien}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.text),
              ),
              if (sign.nhomBien.isNotEmpty) ...[
                const SizedBox(height: 4),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPale,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      sign.nhomBien,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Meaning Explanation
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text('Ý nghĩa biển báo:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      sign.yNghia.isNotEmpty ? sign.yNghia : 'Biển báo quy định người tham gia giao thông cần chú ý.',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.text2, height: 1.4),
                    ),
                    if (sign.mucPhatXeMay.isNotEmpty || sign.mucPhatOto.isNotEmpty) ...[
                      const Divider(height: 18),
                      const Text('Mức phạt vi phạm:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      const SizedBox(height: 4),
                      if (sign.mucPhatXeMay.isNotEmpty)
                        Text('• Xe máy: ${sign.mucPhatXeMay}', style: const TextStyle(fontSize: 12, color: AppColors.text2)),
                      if (sign.mucPhatOto.isNotEmpty)
                        Text('• Ô tô: ${sign.mucPhatOto}', style: const TextStyle(fontSize: 12, color: AppColors.text2)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openRedeemSheet();
                      },
                      icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                      label: const Text('Đổi gói Pro'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _startNewPuzzle();
                      },
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text('Biển tiếp theo'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
    final sign = _currentSign;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghép Hình Biển Báo'),
        actions: [
          // Coin badge
          GestureDetector(
            onTap: _openRedeemSheet,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text(
                    '${state.coins} xu',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF92400E), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: sign == null
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                // Ensure puzzle board fits nicely on screen
                final maxAvailableWidth = constraints.maxWidth - 32;
                final boardSize = maxAvailableWidth.clamp(280.0, 360.0);
                const gap = 1.5;
                // Border (2*2) + Padding (2*2) = 8.0
                final innerBoardSize = boardSize - 8.0;
                final pieceSize = (innerBoardSize - (kGridDimension - 1) * gap) / kGridDimension;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header Stats: Pieces count & Moves & Reward badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryPale,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('25 mảnh ghép', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
                                ),
                                const SizedBox(width: 8),
                                Text('Đổi: $_moves lần', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text2)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF10B981)),
                              ),
                              child: const Text('+10 xu khi ghép đúng', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF065F46))),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Tool buttons row (Preview sample, Toggle numbers, Change sign)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: _showPreview ? AppColors.primaryPale : Colors.transparent,
                            ),
                            onPressed: () => setState(() => _showPreview = !_showPreview),
                            icon: Icon(_showPreview ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 16),
                            label: Text(_showPreview ? 'Ẩn ảnh mẫu' : 'Ảnh mẫu', style: const TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: _showNumbers ? AppColors.primaryPale : Colors.transparent,
                            ),
                            onPressed: () => setState(() => _showNumbers = !_showNumbers),
                            icon: const Icon(Icons.numbers_rounded, size: 16),
                            label: Text(_showNumbers ? 'Tắt số' : 'Gợi ý số', style: const TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () => _startNewPuzzle(),
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Đổi biển', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Sample preview if toggled
                      if (_showPreview) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary),
                          ),
                          child: Column(
                            children: [
                              Image.asset(sign.image, width: 80, height: 80, fit: BoxFit.contain),
                              const SizedBox(height: 4),
                              Text(sign.tenBien, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ],

                      // The 5x5 Puzzle Board
                      Container(
                        width: boardSize,
                        height: boardSize,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.line, width: 2),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Center(
                          child: SizedBox(
                            width: innerBoardSize,
                            height: innerBoardSize,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(kGridDimension, (row) {
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: List.generate(kGridDimension, (col) {
                                final slotIndex = row * kGridDimension + col;
                                final pieceId = _board[slotIndex];
                                final isSelected = _selectedSlot == slotIndex;

                                return GestureDetector(
                                  onTap: () => _onSlotTapped(slotIndex),
                                  child: Container(
                                    width: pieceSize,
                                    height: pieceSize,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
                                        width: isSelected ? 2.5 : 1,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        _PuzzlePieceTile(
                                          sign: sign,
                                          pieceId: pieceId,
                                          pieceSize: pieceSize,
                                          boardSize: boardSize,
                                        ),
                                        if (_showNumbers)
                                          Positioned(
                                            top: 2,
                                            left: 2,
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(alpha: 0.65),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '${pieceId + 1}',
                                                style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w800),
                                              ),
                                            ),
                                          ),
                                        if (isSelected)
                                          Container(
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                      const SizedBox(height: 16),

                      // Instructions banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app_rounded, size: 16, color: AppColors.text2),
                            SizedBox(width: 6),
                            Text(
                              'Chạm mảnh 1 rồi chạm mảnh 2 để hoán đổi vị trí',
                              style: TextStyle(fontSize: 11.5, color: AppColors.text2, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Check Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _checkPuzzleResult,
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: const Text('Kiểm tra kết quả', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Demo Auto-solve for testing / quick exploration
                      TextButton(
                        onPressed: _autoSolveForDemo,
                        child: const Text('Hoàn thành nhanh (Chế độ xem mẫu)', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

/// Renders a single cropped tile from the full traffic sign image
class _PuzzlePieceTile extends StatelessWidget {
  final TrafficSign sign;
  final int pieceId;
  final double pieceSize;
  final double boardSize;

  const _PuzzlePieceTile({
    required this.sign,
    required this.pieceId,
    required this.pieceSize,
    required this.boardSize,
  });

  @override
  Widget build(BuildContext context) {
    const dim = PuzzleGameScreenState.kGridDimension;
    final r = pieceId ~/ dim;
    final c = pieceId % dim;

    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        width: pieceSize,
        height: pieceSize,
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: boardSize,
          maxWidth: boardSize,
          minHeight: boardSize,
          maxHeight: boardSize,
          child: Transform.translate(
            offset: Offset(-c * pieceSize, -r * pieceSize),
            child: SizedBox(
              width: boardSize,
              height: boardSize,
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.all(boardSize * 0.08),
                child: Image.asset(
                  sign.image,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.traffic, color: AppColors.muted, size: 24),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper constant to expose grid dimension to _PuzzlePieceTile
class PuzzleGameScreenState {
  static const int kGridDimension = 5;
}
