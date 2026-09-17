import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/handbook_models.dart';
import '../services/app_state.dart';
import '../services/data_service.dart';
import '../theme.dart';
import 'handbook_post_screen.dart';

class HandbookScreen extends StatefulWidget {
  const HandbookScreen({super.key});

  @override
  State<HandbookScreen> createState() => _HandbookScreenState();
}

class _HandbookScreenState extends State<HandbookScreen> {
  List<HandbookPost> _defaultPosts = [];
  String? _category;

  static const _categories = {
    'an-toan': ('🛡️', 'An toàn'),
    'xu-ly': ('🆘', 'Xử lý tình huống'),
    'duong-cao-toc': ('🛣️', 'Đường cao tốc'),
    'canh-bao': ('⚠️', 'Cảnh báo'),
  };

  @override
  void initState() {
    super.initState();
    DataService.instance.loadDefaultHandbookPosts().then((p) => setState(() => _defaultPosts = p));
  }

  List<HandbookPost> _allPosts(AppState state) {
    final list = [...state.userPosts, ..._defaultPosts];
    list.sort((a, b) => b.date.compareTo(a.date));
    if (_category == null) return list;
    return list.where((p) => p.category == _category).toList();
  }

  void _openComposer() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String category = 'an-toan';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Đăng bài mới', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 14),
              TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: 'Tiêu đề bài viết')),
              const SizedBox(height: 10),
              TextField(
                controller: contentCtrl,
                maxLines: 5,
                decoration: const InputDecoration(hintText: 'Nội dung chia sẻ kinh nghiệm lái xe...'),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _categories.entries.map((e) {
                  final active = category == e.key;
                  return ChoiceChip(
                    label: Text('${e.value.$1} ${e.value.$2}'),
                    selected: active,
                    onSelected: (_) => setSheetState(() => category = e.key),
                    selectedColor: AppColors.primaryPale,
                    labelStyle: TextStyle(color: active ? AppColors.primary : AppColors.text2, fontSize: 12),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) return;
                    final state = context.read<AppState>();
                    state.addUserPost(HandbookPost(
                      id: DateTime.now().millisecondsSinceEpoch,
                      title: titleCtrl.text.trim(),
                      content: contentCtrl.text.trim(),
                      author: state.userName.isEmpty ? 'Bạn' : state.userName,
                      date: DateTime.now(),
                      likes: 0,
                      category: category,
                      tags: const [],
                    ));
                    Navigator.pop(ctx);
                  },
                  child: const Text('Đăng bài'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final posts = _allPosts(state);
    final df = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cẩm nang lái xe'),
        actions: [
          TextButton(onPressed: _openComposer, child: const Text('+ Đăng bài')),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 84,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              children: [
                _categoryCard('📚', 'Tất cả', null),
                ..._categories.entries.map((e) => _categoryCard(e.value.$1, e.value.$2, e.key)),
              ],
            ),
          ),
          Expanded(
            child: posts.isEmpty
                ? const Center(child: Text('Chưa có bài viết', style: TextStyle(color: AppColors.muted)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: posts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final p = posts[i];
                      final liked = state.likedPostIds.contains(p.id);
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => HandbookPostScreen(post: p))),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            border: Border.all(color: AppColors.line),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                              const SizedBox(height: 4),
                              Text(p.content,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12.5, color: AppColors.text2, height: 1.4)),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Text(p.author, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                                  const SizedBox(width: 6),
                                  Text('· ${df.format(p.date)}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () => state.toggleLike(p.id),
                                    child: Row(
                                      children: [
                                        Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                            size: 16, color: liked ? AppColors.danger : AppColors.muted),
                                        const SizedBox(width: 3),
                                        Text('${p.likes}',
                                            style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _categoryCard(String emoji, String label, String? key) {
    final active = _category == key;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => setState(() => _category = key),
        child: Container(
          width: 84,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.primaryPale : AppColors.surface,
            border: Border.all(color: active ? AppColors.primary : AppColors.line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: active ? AppColors.primary : AppColors.text2)),
            ],
          ),
        ),
      ),
    );
  }
}
