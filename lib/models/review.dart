import 'dart:convert';

class AppReview {
  final String id;
  final String userName;
  final int rating; // 1 to 5
  final String comment;
  final String role; // e.g. "Học viên B2", "Tài xế công nghệ"
  final DateTime createdAt;
  final int likes;

  const AppReview({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.role,
    required this.createdAt,
    this.likes = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userName': userName,
        'rating': rating,
        'comment': comment,
        'role': role,
        'createdAt': createdAt.toIso8601String(),
        'likes': likes,
      };

  factory AppReview.fromJson(Map<String, dynamic> json) {
    return AppReview(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userName: json['userName'] as String? ?? 'Người dùng',
      rating: json['rating'] is int ? json['rating'] as int : int.tryParse('${json['rating']}') ?? 5,
      comment: json['comment'] as String? ?? '',
      role: json['role'] as String? ?? 'Người dùng',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      likes: json['likes'] is int ? json['likes'] as int : 0,
    );
  }
}
