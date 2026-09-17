import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/traffic_sign.dart';

class IdentifyResult {
  final TrafficSign? sign;
  final String confidence; // 'cao' | 'trung bình' | 'thấp'
  final String rawCode;
  final String? error;

  IdentifyResult({this.sign, required this.confidence, required this.rawCode, this.error});
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
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  static Future<IdentifyResult> identify({
    required List<int> imageBytes,
    required String apiKey,
    required List<TrafficSign> catalog,
  }) async {
    if (apiKey.trim().isEmpty) {
      return IdentifyResult(
        confidence: 'thấp',
        rawCode: '',
        error:
            'Chưa có Gemini API Key. Vào Tài khoản → Cài đặt AI để nhập khóa, hoặc dùng Tra cứu để tìm biển thủ công.',
      );
    }

    final catalogText = catalog
        .map((s) => '${s.maBien}|${s.tenBien}|${s.visualFeatures.shape}|'
            '${s.visualFeatures.background}|${s.visualFeatures.border}|'
            '${s.visualFeatures.symbol}')
        .join('\n');

    final prompt = '''
Bạn là bộ nhận diện biển báo giao thông Việt Nam. Dưới đây là danh mục các mã biển hợp lệ
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
                'mime_type': 'image/jpeg',
                'data': base64Encode(imageBytes),
              }
            }
          ]
        }
      ],
      'generationConfig': {'temperature': 0.1},
    });

    try {
      final res = await http
          .post(
            Uri.parse('$_endpoint?key=$apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        return IdentifyResult(
          confidence: 'thấp',
          rawCode: '',
          error: 'Lỗi máy chủ Gemini (${res.statusCode}). Vui lòng thử lại.',
        );
      }

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final candidates = decoded['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        return IdentifyResult(confidence: 'thấp', rawCode: '', error: 'Không nhận được phản hồi từ AI.');
      }
      final parts = (candidates.first['content']?['parts'] as List<dynamic>?) ?? [];
      final text = parts.map((p) => p['text']?.toString() ?? '').join();
      final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();

      final match = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
      if (match == null) {
        return IdentifyResult(confidence: 'thấp', rawCode: '', error: 'Không đọc được kết quả AI.');
      }
      final parsed = jsonDecode(match.group(0)!) as Map<String, dynamic>;
      final code = normalizeCode(parsed['maBien']?.toString() ?? '');
      final confidencePercent = num.tryParse('${parsed['confidencePercent'] ?? 70}') ?? 70;
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

      return IdentifyResult(sign: found, confidence: confidence, rawCode: code);
    } catch (e) {
      return IdentifyResult(
        confidence: 'thấp',
        rawCode: '',
        error: 'Không thể kết nối tới Gemini: $e',
      );
    }
  }

  static String normalizeCode(String value) {
    final raw = value.trim().toUpperCase().replaceAll(RegExp(r'[_\s]+'), '.').replaceAll(RegExp(r'\.+'), '.');
    final compact = raw.replaceAll('.', '');
    final match = RegExp(r'^([PWRIS])(\d{3})([A-Z]\d?)?$').firstMatch(compact);
    if (match == null) return raw;
    final letter = match.group(1)!;
    final digits = match.group(2)!;
    final suffix = match.group(3)?.toLowerCase() ?? '';
    return '$letter.$digits$suffix';
  }
}
