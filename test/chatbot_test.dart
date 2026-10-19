import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signeye_flutter/models/traffic_sign.dart';
import 'package:signeye_flutter/screens/chatbot_screen.dart';
import 'package:signeye_flutter/services/app_state.dart';
import 'package:signeye_flutter/services/chatbot_service.dart';
import 'package:signeye_flutter/services/data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SignEye AI Chatbot Tests', () {
    test('ChatbotAiService answers driving law queries accurately', () async {
      final signs = await DataService.instance.loadSigns();
      expect(signs.isNotEmpty, isTrue);

      // Test 1: Query about specific sign P.102
      final reply1 = await ChatbotAiService.instance.reply(
        prompt: 'Biển P.102 là gì?',
        catalog: signs,
      );
      expect(reply1.isUser, isFalse);
      expect(reply1.identifiedSign, isNotNull);
      expect(reply1.identifiedSign!.maBien, 'P.102');
      expect(reply1.text.contains('Cấm đi ngược chiều'), isTrue);

      // Test 2: Query about red light fine
      final reply2 = await ChatbotAiService.instance.reply(
        prompt: 'Vượt đèn đỏ bị phạt bao nhiêu tiền?',
        catalog: signs,
      );
      expect(reply2.isUser, isFalse);
      expect(reply2.text.contains('Nghị định 100/2019'), isTrue);
      expect(reply2.text.contains('800.000đ - 1.000.000đ'), isTrue);

      // Test 3: Query about turning left vs U-turn rule
      final reply3 = await ChatbotAiService.instance.reply(
        prompt: 'Gặp biển cấm rẽ trái có được quay đầu xe không?',
        catalog: signs,
      );
      expect(reply3.isUser, isFalse);
      expect(reply3.text.contains('CÓ ĐƯỢC PHÉP QUAY ĐẦU'), isTrue);
      expect(reply3.text.contains('QCVN 41:2019/BGTVT'), isTrue);
    });

    test('ChatbotAiService processes sample sign image asset', () async {
      final signs = await DataService.instance.loadSigns();

      // Test image lookup with sample asset
      final reply = await ChatbotAiService.instance.reply(
        prompt: 'Nhận diện biển báo này',
        imageAssetPath: 'assets/images/prohibition/P102.jpg',
        catalog: signs,
      );

      expect(reply.isUser, isFalse);
      expect(reply.identifiedSign, isNotNull);
      expect(reply.identifiedSign!.maBien, 'P.102');
      expect(reply.text.contains('Tôi đã nhận diện được biển báo'), isTrue);
    });

    testWidgets('AiChatbotScreen renders welcoming UI, handles text questions, and sample image lookup', (tester) async {
      final state = AppState();
      await state.init();

      List<TrafficSign> signs = [];
      await tester.runAsync(() async {
        signs = await DataService.instance.loadSigns();
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: MaterialApp(
            home: AiChatbotScreen(catalog: signs),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify Header and Welcome message
      expect(find.text('Trợ lý AI SignEye'), findsOneWidget);
      expect(find.text('Tra cứu & gửi ảnh nhận diện 24/7'), findsOneWidget);
      expect(find.textContaining('Xin chào! Tôi là Trợ lý AI SignEye'), findsOneWidget);

      // 2. Verify quick follow-up chips are rendered
      expect(find.text('📷 Gửi ảnh nhận diện biển báo'), findsOneWidget);
      expect(find.text('Biển cấm đi ngược chiều P.102'), findsOneWidget);

      // 3. Tap quick suggestion chip to ask about P.102
      await tester.tap(find.text('Biển cấm đi ngược chiều P.102'));
      await tester.pumpAndSettle();

      // 4. Verify AI responds with P.102 card
      expect(find.text('Xem chi tiết biển'), findsOneWidget);
      expect(find.textContaining('P.102'), findsWidgets);

      // 5. Open sample images sheet
      await tester.tap(find.byIcon(Icons.photo_library_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Chọn ảnh mẫu biển báo để tra cứu'), findsOneWidget);
      expect(find.text('P.102'), findsWidgets);

      // Tap first sample sign
      await tester.tap(find.text('P.102').last);
      await tester.pumpAndSettle();

      // Staged image bar should appear
      expect(find.text('Ảnh đính kèm đã sẵn sàng'), findsOneWidget);

      // Send the image
      await tester.tap(find.byKey(const Key('chatbot_send_btn')));
      await tester.pumpAndSettle();

      // Verify AI analyzed the image and identified P.102
      expect(find.textContaining('Tôi đã nhận diện được biển báo trong ảnh!'), findsOneWidget);
    });
  });
}
