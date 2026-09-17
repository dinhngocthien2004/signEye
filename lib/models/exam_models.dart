class ExamTopic {
  final int id;
  final String name;

  ExamTopic({required this.id, required this.name});

  factory ExamTopic.fromJson(Map<String, dynamic> json) => ExamTopic(
        id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
        name: json['name']?.toString() ?? '',
      );
}

class ExamQuestion {
  final int id;
  final int topicId;
  final String question;
  final List<String> options;
  final int answer; // index of the correct option
  final String explanation;

  ExamQuestion({
    required this.id,
    required this.topicId,
    required this.question,
    required this.options,
    required this.answer,
    required this.explanation,
  });

  factory ExamQuestion.fromJson(Map<String, dynamic> json) => ExamQuestion(
        id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
        topicId:
            json['topicId'] is int ? json['topicId'] as int : int.tryParse('${json['topicId']}') ?? 0,
        question: json['question']?.toString() ?? '',
        options: (json['options'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        answer: json['answer'] is int ? json['answer'] as int : int.tryParse('${json['answer']}') ?? 0,
        explanation: json['explanation']?.toString() ?? '',
      );
}

class ExamBank {
  final List<ExamTopic> topics;
  final List<ExamQuestion> questions;

  ExamBank({required this.topics, required this.questions});

  factory ExamBank.fromJson(Map<String, dynamic> json) => ExamBank(
        topics: (json['topics'] as List<dynamic>? ?? const [])
            .map((e) => ExamTopic.fromJson(e as Map<String, dynamic>))
            .toList(),
        questions: (json['questions'] as List<dynamic>? ?? const [])
            .map((e) => ExamQuestion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Result of a finished practice/full exam attempt, kept locally so the
/// history and account screens can show progress over time.
class ExamAttempt {
  final DateTime date;
  final int total;
  final int correct;
  final String topicLabel;

  ExamAttempt({
    required this.date,
    required this.total,
    required this.correct,
    required this.topicLabel,
  });

  double get scorePercent => total == 0 ? 0 : (correct / total) * 100;
  bool get passed => scorePercent >= 90; // mirrors the real GPLX theory pass mark

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'total': total,
        'correct': correct,
        'topicLabel': topicLabel,
      };

  factory ExamAttempt.fromJson(Map<String, dynamic> json) => ExamAttempt(
        date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
        total: json['total'] is int ? json['total'] as int : int.tryParse('${json['total']}') ?? 0,
        correct:
            json['correct'] is int ? json['correct'] as int : int.tryParse('${json['correct']}') ?? 0,
        topicLabel: json['topicLabel']?.toString() ?? '',
      );
}
