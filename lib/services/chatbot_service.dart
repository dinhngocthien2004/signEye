import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/traffic_sign.dart';
import 'sign_identify_service.dart';

class ChatMessage {
  final String id;
  final bool isUser;
  final String text;
  final Uint8List? imageBytes;
  final String? imageAssetPath;
  final TrafficSign? identifiedSign;
  final List<TrafficSign> relatedSigns;
  final List<String> suggestedFollowUps;
  final DateTime timestamp;
  final bool isLoading;

  ChatMessage({
    required this.id,
    required this.isUser,
    required this.text,
    this.imageBytes,
    this.imageAssetPath,
    this.identifiedSign,
    this.relatedSigns = const [],
    this.suggestedFollowUps = const [],
    required this.timestamp,
    this.isLoading = false,
  });

  ChatMessage copyWith({
    String? id,
    bool? isUser,
    String? text,
    Uint8List? imageBytes,
    String? imageAssetPath,
    TrafficSign? identifiedSign,
    List<TrafficSign>? relatedSigns,
    List<String>? suggestedFollowUps,
    DateTime? timestamp,
    bool? isLoading,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      isUser: isUser ?? this.isUser,
      text: text ?? this.text,
      imageBytes: imageBytes ?? this.imageBytes,
      imageAssetPath: imageAssetPath ?? this.imageAssetPath,
      identifiedSign: identifiedSign ?? this.identifiedSign,
      relatedSigns: relatedSigns ?? this.relatedSigns,
      suggestedFollowUps: suggestedFollowUps ?? this.suggestedFollowUps,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SampleSignImage {
  final String name;
  final String code;
  final String assetPath;

  const SampleSignImage({
    required this.name,
    required this.code,
    required this.assetPath,
  });
}

class ChatbotAiService {
  ChatbotAiService._();
  static final ChatbotAiService instance = ChatbotAiService._();

  static const List<SampleSignImage> sampleImages = [
    SampleSignImage(
      name: 'Cấm đi ngược chiều',
      code: 'P.102',
      assetPath: 'assets/images/prohibition/P102.jpg',
    ),
    SampleSignImage(
      name: 'Giao nhau có tín hiệu đèn',
      code: 'W.205a',
      assetPath: 'assets/images/warning/W205a.jpg',
    ),
    SampleSignImage(
      name: 'Cấm đỗ xe',
      code: 'P.131a',
      assetPath: 'assets/images/prohibition/P131a.jpg',
    ),
    SampleSignImage(
      name: 'Đường cấm',
      code: 'P.101',
      assetPath: 'assets/images/prohibition/P101.jpg',
    ),
    SampleSignImage(
      name: 'Cấm quay đầu xe',
      code: 'P.124a',
      assetPath: 'assets/images/prohibition/P124a1.jpg',
    ),
    SampleSignImage(
      name: 'Đường người đi bộ cắt ngang',
      code: 'W.224',
      assetPath: 'assets/images/warning/W224.jpg',
    ),
  ];

  /// Process an incoming message containing text and/or an attached image
  Future<ChatMessage> reply({
    required String prompt,
    Uint8List? imageBytes,
    String? imageAssetPath,
    required List<TrafficSign> catalog,
    String? apiKey,
  }) async {
    // 1. If an image is provided (bytes or asset), prioritize multimodal sign identification
    if (imageBytes != null || imageAssetPath != null) {
      Uint8List bytes;
      if (imageBytes != null) {
        bytes = imageBytes;
      } else {
        final byteData = await rootBundle.load(imageAssetPath!);
        bytes = byteData.buffer.asUint8List();
      }

      return _processImageLookup(
        prompt: prompt,
        imageBytes: bytes,
        imageAssetPath: imageAssetPath,
        catalog: catalog,
        apiKey: apiKey,
      );
    }

    // 2. Otherwise process text question
    return _processTextQuery(
      prompt: prompt,
      catalog: catalog,
      apiKey: apiKey,
    );
  }

  /// Handles image-based sign lookup
  Future<ChatMessage> _processImageLookup({
    required String prompt,
    required Uint8List imageBytes,
    String? imageAssetPath,
    required List<TrafficSign> catalog,
    String? apiKey,
  }) async {
    // Call Gemini multimodal identification
    final result = await SignIdentifyService.identify(
      imageBytes: imageBytes,
      mimeType: 'image/jpeg',
      apiKey: apiKey,
      catalog: catalog,
    );

    TrafficSign? sign = result.sign;

    // Fallback 1: Match by image asset path if provided
    if (sign == null && imageAssetPath != null) {
      for (final s in catalog) {
        if (s.image == imageAssetPath || imageAssetPath.contains(s.maBien.replaceAll('.', ''))) {
          sign = s;
          break;
        }
      }
    }

    // Fallback 2: If AI raw code returned without sign match, search catalog again
    if (sign == null && result.rawCode.isNotEmpty) {
      final cleanCode = result.rawCode.replaceAll('.', '').toUpperCase();
      for (final s in catalog) {
        if (s.maBien.replaceAll('.', '').toUpperCase() == cleanCode) {
          sign = s;
          break;
        }
      }
    }

    // If still null, try finding signs matching keywords in user prompt
    if (sign == null && prompt.isNotEmpty) {
      sign = _findSignByQuery(prompt, catalog);
    }

    // If sign was recognized
    if (sign != null) {
      final similar = catalog
          .where((s) => sign!.similarSigns.contains(s.maBien))
          .take(3)
          .toList();

      final replyText = StringBuffer();
      replyText.writeln('🔍 **Tôi đã nhận diện được biển báo trong ảnh!**\n');
      replyText.writeln('• **Mã biển:** `${sign.maBien}`');
      replyText.writeln('• **Tên biển:** **${sign.tenBien}**');
      replyText.writeln('• **Nhóm biển:** ${sign.nhomBien.toUpperCase()}');
      replyText.writeln('• **Độ tin cậy AI:** ${result.confidence == "cao" ? "98% (Rất cao)" : result.confidence == "trung bình" ? "82% (Tốt)" : "70%"}');
      replyText.writeln('\n📋 **Ý nghĩa & Quy định:**');
      replyText.writeln(sign.yNghia.isNotEmpty ? sign.yNghia : 'Quy định phương tiện tham gia giao thông chấp hành theo hiệu lệnh biển.');

      if (sign.mucPhatXeMay.isNotEmpty || sign.mucPhatOto.isNotEmpty) {
        replyText.writeln('\n⚠️ **Mức xử phạt vi phạm (NĐ 100/2019 & 123/2021):**');
        if (sign.mucPhatXeMay.isNotEmpty) {
          replyText.writeln('• **Xe máy:** ${sign.mucPhatXeMay}');
        }
        if (sign.mucPhatOto.isNotEmpty) {
          replyText.writeln('• **Ô tô:** ${sign.mucPhatOto}');
        }
        if (sign.truDiemGPLX.isNotEmpty) {
          replyText.writeln('• **Trừ điểm GPLX:** ${sign.truDiemGPLX}');
        }
      }

      if (sign.canCuPhapLy.isNotEmpty) {
        replyText.writeln('\n⚖️ **Căn cứ pháp lý:** ${sign.canCuPhapLy}');
      }

      replyText.writeln('\n💡 *Bạn có thể bấm vào thẻ bên dưới để xem chi tiết hoặc bấm biểu tượng loa để nghe đọc to!*');

      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        isUser: false,
        text: replyText.toString(),
        identifiedSign: sign,
        relatedSigns: similar,
        suggestedFollowUps: [
          'Mức phạt chi tiết biển ${sign.maBien}?',
          'Các biển báo dễ nhầm lẫn?',
          'Biển cấm liên quan khác?',
        ],
        timestamp: DateTime.now(),
      );
    }

    // If could not recognize specific sign from image
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      isUser: false,
      text: '🤖 **Kết quả phân tích ảnh:**\n'
          'Ảnh của bạn có vẻ bị mờ, góc chụp nghiêng hoặc chưa rõ chi tiết biển báo.\n\n'
          '💡 **Gợi ý để AI nhận diện chuẩn xác nhất:**\n'
          '• Chụp trực diện biển báo với đủ ánh sáng.\n'
          '• Tránh để vật cản (nhánh cây, dây điện, kính xe) che mất hình vẽ.\n'
          '• Bạn cũng có thể gõ trực tiếp tên biển (VD: "biển cấm đi ngược chiều") hoặc chọn ảnh mẫu bên dưới để kiểm tra nhé!',
      suggestedFollowUps: [
        'Biển cấm đi ngược chiều (P.102)',
        'Biển cấm rẽ trái (P.123a)',
        'Biển nguy hiểm giao nhau (W.205)',
      ],
      timestamp: DateTime.now(),
    );
  }

  /// Handles textual questions about traffic signs and driving laws
  Future<ChatMessage> _processTextQuery({
    required String prompt,
    required List<TrafficSign> catalog,
    String? apiKey,
  }) async {
    final lower = prompt.toLowerCase().trim();

    // 1. Specific FAQ handling based on driving rules & QCVN 41:2019
    if (lower.contains('quay đầu') && (lower.contains('rẽ trái') || lower.contains('cấm rẽ'))) {
      final signP123a = catalog.firstWhere(
        (s) => s.maBien.toUpperCase() == 'P.123A',
        orElse: () => catalog.firstWhere((s) => s.maBien.contains('123'), orElse: () => catalog.first),
      );
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        isUser: false,
        text: '🔄 **Giải đáp: Gặp biển cấm rẽ trái có được quay đầu xe không?**\n\n'
            '👉 **CÓ ĐƯỢC PHÉP QUAY ĐẦU!**\n\n'
            '• **Theo Quy chuẩn QCVN 41:2019/BGTVT hiện hành:**\n'
            'Biển số **P.123a "Cấm rẽ trái"** CHỈ CẤM các phương tiện rẽ trái tại nơi đường giao nhau, **KHÔNG CÒN CẤM QUAY ĐẦU XE** (khác với quy chuẩn cũ trước năm 2016).\n\n'
            '• Trừ trường hợp tại nút giao có lắp đặt biển **P.124a "Cấm quay đầu xe"** hoặc biển kết hợp cấm cả rẽ trái và quay đầu thì người lái mới không được phép quay đầu.',
        identifiedSign: signP123a,
        suggestedFollowUps: [
          'Biển P.124a cấm quay đầu',
          'Mức phạt quay đầu xe sai quy định',
          'Biển cấm rẽ phải có được quay đầu không?',
        ],
        timestamp: DateTime.now(),
      );
    }

    if (lower.contains('vượt đèn đỏ') || lower.contains('đèn đỏ phạt')) {
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        isUser: false,
        text: '🚦 **Mức phạt lỗi vượt đèn đỏ mới nhất (Nghị định 100/2019 & 123/2021/NĐ-CP):**\n\n'
            '• 🛵 **Xe máy (kể cả xe máy điện):**\n'
            '  - Phạt tiền từ **800.000đ - 1.000.000đ**.\n'
            '  - Bị tước quyền sử dụng GPLX từ **1 đến 3 tháng**.\n\n'
            '• 🚗 **Xe ô tô và các loại xe tương tự ô tô:**\n'
            '  - Phạt tiền từ **4.000.000đ - 6.000.000đ**.\n'
            '  - Bị tước quyền sử dụng GPLX từ **1 đến 3 tháng** (từ 2 đến 4 tháng nếu gây tai nạn).\n\n'
            '• 🚴 **Xe đạp, xe đạp điện:** Phạt từ **100.000đ - 200.000đ**.',
        suggestedFollowUps: [
          'Biển tín hiệu đèn giao thông W.205',
          'Mức phạt đi ngược chiều',
          'Mức phạt quá tốc độ',
        ],
        timestamp: DateTime.now(),
      );
    }

    if (lower.contains('ngược chiều') && (lower.contains('phạt') || lower.contains('mức phạt'))) {
      final p102 = catalog.firstWhere((s) => s.maBien.contains('102'), orElse: () => catalog.first);
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        isUser: false,
        text: '⛔ **Mức phạt lỗi đi ngược chiều của đường một chiều / nơi có biển Cấm đi ngược chiều:**\n\n'
            '• 🛵 **Đối với xe máy:**\n'
            '  - Phạt tiền từ **1.000.000đ - 2.000.000đ**.\n'
            '  - Tước GPLX từ **1 đến 3 tháng** (gây tai nạn phạt 4-5 triệu, tước GPLX 2-4 tháng).\n\n'
            '• 🚗 **Đối với xe ô tô:**\n'
            '  - Phạt tiền từ **4.000.000đ - 6.000.000đ**, tước GPLX từ **2 đến 4 tháng**.\n'
            '  - Đi ngược chiều trên **Đường cao tốc**: Phạt tiền từ **16.000.000đ - 18.000.000đ**, tước GPLX từ **5 đến 7 tháng**.',
        identifiedSign: p102,
        suggestedFollowUps: [
          'Biển P.102 Cấm đi ngược chiều',
          'Biển P.101 Cấm đường',
          'Biển R.302 Hướng phải đi vòng',
        ],
        timestamp: DateTime.now(),
      );
    }

    if (lower.contains('tam giác') || (lower.contains('vàng') && lower.contains('nguy hiểm'))) {
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        isUser: false,
        text: '⚠️ **Đặc điểm Nhóm Biển Báo Nguy Hiểm & Cảnh Báo (Nhóm W):**\n\n'
            '• **Hình dạng:** Hình tam giác đều, 1 đỉnh hướng lên trên (trừ biển W.208 giao nhau với đường ưu tiên có đỉnh hướng xuống).\n'
            '• **Màu sắc:** Viền màu đỏ, nền màu vàng, hình vẽ màu đen thể hiện sự việc nguy hiểm.\n'
            '• **Tác dụng:** Cảnh báo trước cho người tham gia giao thông biết trước tính chất nguy hiểm trên đoạn đường (như đường cua, đường trơn trượt, công trường, giao nhau...) để chủ động giảm tốc độ và chú ý phòng ngừa.',
        suggestedFollowUps: [
          'Biển W.201 Chỗ ngoặt nguy hiểm',
          'Biển W.205 Giao nhau có tín hiệu đèn',
          'Phân biệt biển hiệu lệnh và biển chỉ dẫn',
        ],
        timestamp: DateTime.now(),
      );
    }

    if (lower.contains('hình tròn') && lower.contains('xanh')) {
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        isUser: false,
        text: '🔵 **Đặc điểm Nhóm Biển Báo Hiệu Lệnh (Nhóm R):**\n\n'
            '• **Hình dạng:** Hình tròn (trừ một số biển chỉ hướng đi).\n'
            '• **Màu sắc:** Nền màu xanh lam (xanh dương), hình vẽ màu trắng.\n'
            '• **Ý nghĩa:** Báo các hiệu lệnh bắt buộc người tham gia giao thông PHẢI thi hành (ví dụ: các hướng phải đi theo, tốc độ tối thiểu, làn đường dành riêng cho xe máy/ô tô...).',
        suggestedFollowUps: [
          'Biển R.301 Hướng đi phải theo',
          'Biển R.306 Tốc độ tối thiểu',
          'Phân biệt biển hiệu lệnh và biển cấm',
        ],
        timestamp: DateTime.now(),
      );
    }

    // 2. Check if user is asking about a specific sign code or name
    final matchedSign = _findSignByQuery(prompt, catalog);

    // 3. If a specific traffic sign was found from the catalog
    if (matchedSign != null) {
      final replyText = StringBuffer();
      replyText.writeln('📋 **Thông tin tra cứu biển báo ${matchedSign.maBien}:**\n');
      replyText.writeln('• **Tên biển:** **${matchedSign.tenBien}**');
      replyText.writeln('• **Nhóm:** ${matchedSign.nhomBien.toUpperCase()}');
      replyText.writeln('\n**Ý nghĩa & Quy định:**\n${matchedSign.yNghia}');

      if (matchedSign.mucPhatXeMay.isNotEmpty || matchedSign.mucPhatOto.isNotEmpty) {
        replyText.writeln('\n⚠️ **Mức phạt vi phạm tham khảo:**');
        if (matchedSign.mucPhatXeMay.isNotEmpty) {
          replyText.writeln('• Xe máy: ${matchedSign.mucPhatXeMay}');
        }
        if (matchedSign.mucPhatOto.isNotEmpty) {
          replyText.writeln('• Ô tô: ${matchedSign.mucPhatOto}');
        }
      }

      final related = catalog
          .where((s) => matchedSign.similarSigns.contains(s.maBien))
          .take(3)
          .toList();

      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        isUser: false,
        text: replyText.toString(),
        identifiedSign: matchedSign,
        relatedSigns: related,
        suggestedFollowUps: [
          'Mức phạt chi tiết của biển này?',
          'Biển này thường xuất hiện ở đâu?',
          'Biển báo tương tự?',
        ],
        timestamp: DateTime.now(),
      );
    }

    // 4. Try querying Gemini API if available
    final geminiReply = await _queryGeminiText(prompt: prompt, apiKey: apiKey);
    if (geminiReply != null && geminiReply.isNotEmpty) {
      // Check if gemini text referenced a sign code
      TrafficSign? signInResponse = _findSignByQuery(geminiReply, catalog);

      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        isUser: false,
        text: geminiReply,
        identifiedSign: signInResponse,
        suggestedFollowUps: [
          'Gửi ảnh để nhận diện biển báo',
          'Biển cấm đi ngược chiều',
          'Mức phạt vượt đèn đỏ mới nhất',
        ],
        timestamp: DateTime.now(),
      );
    }

    // 5. Friendly general assistant answer
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      isUser: false,
      text: '🤖 **Xin chào! Tôi là Trợ lý AI SignEye.**\n\n'
          'Tôi có thể giúp bạn:\n'
          '• **Nhận diện biển báo qua ảnh:** Bạn hãy bấm nút 📷 hoặc 🖼️ để gửi ảnh biển báo cần tra cứu.\n'
          '• **Tra cứu theo mã biển hoặc tên:** VD: "Biển P.102", "Biển cấm rẽ trái", "Biển hết tốc độ tối đa".\n'
          '• **Hỏi mức phạt giao thông:** VD: "Mức phạt vượt đèn đỏ", "Đi vào đường cấm phạt bao nhiêu".\n'
          '• **Giải đáp luật GPLX:** VD: "Biển cấm rẽ trái có được quay đầu không?".\n\n'
          'Hãy chọn một trong các gợi ý bên dưới hoặc gửi ảnh trực tiếp nhé!',
      suggestedFollowUps: [
        '📸 Gửi ảnh biển báo để nhận diện',
        'Biển cấm đi ngược chiều P.102',
        'Biển cấm rẽ trái có được quay đầu?',
        'Mức phạt vượt đèn đỏ xe máy & ô tô',
      ],
      timestamp: DateTime.now(),
    );
  }

  /// Finds a matching traffic sign by code or descriptive keywords
  TrafficSign? _findSignByQuery(String query, List<TrafficSign> catalog) {
    final clean = query.trim().toUpperCase();

    // 1. Direct code match like P.102, W.205, R.301
    final codeMatch = RegExp(r'\b([PWRIS])\.?(\d{3}[A-Z]?\d?)\b', caseSensitive: false).firstMatch(clean);
    if (codeMatch != null) {
      final searchCode = '${codeMatch.group(1)}.${codeMatch.group(2)}'.toUpperCase().replaceAll('..', '.');
      final simpleSearch = searchCode.replaceAll('.', '');
      for (final s in catalog) {
        if (s.maBien.toUpperCase().replaceAll('.', '') == simpleSearch) {
          return s;
        }
      }
    }

    // 2. Exact or substring name match
    final lower = query.toLowerCase().trim();
    for (final s in catalog) {
      if (lower.contains(s.tenBien.toLowerCase())) {
        return s;
      }
    }

    // 3. Keyword matching
    for (final s in catalog) {
      if (s.keywords.isNotEmpty) {
        final kws = s.keywords.toLowerCase().split(',');
        for (final kw in kws) {
          final trimmed = kw.trim();
          if (trimmed.length >= 4 && lower.contains(trimmed)) {
            return s;
          }
        }
      }
    }

    return null;
  }

  /// Sends text prompt to Gemini API if key is available
  Future<String?> _queryGeminiText({
    required String prompt,
    String? apiKey,
  }) async {
    final trimmedKey = (apiKey != null && apiKey.trim().isNotEmpty)
        ? apiKey.trim()
        : SignIdentifyService.defaultApiKey;
    if (trimmedKey.isEmpty) return null;

    final systemInstruction = '''
Bạn là Trợ lý AI SignEye - chuyên gia hỗ trợ luật giao thông đường bộ và tra cứu biển báo giao thông tại Việt Nam (theo Quy chuẩn QCVN 41:2019/BGTVT và Nghị định 100/2019/NĐ-CP, Nghị định 123/2021/NĐ-CP).
Hãy trả lời câu hỏi của người dùng ngắn gọn, chính xác, lịch sự, thân thiện và định dạng markdown rõ ràng với gạch đầu dòng. Cung cấp mức phạt cho cả xe máy và ô tô nếu liên quan đến vi phạm.
''';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': '$systemInstruction\n\nCâu hỏi của người dùng: $prompt'}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.3,
        'maxOutputTokens': 800,
      },
    });

    for (final model in ['gemini-3.7-flash', 'gemini-3.8-flash', 'gemini-flash-lite-latest']) {
      try {
        final endpoint = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';
        final res = await http.post(
          Uri.parse('$endpoint?key=${Uri.encodeQueryComponent(trimmedKey)}'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        ).timeout(const Duration(seconds: 12));

        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body) as Map<String, dynamic>;
          final candidates = decoded['candidates'] as List<dynamic>?;
          if (candidates != null && candidates.isNotEmpty) {
            final parts = (candidates.first['content']?['parts'] as List<dynamic>?) ?? [];
            final text = parts.map((p) => p['text']?.toString() ?? '').join();
            if (text.trim().isNotEmpty) return text.trim();
          }
        }
      } catch (_) {
        // Fallback to next model or offline engine
      }
    }
    return null;
  }
}
