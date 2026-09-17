import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/traffic_sign.dart';
import '../models/exam_models.dart';
import '../models/learning_models.dart';
import '../models/handbook_models.dart';

/// Loads the static datasets that were ported from `data.js`, `exam-data.js`,
/// `learning-data.js` and `handbook-data.js` in the original web project.
/// Everything is bundled as JSON assets, so there is no network call needed
/// to show sign meanings, fines, exam questions, lessons or handbook posts.
class DataService {
  DataService._();
  static final DataService instance = DataService._();

  List<TrafficSign>? _signs;
  ExamBank? _examBank;
  LearningData? _learningData;
  List<HandbookPost>? _defaultPosts;
  Map<int, List<HandbookComment>>? _defaultComments;

  Future<List<TrafficSign>> loadSigns() async {
    if (_signs != null) return _signs!;
    final raw = await rootBundle.loadString('assets/data/signs.json');
    final list = jsonDecode(raw) as List<dynamic>;
    _signs = list.map((e) => TrafficSign.fromJson(e as Map<String, dynamic>)).toList();
    return _signs!;
  }

  Future<ExamBank> loadExamBank() async {
    if (_examBank != null) return _examBank!;
    final raw = await rootBundle.loadString('assets/data/exam.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    _examBank = ExamBank.fromJson(map);
    return _examBank!;
  }

  Future<LearningData> loadLearningData() async {
    if (_learningData != null) return _learningData!;
    final raw = await rootBundle.loadString('assets/data/learning.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    _learningData = LearningData.fromJson(map);
    return _learningData!;
  }

  Future<List<HandbookPost>> loadDefaultHandbookPosts() async {
    if (_defaultPosts != null) return _defaultPosts!;
    await _loadHandbookRaw();
    return _defaultPosts!;
  }

  Future<Map<int, List<HandbookComment>>> loadDefaultHandbookComments() async {
    if (_defaultComments != null) return _defaultComments!;
    await _loadHandbookRaw();
    return _defaultComments!;
  }

  Future<void> _loadHandbookRaw() async {
    final raw = await rootBundle.loadString('assets/data/handbook.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    _defaultPosts = (map['defaultPosts'] as List<dynamic>? ?? const [])
        .map((e) => HandbookPost.fromJson(e as Map<String, dynamic>))
        .toList();
    final commentsMap = map['defaultComments'] as Map<String, dynamic>? ?? const {};
    _defaultComments = commentsMap.map((key, value) => MapEntry(
          int.tryParse(key) ?? 0,
          (value as List<dynamic>)
              .map((e) => HandbookComment.fromJson(e as Map<String, dynamic>))
              .toList(),
        ));
  }

  /// Simple, dependency-free keyword search over sign name/code/keywords,
  /// mirroring the search behaviour in `app.js`.
  static List<TrafficSign> search(List<TrafficSign> all, String query) {
    final q = _normalize(query);
    if (q.isEmpty) return all;
    return all.where((s) {
      final haystack = _normalize('${s.maBien} ${s.tenBien} ${s.keywords} ${s.yNghia}');
      return haystack.contains(q);
    }).toList();
  }

  static String _normalize(String input) {
    var s = input.toLowerCase();
    const from = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const to =   'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    for (var i = 0; i < from.length; i++) {
      s = s.replaceAll(from[i], to[i]);
    }
    return s;
  }
}
