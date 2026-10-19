import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signeye_flutter/models/handbook_models.dart';
import 'package:signeye_flutter/screens/handbook_post_screen.dart';
import 'package:signeye_flutter/screens/handbook_screen.dart';
import 'package:signeye_flutter/services/app_state.dart';
import 'package:signeye_flutter/services/data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Handbook likes and comments tests', () {
    test('HandbookPost getPostLikes increments when liked and decrements when unliked', () async {
      final state = AppState();
      await state.init();

      final post = HandbookPost(
        id: 1,
        title: 'Đội mũ bảo hiểm',
        content: 'Nội dung',
        author: 'Admin',
        date: DateTime.now(),
        likes: 15,
        category: 'an-toan',
        tags: const [],
      );

      // Initially not liked
      expect(state.isPostLiked(post.id), isFalse);
      expect(state.getPostLikes(post), 15);

      // User likes the post
      await state.toggleLike(post.id);
      expect(state.isPostLiked(post.id), isTrue);
      expect(state.getPostLikes(post), 16);

      // User unlikes the post
      await state.toggleLike(post.id);
      expect(state.isPostLiked(post.id), isFalse);
      expect(state.getPostLikes(post), 15);
    });

    test('User posts like count starts at 0 and increments/decrements cleanly', () async {
      final state = AppState();
      await state.init();

      final userPost = HandbookPost(
        id: 999,
        title: 'Kinh nghiệm lái đèo',
        content: 'Giữ số thấp khi xuống dốc...',
        author: 'Tài xế mới',
        date: DateTime.now(),
        likes: 0,
        category: 'an-toan',
        tags: const ['kinh-nghiem'],
      );

      await state.addUserPost(userPost);
      expect(state.userPosts.length, 1);
      expect(state.getPostLikes(userPost), 0);

      // Like user post
      await state.toggleLike(userPost.id);
      expect(state.isPostLiked(userPost.id), isTrue);
      expect(state.getPostLikes(userPost), 1);

      // Unlike user post
      await state.toggleLike(userPost.id);
      expect(state.isPostLiked(userPost.id), isFalse);
      expect(state.getPostLikes(userPost), 0);
    });

    test('Adding comments persists and associates with post id', () async {
      final state = AppState();
      await state.init();

      expect(state.userComments[1], isNull);

      final newComment = HandbookComment(
        author: 'Bác Ba',
        content: 'Chia sẻ rất hay và thực tế!',
        date: DateTime.now(),
      );

      await state.addComment(1, newComment);
      expect(state.userComments[1]?.length, 1);
      expect(state.userComments[1]!.first.author, 'Bác Ba');
      expect(state.userComments[1]!.first.content, 'Chia sẻ rất hay và thực tế!');
    });

    test('Default comments in handbook.json are realistic and have no demo placeholders', () async {
      final commentsMap = await DataService.instance.loadDefaultHandbookComments();
      expect(commentsMap.isNotEmpty, isTrue);

      for (final entry in commentsMap.entries) {
        for (final comment in entry.value) {
          // Verify no demo placeholders like "Nguyễn Văn A", "Trần Thị B", etc.
          expect(comment.author.contains('Nguyễn Văn A'), isFalse);
          expect(comment.author.contains('Trần Thị B'), isFalse);
          expect(comment.author.contains('Lê Văn C'), isFalse);
          expect(comment.author.contains('Phạm Thị D'), isFalse);
          expect(comment.author.contains('Nguyễn Văn E'), isFalse);
          expect(comment.content.isNotEmpty, isTrue);
        }
      }
    });

    testWidgets('HandbookPostScreen shows updated likes when heart is clicked', (tester) async {
      final state = AppState();
      await state.init();

      final post = HandbookPost(
        id: 1,
        title: 'Đội mũ bảo hiểm đúng cách',
        content: 'Mũ bảo hiểm phải vừa vặn với đầu...',
        author: 'Admin',
        date: DateTime.now(),
        likes: 15,
        category: 'an-toan',
        tags: const ['mũ bảo hiểm'],
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: MaterialApp(
            home: HandbookPostScreen(post: post),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially shows 15 lượt thích
      expect(find.text('15 lượt thích'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

      // Tap on the like button
      await tester.tap(find.text('15 lượt thích'));
      await tester.pumpAndSettle();

      // Like count should now be 16 lượt thích and heart filled!
      expect(find.text('16 lượt thích'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.text('15 lượt thích'), findsNothing);

      // Tap again to unlike
      await tester.tap(find.text('16 lượt thích'));
      await tester.pumpAndSettle();

      // Like count should return to 15 lượt thích and heart outline!
      expect(find.text('15 lượt thích'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.text('16 lượt thích'), findsNothing);
    });

    testWidgets('HandbookScreen displays dynamic like count and toggles on click', (tester) async {
      final state = AppState();
      await state.init();

      // Preload posts so initState gets cached data immediately
      await tester.runAsync(() async {
        await DataService.instance.loadDefaultHandbookPosts();
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: const MaterialApp(
            home: HandbookScreen(),
          ),
        ),
      );
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      // Top post (post 5, latest date 2026-06-05) has 6 default likes
      expect(find.text('6'), findsOneWidget);

      // Tap heart to like post 5
      await state.toggleLike(5);
      await tester.pumpAndSettle();

      // Now it should display 7!
      expect(find.text('7'), findsOneWidget);
      expect(find.text('6'), findsNothing);

      // Toggle back to unlike post 5
      await state.toggleLike(5);
      await tester.pumpAndSettle();

      expect(find.text('6'), findsOneWidget);
      expect(find.text('7'), findsNothing);
    });
  });
}
