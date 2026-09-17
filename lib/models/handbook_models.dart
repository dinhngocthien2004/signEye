class HandbookComment {
  final String author;
  final String content;
  final DateTime date;

  HandbookComment({required this.author, required this.content, required this.date});

  factory HandbookComment.fromJson(Map<String, dynamic> json) => HandbookComment(
        author: json['author']?.toString() ?? '',
        content: json['content']?.toString() ?? '',
        date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'author': author,
        'content': content,
        'date': date.toIso8601String(),
      };
}

class HandbookPost {
  final int id;
  final String title;
  final String content;
  final String author;
  final DateTime date;
  final int likes;
  final String category;
  final List<String> tags;

  HandbookPost({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.date,
    required this.likes,
    required this.category,
    required this.tags,
  });

  HandbookPost copyWith({int? likes}) => HandbookPost(
        id: id,
        title: title,
        content: content,
        author: author,
        date: date,
        likes: likes ?? this.likes,
        category: category,
        tags: tags,
      );

  factory HandbookPost.fromJson(Map<String, dynamic> json) => HandbookPost(
        id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
        title: json['title']?.toString() ?? '',
        content: json['content']?.toString() ?? '',
        author: json['author']?.toString() ?? 'Ẩn danh',
        date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
        likes: json['likes'] is int ? json['likes'] as int : int.tryParse('${json['likes']}') ?? 0,
        category: json['category']?.toString() ?? '',
        tags: (json['tags'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'author': author,
        'date': date.toIso8601String(),
        'likes': likes,
        'category': category,
        'tags': tags,
      };
}
