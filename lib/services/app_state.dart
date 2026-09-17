import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exam_models.dart';
import '../models/handbook_models.dart';
import 'remote_sync_service.dart';

/// One entry in the "Lịch sử" (history) tab: a sign the user looked up,
/// either via search or via the AI scan screen.
class HistoryEntry {
  final String maBien;
  final DateTime date;
  final String source; // 'scan' | 'search'

  HistoryEntry(
      {required this.maBien, required this.date, required this.source});

  Map<String, dynamic> toJson() => {
        'maBien': maBien,
        'date': date.toIso8601String(),
        'source': source,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        maBien: json['maBien']?.toString() ?? '',
        date:
            DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
        source: json['source']?.toString() ?? 'search',
      );
}

/// Central app state: authentication, Free/Pro subscription, scan quota,
/// lookup history, exam attempts and handbook posts/comments created by the
/// user. Everything is persisted locally with SharedPreferences, mirroring
/// how the original web app relied on `localStorage` for the same data
/// (see IMPLEMENTATION_NOTES.md / README.md "Giới hạn kỹ thuật cần biết").
class AppState extends ChangeNotifier {
  final RemoteSyncService _remoteSync = RemoteSyncService();

  static const _kLoggedIn = 'se_logged_in';
  static const _kUserName = 'se_user_name';
  static const _kUserEmail = 'se_user_email';
  static const _kIsPro = 'se_is_pro';
  static const _kProExpiry = 'se_pro_expiry';
  static const _kHistory = 'se_history';
  static const _kScanCount = 'se_scan_count';
  static const _kScanDate = 'se_scan_date';
  static const _kExamAttempts = 'se_exam_attempts';
  static const _kUserPosts = 'se_user_posts';
  static const _kUserComments = 'se_user_comments';
  static const _kPostLikes = 'se_post_likes';
  static const _kGeminiKey = 'se_gemini_api_key';
  static const _kThemeDark = 'se_theme_dark';

  static const int freeDailyScanLimit = 5;
  static const int freeHistoryLimit = 10;

  late SharedPreferences _prefs;
  bool _ready = false;
  bool get ready => _ready;

  bool isLoggedIn = false;
  String userName = '';
  String userEmail = '';
  bool isPro = false;
  DateTime? proExpiry;
  bool darkMode = false;

  List<HistoryEntry> history = [];
  int scanCountToday = 0;
  DateTime? lastScanDate;

  List<ExamAttempt> examAttempts = [];

  List<HandbookPost> userPosts = [];
  Map<int, List<HandbookComment>> userComments = {};
  Set<int> likedPostIds = {};

  String geminiApiKey = '';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    isLoggedIn = _prefs.getBool(_kLoggedIn) ?? false;
    userName = _prefs.getString(_kUserName) ?? '';
    userEmail = _prefs.getString(_kUserEmail) ?? '';
    isPro = _prefs.getBool(_kIsPro) ?? false;
    darkMode = _prefs.getBool(_kThemeDark) ?? false;
    final expiryRaw = _prefs.getString(_kProExpiry);
    proExpiry = expiryRaw != null ? DateTime.tryParse(expiryRaw) : null;
    if (proExpiry != null && proExpiry!.isBefore(DateTime.now())) {
      isPro = false;
      proExpiry = null;
    }
    geminiApiKey = _prefs.getString(_kGeminiKey) ?? '';

    final historyRaw = _prefs.getString(_kHistory);
    if (historyRaw != null) {
      final list = jsonDecode(historyRaw) as List<dynamic>;
      history = list
          .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    scanCountToday = _prefs.getInt(_kScanCount) ?? 0;
    final scanDateRaw = _prefs.getString(_kScanDate);
    lastScanDate = scanDateRaw != null ? DateTime.tryParse(scanDateRaw) : null;
    _resetScanCounterIfNewDay();

    final attemptsRaw = _prefs.getString(_kExamAttempts);
    if (attemptsRaw != null) {
      final list = jsonDecode(attemptsRaw) as List<dynamic>;
      examAttempts = list
          .map((e) => ExamAttempt.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final postsRaw = _prefs.getString(_kUserPosts);
    if (postsRaw != null) {
      final list = jsonDecode(postsRaw) as List<dynamic>;
      userPosts = list
          .map((e) => HandbookPost.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final commentsRaw = _prefs.getString(_kUserComments);
    if (commentsRaw != null) {
      final map = jsonDecode(commentsRaw) as Map<String, dynamic>;
      userComments = map.map((k, v) => MapEntry(
            int.tryParse(k) ?? 0,
            (v as List<dynamic>)
                .map((e) => HandbookComment.fromJson(e as Map<String, dynamic>))
                .toList(),
          ));
    }

    final likesRaw = _prefs.getStringList(_kPostLikes);
    if (likesRaw != null) {
      likedPostIds = likesRaw
          .map((e) => int.tryParse(e) ?? -1)
          .where((e) => e >= 0)
          .toSet();
    }

    _ready = true;
    notifyListeners();
  }

  void _resetScanCounterIfNewDay() {
    final now = DateTime.now();
    if (lastScanDate == null ||
        lastScanDate!.year != now.year ||
        lastScanDate!.month != now.month ||
        lastScanDate!.day != now.day) {
      scanCountToday = 0;
      lastScanDate = now;
      _prefs.setInt(_kScanCount, 0);
      _prefs.setString(_kScanDate, now.toIso8601String());
    }
  }

  // ───────────────────────── Auth ─────────────────────────

  Future<void> login({required String name, required String email}) async {
    isLoggedIn = true;
    userName = name.trim().isEmpty ? 'Người dùng' : name.trim();
    userEmail = email.trim();
    await _prefs.setBool(_kLoggedIn, true);
    await _prefs.setString(_kUserName, userName);
    await _prefs.setString(_kUserEmail, userEmail);
    try {
      await _remoteSync.saveUser(userName, userEmail);
    } catch (_) {
      // Fallback gracefully when the PostgreSQL backend is not running yet.
    }
    notifyListeners();
  }

  Future<void> logout() async {
    isLoggedIn = false;
    await _prefs.setBool(_kLoggedIn, false);
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    darkMode = value;
    await _prefs.setBool(_kThemeDark, value);
    notifyListeners();
  }

  // ───────────────────────── Subscription (demo) ─────────────────────────
  // NOTE: exactly like the original app, this is a *local, browser/device
  // side* demo flow (see README "Thanh toán"). It never charges real money
  // and must be backed by a real payment gateway + server-side subscription
  // check before being used commercially.

  Future<void> upgradeToPro({required bool yearly}) async {
    isPro = true;
    proExpiry = DateTime.now()
        .add(yearly ? const Duration(days: 365) : const Duration(days: 30));
    await _prefs.setBool(_kIsPro, true);
    await _prefs.setString(_kProExpiry, proExpiry!.toIso8601String());
    notifyListeners();
  }

  Future<void> cancelPro() async {
    isPro = false;
    proExpiry = null;
    await _prefs.setBool(_kIsPro, false);
    await _prefs.remove(_kProExpiry);
    notifyListeners();
  }

  // ───────────────────────── Scan quota ─────────────────────────

  bool get canScan => isPro || scanCountToday < freeDailyScanLimit;

  int get scansRemainingToday => isPro
      ? -1
      : (freeDailyScanLimit - scanCountToday).clamp(0, freeDailyScanLimit);

  Future<void> recordScan() async {
    _resetScanCounterIfNewDay();
    scanCountToday += 1;
    await _prefs.setInt(_kScanCount, scanCountToday);
    notifyListeners();
  }

  // ───────────────────────── History ─────────────────────────

  Future<void> addHistory(String maBien, {String source = 'search'}) async {
    history.removeWhere((h) => h.maBien == maBien);
    history.insert(
        0, HistoryEntry(maBien: maBien, date: DateTime.now(), source: source));
    if (!isPro && history.length > freeHistoryLimit) {
      history = history.sublist(0, freeHistoryLimit);
    }
    await _persistHistory();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    history = [];
    await _persistHistory();
    notifyListeners();
  }

  Future<void> _persistHistory() async {
    await _prefs.setString(
        _kHistory, jsonEncode(history.map((e) => e.toJson()).toList()));
    try {
      for (final entry in history.take(10)) {
        await _remoteSync.saveHistory(entry.maBien, source: entry.source);
      }
    } catch (_) {
      // Ignore remote sync errors so the app still works in offline/local demo mode.
    }
  }

  // ───────────────────────── Exam attempts ─────────────────────────

  Future<void> saveExamAttempt(ExamAttempt attempt) async {
    examAttempts.insert(0, attempt);
    if (examAttempts.length > 50) {
      examAttempts = examAttempts.sublist(0, 50);
    }
    await _prefs.setString(_kExamAttempts,
        jsonEncode(examAttempts.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  // ───────────────────────── Handbook (user posts/comments/likes) ────────

  Future<void> addUserPost(HandbookPost post) async {
    userPosts.insert(0, post);
    await _persistUserPosts();
    notifyListeners();
  }

  Future<void> _persistUserPosts() async {
    await _prefs.setString(
        _kUserPosts, jsonEncode(userPosts.map((e) => e.toJson()).toList()));
  }

  Future<void> addComment(int postId, HandbookComment comment) async {
    userComments.putIfAbsent(postId, () => []);
    userComments[postId]!.add(comment);
    await _persistComments();
    notifyListeners();
  }

  Future<void> _persistComments() async {
    final map = userComments.map(
        (k, v) => MapEntry(k.toString(), v.map((e) => e.toJson()).toList()));
    await _prefs.setString(_kUserComments, jsonEncode(map));
  }

  Future<void> toggleLike(int postId) async {
    if (likedPostIds.contains(postId)) {
      likedPostIds.remove(postId);
    } else {
      likedPostIds.add(postId);
    }
    final idx = userPosts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      final liked = likedPostIds.contains(postId);
      userPosts[idx] = userPosts[idx].copyWith(
        likes: userPosts[idx].likes + (liked ? 1 : -1),
      );
      await _persistUserPosts();
    }
    await _prefs.setStringList(
        _kPostLikes, likedPostIds.map((e) => e.toString()).toList());
    notifyListeners();
  }

  // ───────────────────────── Gemini API key (optional, for AI scan) ──────

  Future<void> setGeminiApiKey(String key) async {
    geminiApiKey = key.trim();
    await _prefs.setString(_kGeminiKey, geminiApiKey);
    notifyListeners();
  }
}
