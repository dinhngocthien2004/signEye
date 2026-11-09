import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/review.dart';

class ReviewService extends ChangeNotifier {
  static final ReviewService instance = ReviewService._internal();
  ReviewService._internal();

  static const String _prefKey = 'signeye_user_reviews_v1';
  List<AppReview> _reviews = [];
  bool _loaded = false;

  List<AppReview> get reviews => List.unmodifiable(_reviews);

  double get averageRating {
    if (_reviews.isEmpty) return 5.0;
    final total = _reviews.fold<int>(0, (sum, r) => sum + r.rating);
    return total / _reviews.length;
  }

  int get totalReviews => _reviews.length;

  Map<int, int> get ratingDistribution {
    final map = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in _reviews) {
      if (map.containsKey(r.rating)) {
        map[r.rating] = (map[r.rating] ?? 0) + 1;
      }
    }
    return map;
  }

  Future<void> loadReviews() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        _reviews = list.map((e) => AppReview.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _reviews = _getSeedReviews();
        await _save();
      }
    } catch (_) {
      _reviews = _getSeedReviews();
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> addReview({
    required String userName,
    required int rating,
    required String comment,
    String role = 'Người dùng SignEye',
  }) async {
    final newReview = AppReview(
      id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
      userName: userName.trim().isEmpty ? 'Người dùng ẩn danh' : userName.trim(),
      rating: rating.clamp(1, 5),
      comment: comment.trim(),
      role: role,
      createdAt: DateTime.now(),
      likes: 0,
    );

    _reviews.insert(0, newReview);
    await _save();
    notifyListeners();
  }

  Future<void> deleteReview(String id) async {
    _reviews.removeWhere((r) => r.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> likeReview(String id) async {
    final idx = _reviews.indexWhere((r) => r.id == id);
    if (idx != -1) {
      final old = _reviews[idx];
      _reviews[idx] = AppReview(
        id: old.id,
        userName: old.userName,
        rating: old.rating,
        comment: old.comment,
        role: old.role,
        createdAt: old.createdAt,
        likes: old.likes + 1,
      );
      await _save();
      notifyListeners();
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(_reviews.map((r) => r.toJson()).toList());
      await prefs.setString(_prefKey, data);
    } catch (_) {}
  }

  List<AppReview> _getSeedReviews() {
    return [
      AppReview(
        id: 'rev_1',
        userName: 'Nguyễn Thành Nam',
        rating: 5,
        comment:
            'Ứng dụng quét biển báo rất nhanh và chuẩn xác! Mình chụp ảnh biển cấm từ trong xe mà vẫn nhận diện đúng mã P.102 kèm mức phạt tiền và điểm trừ GPLX rất rõ ràng.',
        role: 'Tài xế ô tô (Hà Nội)',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        likes: 18,
      ),
      AppReview(
        id: 'rev_2',
        userName: 'Trần Thị Thu Thảo',
        rating: 5,
        comment:
            'Nhờ bộ đề thi sát hạch có ảnh biển báo và minigame ghép hình mà mình đã thi đỗ lý thuyết bằng lái B2 với 35/35 điểm. Chơi đố vui còn tích được xu đổi gói Pro nữa, cực kỳ thích!',
        role: 'Học viên bằng lái B2',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        likes: 25,
      ),
      AppReview(
        id: 'rev_3',
        userName: 'Lê Hoàng Dũng',
        rating: 5,
        comment:
            'Trợ lý Chatbot AI rất thông minh, hỗ trợ gửi ảnh biển báo hỏi đáp luật giao thông bất kỳ lúc nào. Giao diện đẹp, dễ dùng, đầy đủ 386 biển báo theo quy chuẩn mới nhất.',
        role: 'Tài xế công nghệ Grab',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        likes: 12,
      ),
      AppReview(
        id: 'rev_4',
        userName: 'Phạm Minh Quân',
        rating: 4,
        comment:
            'Rất tiện ích cho người mới tập lái xe máy. Mức phạt cập nhật đúng theo Nghị định mới nhất 168/2024. Đánh giá 5 sao cho team phát triển!',
        role: 'Sinh viên · Học bằng A1',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        likes: 9,
      ),
      AppReview(
        id: 'rev_5',
        userName: 'Vũ Quốc Bảo',
        rating: 5,
        comment:
            'Gói Pro 39k quá rẻ so với giá trị nhận được, quét không giới hạn lượt, tra cứu mức phạt nhanh khi đi đường xa. Đáng để ủng hộ app Việt.',
        role: 'Thành viên Pro',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        likes: 15,
      ),
    ];
  }
}
