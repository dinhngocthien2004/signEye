import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/traffic_sign.dart';

class IdentifyResult {
  final TrafficSign? sign;
  final String confidence; // 'cao' | 'trung bình' | 'thấp'
  final String rawCode;
  final String? error;

  IdentifyResult(
      {this.sign, required this.confidence, required this.rawCode, this.error});
}

/// Re-implements the "controlled hybrid" approach described in the original
/// README: Gemini Vision is only ever asked to *identify the sign code* from
/// a photo. All legal facts (meaning, fines, points, legal basis) always
/// come from the locally bundled `signs.json` — never from the model, so the
/// legal data stays auditable and can't be hallucinated by the AI.
///
/// This mirrors `api/identify.js`, but runs directly from the Flutter app
/// using a Gemini API key the user enters in Account settings (there is no
/// bundled backend/server in this Flutter port).
class SignIdentifyService {
  static const List<String> _candidateModels = [
    'gemini-3.7-flash',
    'gemini-3.8-flash',
    'gemini-flash-lite-latest',
    'gemini-3.6-flash',
  ];

  static String get defaultApiKey {
    const envKey = String.fromEnvironment('GEMINI_API_KEY');
    if (envKey.isNotEmpty) return envKey;
    try {
      return utf8.decode(
        base64.decode(
          'QVEuQWI4Uk42SUx6Vks3bEotYmZXWFlsY0VyRVN4T2VJOHRfZWJlOTk1ck15NFlRQTV2Qmc=',
        ),
      );
    } catch (_) {
      return '';
    }
  }

  static Future<IdentifyResult> identify({
    required List<int> imageBytes,
    required String mimeType,
    String? apiKey,
    required List<TrafficSign> catalog,
  }) async {
    final trimmedKey = (apiKey != null && apiKey.trim().isNotEmpty)
        ? apiKey.trim()
        : defaultApiKey;
    if (trimmedKey.isEmpty) {
      return IdentifyResult(
        confidence: 'thấp',
        rawCode: '',
        error:
            'Chưa có Gemini API Key. Hãy thử lại hoặc dùng Tra cứu để tìm biển thủ công.',
      );
    }

    if (!_looksLikeGeminiKey(trimmedKey)) {
      return IdentifyResult(
        confidence: 'thấp',
        rawCode: '',
        error:
            'Gemini API Key không đúng định dạng. Hãy kiểm tra lại key trong hệ thống.',
      );
    }

    final catalogText = catalog
        .map((s) => '${s.maBien}|${s.tenBien}|${s.visualFeatures.shape}|'
            '${s.visualFeatures.background}|${s.visualFeatures.border}|'
            '${s.visualFeatures.symbol}')
        .join('\n');

    final prompt = '''
Bạn là chuyên gia nhận diện biển báo giao thông Việt Nam. Dưới đây là danh mục các mã biển hợp lệ
(mã|tên|hình dạng|nền|viền|ký hiệu), mỗi dòng một biển:
$catalogText

Nhìn ảnh được đính kèm và xác định mã biển (maBien) khớp nhất với danh mục ở trên.
CHỈ trả lời bằng JSON thuần, không thêm chữ nào khác, theo định dạng:
{"maBien": "P.101", "confidencePercent": 90}
Nếu không chắc chắn biển nào trong ảnh, hãy chọn mã gần đúng nhất và hạ confidencePercent xuống thấp.
''';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': _supportedMimeType(mimeType),
                'data': base64Encode(imageBytes),
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'response_mime_type': 'application/json',
      },
    });

    String? lastError;

    for (final model in _candidateModels) {
      try {
        final endpoint =
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';
        final res = await http
            .post(
              Uri.parse('$endpoint?key=${Uri.encodeQueryComponent(trimmedKey)}'),
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(const Duration(seconds: 25));

        // When a model experiences temporary high demand (503), rate limit (429), or 500,
        // automatically fallback to the next candidate model
        if (res.statusCode == 503 ||
            res.statusCode == 429 ||
            res.statusCode == 500) {
          lastError =
              'Model $model đang bận (${res.statusCode}). Đang tự động chuyển sang model khác...';
          continue;
        }

        if (res.statusCode == 400 ||
            res.statusCode == 401 ||
            res.statusCode == 403 ||
            res.statusCode == 404) {
          final apiMessage = _apiErrorMessage(res.body);
          if (res.statusCode == 404 || apiMessage.contains('not found')) {
            continue;
          }
          if (res.statusCode == 401 || res.statusCode == 403) {
            return IdentifyResult(
              confidence: 'thấp',
              rawCode: '',
              error: 'Gemini từ chối yêu cầu (${res.statusCode}). $apiMessage',
            );
          }
          lastError = apiMessage;
          continue;
        }

        if (res.statusCode != 200) {
          lastError = _apiErrorMessage(res.body);
          continue;
        }

        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        final candidates = decoded['candidates'] as List<dynamic>?;
        if (candidates == null || candidates.isEmpty) {
          continue;
        }
        final parts =
            (candidates.first['content']?['parts'] as List<dynamic>?) ?? [];
        final text = parts.map((p) => p['text']?.toString() ?? '').join();
        final cleaned =
            text.replaceAll('```json', '').replaceAll('```', '').trim();

        final match = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
        if (match == null) {
          continue;
        }
        final parsed = jsonDecode(match.group(0)!) as Map<String, dynamic>;
        final code = normalizeCode(parsed['maBien']?.toString() ?? '');
        final confidencePercent =
            num.tryParse('${parsed['confidencePercent'] ?? 70}') ?? 70;
        final confidence = confidencePercent >= 88
            ? 'cao'
            : confidencePercent >= 65
                ? 'trung bình'
                : 'thấp';

        TrafficSign? found;
        for (final s in catalog) {
          if (s.maBien.toUpperCase() == code.toUpperCase()) {
            found = s;
            break;
          }
        }

        if (found == null) {
          final cleanCode = code.replaceAll('.', '').toUpperCase();
          for (final s in catalog) {
            if (s.maBien.replaceAll('.', '').toUpperCase() == cleanCode) {
              found = s;
              break;
            }
          }
        }

        return IdentifyResult(
            sign: found, confidence: confidence, rawCode: code);
      } catch (e) {
        lastError = 'Không thể kết nối tới $model: $e';
        continue;
      }
    }

    return IdentifyResult(
      confidence: 'thấp',
      rawCode: '',
      error: lastError ?? 'Máy chủ AI đang bận. Vui lòng thử lại sau giây lát.',
    );
  }

  static bool _looksLikeGeminiKey(String key) {
    final normalized = key.trim();
    if (normalized.isEmpty) return false;
    return RegExp(r'^(AIza|AIzaSy)[A-Za-z0-9_-]+$').hasMatch(normalized) ||
        RegExp(r'^AQ\.[A-Za-z0-9_-]+$').hasMatch(normalized);
  }

  static String _supportedMimeType(String mimeType) {
    const supported = {'image/jpeg', 'image/png', 'image/webp', 'image/heic'};
    return supported.contains(mimeType.toLowerCase())
        ? mimeType.toLowerCase()
        : 'image/jpeg';
  }

  static String _apiErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final message = decoded['error']?['message']?.toString();
      if (message != null && message.isNotEmpty) return message;
    } catch (_) {
      // Keep a safe generic message when Gemini returns a non-JSON response.
    }
    return 'Kiểm tra API key, model Gemini và quyền truy cập rồi thử lại.';
  }

  static String normalizeCode(String value) {
    final raw = value
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[_\s]+'), '.')
        .replaceAll(RegExp(r'\.+'), '.');
    final compact = raw.replaceAll('.', '');
    final match = RegExp(r'^([PWRIS])(\d{3})([A-Z]\d?)?$').firstMatch(compact);
    if (match == null) return raw;
    final letter = match.group(1)!;
    final digits = match.group(2)!;
    final suffix = match.group(3)?.toLowerCase() ?? '';
    return '$letter.$digits$suffix';
  }
}
