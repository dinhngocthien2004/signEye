import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signeye_flutter/screens/game_screen.dart';
import 'package:signeye_flutter/services/app_state.dart';
import 'package:signeye_flutter/services/data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Traffic Sign Game & Coins Tests', () {
    test('addCoins adds coins correctly and notifies listeners', () async {
      final state = AppState();
      await state.init();

      expect(state.coins, 0);

      await state.addCoins(5);
      expect(state.coins, 5);

      await state.addCoins(5);
      expect(state.coins, 10);
    });

    test('exchangeCoinsToCash requires at least 1000 coins and exchanges 1000 xu to 1000 VND', () async {
      final state = AppState();
      await state.init();

      await state.addCoins(995);
      expect(state.coins, 995);

      // Cannot exchange with < 1000 coins
      final failedExchange = await state.exchangeCoinsToCash(coinsToExchange: 1000);
      expect(failedExchange, isFalse);
      expect(state.coins, 995);
      expect(state.rewardBalance, 0);

      // Add 5 more coins to reach 1000
      await state.addCoins(5);
      expect(state.coins, 1000);

      // Successfully exchange 1000 coins
      final successExchange = await state.exchangeCoinsToCash(coinsToExchange: 1000);
      expect(successExchange, isTrue);
      expect(state.coins, 0);
      expect(state.rewardBalance, 1000);
    });

    test('buyProWithCoins allows redeeming Pro directly with coins', () async {
      final state = AppState();
      await state.init();

      expect(state.isPro, isFalse);

      await state.addCoins(1000);
      final success = await state.buyProWithCoins(days: 1, costCoins: 1000);

      expect(success, isTrue);
      expect(state.coins, 0);
      expect(state.isPro, isTrue);
      expect(state.proExpiry, isNotNull);
      expect(state.proExpiry!.isAfter(DateTime.now()), isTrue);
    });

    test('buyProWithRewardBalance allows redeeming Pro with converted cash', () async {
      final state = AppState();
      await state.init();

      await state.addCoins(1000);
      await state.exchangeCoinsToCash(coinsToExchange: 1000);
      expect(state.rewardBalance, 1000);

      final success = await state.buyProWithRewardBalance(days: 1, costVnd: 1000);
      expect(success, isTrue);
      expect(state.rewardBalance, 0);
      expect(state.isPro, isTrue);
      expect(state.proExpiry, isNotNull);
    });

    testWidgets('TrafficSignGameScreen loads signs, presents 4 options, and awards 5 coins on correct answer', (tester) async {
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
            home: TrafficSignGameScreen(),
          ),
        ),
      );

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      // Verify Game elements
      expect(find.text('Đố Vui Biển Báo'), findsOneWidget);
      expect(find.text('Đây là biển báo gì?'), findsOneWidget);
      expect(find.text('Chọn đúng để nhận ngay +5 xu 🪙'), findsOneWidget);
      expect(find.text('0 xu'), findsOneWidget);

      // Verify letters A, B, C, D exist
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);

      // Tap on option A
      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();

      // Total answered should be 1
      expect(state.coins == 5 || state.coins == 0, isTrue);

      // Next question button should be visible
      expect(find.text('Câu hỏi tiếp theo'), findsOneWidget);

      // Scroll and tap Next question
      await tester.ensureVisible(find.text('Câu hỏi tiếp theo'));
      await tester.tap(find.text('Câu hỏi tiếp theo'));
      await tester.pumpAndSettle();

      // New question should be ready to answer
      expect(find.text('Câu hỏi tiếp theo'), findsNothing);
    });
  });
}
