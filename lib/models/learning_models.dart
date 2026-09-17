class DrivingLicense {
  final String id;
  final String name;
  final String vehicle;

  DrivingLicense({required this.id, required this.name, required this.vehicle});

  factory DrivingLicense.fromJson(Map<String, dynamic> json) => DrivingLicense(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        vehicle: json['vehicle']?.toString() ?? '',
      );
}

class ChapterPractice {
  final String question;
  final List<String> options;
  final int answer;
  final String explanation;

  ChapterPractice({
    required this.question,
    required this.options,
    required this.answer,
    required this.explanation,
  });

  factory ChapterPractice.fromJson(Map<String, dynamic>? json) {
    json ??= const {};
    return ChapterPractice(
      question: json['question']?.toString() ?? '',
      options: (json['options'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
      answer: json['answer'] is int ? json['answer'] as int : int.tryParse('${json['answer']}') ?? 0,
      explanation: json['explanation']?.toString() ?? '',
    );
  }
}

class LearningChapter {
  final String id;
  final int order;
  final String title;
  final String icon;
  final String image;
  final String summary;
  final String content;
  final String example;
  final String memoryTip;
  final ChapterPractice practice;

  LearningChapter({
    required this.id,
    required this.order,
    required this.title,
    required this.icon,
    required this.image,
    required this.summary,
    required this.content,
    required this.example,
    required this.memoryTip,
    required this.practice,
  });

  factory LearningChapter.fromJson(Map<String, dynamic> json) {
    final rawImage = json['image']?.toString() ?? '';
    final normalized = rawImage.replaceFirst('/assets/trafficSigns/', 'assets/images/');
    return LearningChapter(
      id: json['id']?.toString() ?? '',
      order: json['order'] is int ? json['order'] as int : int.tryParse('${json['order']}') ?? 0,
      title: json['title']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '📘',
      image: normalized,
      summary: json['summary']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      example: json['example']?.toString() ?? '',
      memoryTip: json['memoryTip']?.toString() ?? '',
      practice: ChapterPractice.fromJson(json['practice'] as Map<String, dynamic>?),
    );
  }
}

class LearningData {
  final List<DrivingLicense> licenses;
  final List<LearningChapter> chapters;
  final Map<String, String> licenseNotes;

  LearningData({required this.licenses, required this.chapters, required this.licenseNotes});

  factory LearningData.fromJson(Map<String, dynamic> json) => LearningData(
        licenses: (json['licenses'] as List<dynamic>? ?? const [])
            .map((e) => DrivingLicense.fromJson(e as Map<String, dynamic>))
            .toList(),
        chapters: (json['chapters'] as List<dynamic>? ?? const [])
            .map((e) => LearningChapter.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order)),
        licenseNotes: (json['licenseNotes'] as Map<String, dynamic>? ?? const {})
            .map((k, v) => MapEntry(k, v.toString())),
      );
}
