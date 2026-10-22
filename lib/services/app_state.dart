import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exam_models.dart';
import '../models/handbook_models.dart';
import 'remote_sync_service.dart';
import 'sign_identify_service.dart';

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
  static const _kCoins = 'se_user_coins';
  static const _kRewardBalance = 'se_user_reward_balance';

  static String get defaultGeminiApiKey => SignIdentifyService.defaultApiKey;

  static const int freeDailyScanLimit = 5;
  static const int freeHistoryLimit = 10;

  late SharedPreferences _prefs;
  bool _ready = false;
  bool get ready => _ready;

  String authToken = '';
  bool isLoggedIn = false;
  String userName = '';
  String userEmail = '';
  bool isPro = false;
  DateTime? proExpiry;
  bool darkMode = false;

  /// Game coin balance (xu nhận được khi chơi mini game)
  int coins = 0;

  /// Số dư tiền VNĐ đổi từ xu (1.000 xu = 1.000 VNĐ) để tích hợp mua gói Pro
  int rewardBalance = 0;

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
    authToken = _prefs.getString('se_auth_token') ?? '';
    isLoggedIn = _prefs.getBool(_kLoggedIn) ?? authToken.isNotEmpty;
    if (isLoggedIn && authToken.isNotEmpty && authToken != 'offline_session') {
      try {
        const base = String.fromEnvironment('SIGN_EYE_API_URL', defaultValue: 'http://127.0.0.1:8000');
        final response = await http.get(
          Uri.parse('$base/payments/subscription'),
          headers: {'Authorization': 'Bearer $authToken'},
        ).timeout(const Duration(seconds: 2));
        if (response.statusCode == 200) {
          final subscription = jsonDecode(response.body) as Map<String, dynamic>;
          final expiry = DateTime.tryParse((subscription['expiresAt'] ?? '').toString());
          isPro = subscription['isPro'] == true && expiry != null && expiry.isAfter(DateTime.now());
          proExpiry = expiry;
        } else if (response.statusCode == 401) {
          isLoggedIn = false;
          authToken = '';
          await _prefs.remove('se_auth_token');
          await _prefs.setBool(_kLoggedIn, false);
        }
      } catch (_) {}
    }
    userName = _prefs.getString(_kUserName) ?? '';
    userEmail = _prefs.getString(_kUserEmail) ?? '';
    darkMode = _prefs.getBool(_kThemeDark) ?? false;
    coins = _prefs.getInt(_kCoins) ?? 0;
    rewardBalance = _prefs.getInt(_kRewardBalance) ?? 0;
    final expiryRaw = _prefs.getString(_kProExpiry);
    proExpiry = expiryRaw != null ? DateTime.tryParse(expiryRaw) : null;
    if (proExpiry != null && proExpiry!.isAfter(DateTime.now())) {
      isPro = true;
    } else {
      isPro = false;
      proExpiry = null;
    }

    final savedGeminiKey = _prefs.getString(_kGeminiKey);
    if (savedGeminiKey == null ||
        savedGeminiKey.trim().isEmpty ||
        (!savedGeminiKey.startsWith('AQ.') &&
            !savedGeminiKey.startsWith('AIza'))) {
      geminiApiKey = defaultGeminiApiKey;
      await _prefs.setString(_kGeminiKey, geminiApiKey);
    } else {
      geminiApiKey = savedGeminiKey.trim();
    }

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

    for (int i = 0; i < userPosts.length; i++) {
      if (userPosts[i].likes > 0 && likedPostIds.contains(userPosts[i].id)) {
        userPosts[i] = userPosts[i].copyWith(likes: 0);
      }
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

  Future<void> login({required String name, required String email, required String password, required bool register}) async {
    const base = String.fromEnvironment('SIGN_EYE_API_URL', defaultValue: 'http://127.0.0.1:8000');
    try {
      final response = await http.post(
        Uri.parse('$base/auth/${register ? 'register' : 'login'}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) {
        throw StateError(register ? 'Không đăng ký được, email có thể đã tồn tại' : 'Email hoặc mật khẩu không đúng');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      authToken = (data['token'] ?? '').toString();
      await _prefs.setString('se_auth_token', authToken);
    } on StateError {
      rethrow;
    } catch (_) {
      // Khi backend chưa chạy, cho phép đăng nhập offline để trải nghiệm ứng dụng
      authToken = 'offline_session';
      await _prefs.setString('se_auth_token', authToken);
    }
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
    final token = authToken;
    authToken = '';
    await _prefs.remove('se_auth_token');
    isPro = false;
    proExpiry = null;
    isLoggedIn = false;
    await _prefs.setBool(_kLoggedIn, false);
    if (token.isNotEmpty && token != 'offline_session') {
      try {
        const base = String.fromEnvironment('SIGN_EYE_API_URL', defaultValue: 'http://127.0.0.1:8000');
        await http.post(Uri.parse('$base/auth/logout'), headers: {'Authorization': 'Bearer $token'});
      } catch (_) {}
    }
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

  /// Quyền Pro chỉ được cấp sau khi backend xác nhận thanh toán.
  Future<void> upgradeToPro({required bool yearly}) async {
    throw StateError('Chỉ Admin có thể xác nhận thanh toán và kích hoạt Pro.');
  }

  /// Cập nhật quyền Pro theo thời hạn do backend trả về, không tự cộng ngày ở máy khách.
  Future<void> syncProFromServer(Map<String, dynamic> subscription) async {
    final expires = DateTime.tryParse((subscription['expiresAt'] ?? '').toString());
    proExpiry = expires;
    isPro = subscription['isPro'] == true && expires != null && expires.isAfter(DateTime.now());
    await _prefs.setBool(_kIsPro, isPro);
    if (expires == null) {
      await _prefs.remove(_kProExpiry);
    } else {
      await _prefs.setString(_kProExpiry, expires.toIso8601String());
    }
    notifyListeners();
  }

  /// Áp dụng thời hạn Pro được xác nhận từ máy chủ hoặc đơn thanh toán
  Future<void> applyApprovedPro(DateTime expiry) async {
    proExpiry = expiry;
    isPro = expiry.isAfter(DateTime.now());
    await _prefs.setBool(_kIsPro, isPro);
    await _prefs.setString(_kProExpiry, expiry.toIso8601String());
    notifyListeners();
  }

  Future<void> cancelPro() async {
    isPro = false;
    proExpiry = null;
    await _prefs.setBool(_kIsPro, false);
    await _prefs.remove(_kProExpiry);
    notifyListeners();
  }

  // ───────────────────────── Game Coins & Pro Redemption ─────────────────────────

  /// Cộng xu khi trả lời đúng trong minigame (mặc định +5 xu)
  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    coins += amount;
    await _prefs.setInt(_kCoins, coins);
    notifyListeners();
  }

  /// Đổi xu sang tiền VNĐ (1.000 xu = 1.000 VNĐ) để tích hợp mua gói Pro
  Future<bool> exchangeCoinsToCash({int coinsToExchange = 1000}) async {
    if (coins < coinsToExchange || coinsToExchange < 1000) return false;
    final validAmount = (coinsToExchange ~/ 1000) * 1000;
    if (validAmount <= 0 || coins < validAmount) return false;

    coins -= validAmount;
    rewardBalance += validAmount;
    await _prefs.setInt(_kCoins, coins);
    await _prefs.setInt(_kRewardBalance, rewardBalance);
    notifyListeners();
    return true;
  }

  /// Dùng số dư VNĐ thưởng để mua gói Pro
  Future<bool> buyProWithRewardBalance({required int days, required int costVnd}) async {
    if (rewardBalance < costVnd) return false;
    rewardBalance -= costVnd;
    isPro = true;
    final base = (proExpiry != null && proExpiry!.isAfter(DateTime.now()))
        ? proExpiry!
        : DateTime.now();
    proExpiry = base.add(Duration(days: days));
    await _prefs.setInt(_kRewardBalance, rewardBalance);
    await _prefs.setBool(_kIsPro, true);
    await _prefs.setString(_kProExpiry, proExpiry!.toIso8601String());
    notifyListeners();
    return true;
  }

  /// Dùng xu trực tiếp để đổi gói Pro
  Future<bool> buyProWithCoins({required int days, required int costCoins}) async {
    if (coins < costCoins) return false;
    coins -= costCoins;
    isPro = true;
    final base = (proExpiry != null && proExpiry!.isAfter(DateTime.now()))
        ? proExpiry!
        : DateTime.now();
    proExpiry = base.add(Duration(days: days));
    await _prefs.setInt(_kCoins, coins);
    await _prefs.setBool(_kIsPro, true);
    await _prefs.setString(_kProExpiry, proExpiry!.toIso8601String());
    notifyListeners();
    return true;
  }

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

  bool isPostLiked(int postId) => likedPostIds.contains(postId);

  int getPostLikes(HandbookPost post) {
    return post.likes + (likedPostIds.contains(post.id) ? 1 : 0);
  }

  Future<void> toggleLike(int postId) async {
    if (likedPostIds.contains(postId)) {
      likedPostIds.remove(postId);
    } else {
      likedPostIds.add(postId);
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
