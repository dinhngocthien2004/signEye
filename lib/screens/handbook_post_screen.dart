import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/handbook_models.dart';
import '../services/app_state.dart';
import '../services/data_service.dart';
import '../theme.dart';

class HandbookPostScreen extends StatefulWidget {
  final HandbookPost post;
  const HandbookPostScreen({super.key, required this.post});

  @override
  State<HandbookPostScreen> createState() => _HandbookPostScreenState();
}

class _HandbookPostScreenState extends State<HandbookPostScreen> {
  List<HandbookComment> _defaultComments = [];
  final _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    DataService.instance.loadDefaultHandbookComments().then((map) {
      setState(() => _defaultComments = map[widget.post.id] ?? []);
    });
  }

  void _submitComment(AppState state) {
    if (_commentCtrl.text.trim().isEmpty) return;
    state.addComment(
      widget.post.id,
      HandbookComment(
        author: state.userName.isEmpty ? 'Bạn' : state.userName,
        content: _commentCtrl.text.trim(),
        date: DateTime.now(),
      ),
    );
    _commentCtrl.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final post = widget.post;
    final liked = state.likedPostIds.contains(post.id);
    final currentPost = [...state.userPosts].firstWhere((p) => p.id == post.id, orElse: () => post);
    final comments = [..._defaultComments, ...(state.userComments[post.id] ?? [])];
    final df = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Bài viết')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(currentPost.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.primaryPale,
                      child: Text(currentPost.author.isNotEmpty ? currentPost.author[0].toUpperCase() : 'A',
                          style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 8),
                    Text(currentPost.author, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                    const SizedBox(width: 6),
                    Text('· ${df.format(currentPost.date)}',
                        style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(currentPost.content, style: const TextStyle(fontSize: 14.5, height: 1.7)),
                const SizedBox(height: 16),
                if (currentPost.tags.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: currentPost.tags
                        .map((t) => Chip(
                              label: Text('#$t', style: const TextStyle(fontSize: 11)),
                              backgroundColor: AppColors.surface2,
                              side: BorderSide.none,
                            ))
                        .toList(),
                  ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => state.toggleLike(currentPost.id),
                  child: Row(
                    children: [
                      Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: liked ? AppColors.danger : AppColors.muted, size: 20),
                      const SizedBox(width: 6),
                      Text('${currentPost.likes} lượt thích',
                          style: const TextStyle(fontSize: 13, color: AppColors.text2)),
                    ],
                  ),
                ),
                const Divider(height: 32),
                Text('Bình luận (${comments.length})',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 12),
                if (comments.isEmpty)
                  const Text('Chưa có bình luận nào', style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                ...comments.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.surface2,
                            child: Text(c.author.isNotEmpty ? c.author[0].toUpperCase() : '?',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surface2,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.author, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                  const SizedBox(height: 3),
                                  Text(c.content, style: const TextStyle(fontSize: 12.5, height: 1.4)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      decoration: const InputDecoration(hintText: 'Viết bình luận...'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _submitComment(state),
                    icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
