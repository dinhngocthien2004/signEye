import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/review.dart';
import '../services/app_state.dart';
import '../services/review_service.dart';
import '../theme.dart';

class ReviewSection extends StatefulWidget {
  const ReviewSection({super.key});

  @override
  State<ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<ReviewSection> {
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    ReviewService.instance.loadReviews();
  }

  void _openWriteReviewSheet(BuildContext context) {
    final state = context.read<AppState>();
    final nameCtrl = TextEditingController(
        text: state.userName.isNotEmpty ? state.userName : '');
    final commentCtrl = TextEditingController();
    int selectedRating = 5;
    String selectedRole = 'Học viên B2';

    final roles = [
      'Học viên B2',
      'Tài xế ô tô',
      'Học viên A1',
      'Tài xế công nghệ',
      'Người tham gia giao thông',
      'Thành viên Pro',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.rate_review_rounded,
                          color: AppColors.primary, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Đánh Giá & Nhận Xét',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Chia sẻ trải nghiệm sử dụng SignEye của bạn với cộng đồng',
                    style: TextStyle(fontSize: 12.5, color: AppColors.text2),
                  ),
                  const SizedBox(height: 18),

                  // Star Rating Selector
                  const Text(
                    'Đánh giá chất lượng:',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      final isSelected = starValue <= selectedRating;
                      return IconButton(
                        iconSize: 36,
                        splashRadius: 24,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        icon: Icon(
                          isSelected
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: isSelected
                              ? const Color(0xFFF59E0B)
                              : Colors.grey.shade400,
                        ),
                        onPressed: () {
                          setSheetState(() => selectedRating = starValue);
                        },
                      );
                    }),
                  ),
                  Center(
                    child: Text(
                      _getRatingDescription(selectedRating),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name Field
                  const Text(
                    'Họ và tên của bạn:',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Ví dụ: Nguyễn Văn A',
                      filled: true,
                      fillColor: AppColors.surface2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Role selector
                  const Text(
                    'Bạn là:',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: roles.map((role) {
                      final active = role == selectedRole;
                      return ChoiceChip(
                        label: Text(role),
                        selected: active,
                        onSelected: (val) {
                          if (val) setSheetState(() => selectedRole = role);
                        },
                        selectedColor: AppColors.primaryPale,
                        backgroundColor: AppColors.surface2,
                        labelStyle: TextStyle(
                          fontSize: 11.5,
                          fontWeight:
                              active ? FontWeight.w800 : FontWeight.w600,
                          color:
                              active ? AppColors.primary : AppColors.text2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: active
                                ? AppColors.primary
                                : Colors.transparent,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Comment Field
                  const Text(
                    'Bình luận / Nhận xét:',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: commentCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          'Chia sẻ cảm nhận về tính năng quét AI, ôn thi GPLX, tra cứu biển báo...',
                      filled: true,
                      fillColor: AppColors.surface2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final comment = commentCtrl.text.trim();
                        if (comment.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng nhập nội dung nhận xét!'),
                              backgroundColor: Color(0xFFDC2626),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        Navigator.of(context).pop();

                        await ReviewService.instance.addReview(
                          userName: nameCtrl.text.trim().isEmpty
                              ? 'Người dùng ẩn danh'
                              : nameCtrl.text.trim(),
                          rating: selectedRating,
                          comment: comment,
                          role: selectedRole,
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded,
                                      color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Cảm ơn bạn đã gửi đánh giá!'),
                                ],
                              ),
                              backgroundColor: const Color(0xFF059669),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Gửi Đánh Giá',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getRatingDescription(int rating) {
    switch (rating) {
      case 5:
        return 'Tuyệt vời - Rất hài lòng! ⭐⭐⭐⭐⭐';
      case 4:
        return 'Tốt - Ứng dụng hữu ích! ⭐⭐⭐⭐';
      case 3:
        return 'Bình thường - Cần cải thiện ⭐⭐⭐';
      case 2:
        return 'Chưa hài lòng ⭐⭐';
      case 1:
        return 'Kém ⭐';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ReviewService.instance,
      builder: (context, _) {
        final service = ReviewService.instance;
        final reviews = service.reviews;
        final avgRating = service.averageRating;
        final totalReviews = service.totalReviews;
        final distribution = service.ratingDistribution;
        final displayReviews = _showAll ? reviews : reviews.take(3).toList();

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.stars_rounded,
                          color: Color(0xFFF59E0B), size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Đánh Giá & Bình Luận',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => _openWriteReviewSheet(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                    ),
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    label: const Text(
                      'Viết đánh giá',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Rating summary card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    // Big rating score
                    Column(
                      children: [
                        Text(
                          avgRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF92400E),
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < avgRating.round()
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: const Color(0xFFF59E0B),
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$totalReviews đánh giá',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 1,
                      height: 60,
                      color: const Color(0xFFFDE68A),
                    ),
                    const SizedBox(width: 16),
                    // Breakdown bars
                    Expanded(
                      child: Column(
                        children: [5, 4, 3, 2, 1].map((star) {
                          final count = distribution[star] ?? 0;
                          final fraction = totalReviews > 0
                              ? count / totalReviews
                              : 0.0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1.5),
                            child: Row(
                              children: [
                                Text('$star★',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF92400E))),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: fraction,
                                      backgroundColor:
                                          Colors.white.withOpacity(0.6),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                              Color(0xFFF59E0B)),
                                      minHeight: 5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                SizedBox(
                                  width: 18,
                                  child: Text(
                                    '$count',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFFB45309)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Reviews List
              ...displayReviews.map((rev) => _buildReviewCard(rev)),

              if (reviews.length > 3) ...[
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _showAll = !_showAll),
                    child: Text(
                      _showAll
                          ? 'Thu gọn nhận xét ▲'
                          : 'Xem tất cả ${reviews.length} đánh giá ▼',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewCard(AppReview rev) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Text(
                  rev.userName.isNotEmpty
                      ? rev.userName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rev.userName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      rev.role,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.text2,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < rev.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            rev.comment,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                _formatDate(rev.createdAt),
                style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => ReviewService.instance.likeReview(rev.id),
                child: Row(
                  children: [
                    Icon(
                      rev.likes > 0
                          ? Icons.thumb_up_rounded
                          : Icons.thumb_up_outlined,
                      size: 13,
                      color: rev.likes > 0
                          ? AppColors.primary
                          : AppColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${rev.likes}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: rev.likes > 0
                            ? AppColors.primary
                            : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes == 0 ? 1 : diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }
}
