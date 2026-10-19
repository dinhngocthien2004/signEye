import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signeye_flutter/screens/game_screen.dart';
import 'package:signeye_flutter/screens/puzzle_game_screen.dart';
import 'package:signeye_flutter/services/app_state.dart';
import 'package:signeye_flutter/services/data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Traffic Sign Puzzle Game Tests (> 20 pieces)', () {
    test('1 Month (30 days) and 2 Month (60 days) Pro package redemption', () async {
      final state = AppState();
      await state.init();

      expect(state.isPro, isFalse);

      // Add coins to afford 1-month Pro (39,000 coins)
      await state.addCoins(39000);
      expect(state.coins, 39000);

      // Redeem 1-Month Pro
      final res1m = await state.buyProWithCoins(days: 30, costCoins: 39000);
      expect(res1m, isTrue);
      expect(state.isPro, isTrue);
      expect(state.coins, 0);

      // Test 2-Month Pro (60 days) with cash converted from coins
      // Add 75,000 coins and exchange to cash
      await state.addCoins(75000);
      await state.exchangeCoinsToCash(coinsToExchange: 75000);
      expect(state.rewardBalance, 75000);

      // Redeem 2-Month Pro with cash
      final res2m = await state.buyProWithRewardBalance(days: 60, costVnd: 75000);
      expect(res2m, isTrue);
      expect(state.rewardBalance, 0);
      expect(state.isPro, isTrue);
    });

    testWidgets('Puzzle game initializes 25 pieces (> 20), displays error when incorrect, and awards 10 xu + explanation when solved', (tester) async {
      final state = AppState();
      await state.init();

      // Preload signs
      await tester.runAsync(() async {
        await DataService.instance.loadSigns();
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: const MaterialApp(
            home: PuzzleGameScreen(),
          ),
        ),
      );

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      // 1. Verify 25 pieces (> 20 pieces requirement)
      expect(find.text('Ghép Hình Biển Báo'), findsOneWidget);
      expect(find.text('25 mảnh ghép'), findsOneWidget);
      expect(find.text('+10 xu khi ghép đúng'), findsOneWidget);

      // 2. Click "Kiểm tra kết quả" while scrambled -> Should show error dialog
      final checkBtn = find.text('Kiểm tra kết quả');
      await tester.ensureVisible(checkBtn);
      await tester.tap(checkBtn);
      await tester.pumpAndSettle();

      // Verify Error Dialog ("Chưa chính xác!")
      expect(find.text('Chưa chính xác!'), findsOneWidget);
      expect(find.text('Thử ghép tiếp'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Thử ghép tiếp'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa chính xác!'), findsNothing);

      // 3. Trigger auto-solve via test helper button ("Hoàn thành nhanh (Chế độ xem mẫu)")
      expect(state.coins, 0);
      final autoSolveBtn = find.text('Hoàn thành nhanh (Chế độ xem mẫu)');
      await tester.ensureVisible(autoSolveBtn);
      await tester.tap(autoSolveBtn);
      await tester.pumpAndSettle();

      // 4. Verify awarded 10 xu
      expect(state.coins, 10);

      // 5. Verify sign explanation modal is opened
      expect(find.text('GHÉP HÌNH THÀNH CÔNG! 🎉'), findsOneWidget);
      expect(find.text('+10 XU THƯỞNG'), findsOneWidget);
      expect(find.text('Ý nghĩa biển báo:'), findsOneWidget);

      // Verify "Đổi gói Pro" and "Biển tiếp theo" buttons
      expect(find.text('Đổi gói Pro'), findsOneWidget);
      expect(find.text('Biển tiếp theo'), findsOneWidget);
    });

    testWidgets('RedeemProSheet displays both 1-Month and 2-Month options', (tester) async {
      final state = AppState();
      await state.init();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: const MaterialApp(
            home: Scaffold(
              body: RedeemProSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify header and package options
      expect(find.text('Đổi Xu & Mua Gói Pro'), findsOneWidget);
      expect(find.text('Gói Pro 1 Tháng (Chuẩn VIP)'), findsOneWidget);
      expect(find.text('Gói Pro 2 Tháng (Siêu Tiết Kiệm)'), findsOneWidget);
      expect(find.text('39.000 xu hoặc 39.000đ'), findsOneWidget);
      expect(find.text('75.000 xu hoặc 75.000đ'), findsOneWidget);
    });
  });
}
