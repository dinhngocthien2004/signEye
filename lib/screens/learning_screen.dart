import 'package:flutter/material.dart';

import '../models/learning_models.dart';
import '../services/data_service.dart';
import '../theme.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  LearningData? _data;
  String? _selectedLicense;

  @override
  void initState() {
    super.initState();
    DataService.instance.loadLearningData().then((d) {
      setState(() {
        _data = d;
        _selectedLicense = d.licenses.isNotEmpty ? d.licenses.first.id : null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      appBar: AppBar(title: const Text('Học lý thuyết GPLX')),
      body: data == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Chọn hạng bằng lái', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: data.licenses.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final l = data.licenses[i];
                      final active = l.id == _selectedLicense;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedLicense = l.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active ? AppColors.primary : AppColors.surface2,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(l.name,
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: active ? Colors.white : AppColors.text2)),
                        ),
                      );
                    },
                  ),
                ),
                if (_selectedLicense != null && data.licenseNotes[_selectedLicense] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.primaryPale, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(data.licenseNotes[_selectedLicense]!,
                              style: const TextStyle(fontSize: 12.5, color: AppColors.primary, height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Text('Chương học', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 10),
                ...data.chapters.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => ChapterDetailScreen(chapter: c))),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            border: Border.all(color: AppColors.line),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                    color: AppColors.primaryPale, borderRadius: BorderRadius.circular(12)),
                                alignment: Alignment.center,
                                child: Text(c.icon, style: const TextStyle(fontSize: 20)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text(c.summary,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12, color: AppColors.text2)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                            ],
                          ),
                        ),
                      ),
                    )),
              ],
            ),
    );
  }
}

class ChapterDetailScreen extends StatefulWidget {
  final LearningChapter chapter;
  const ChapterDetailScreen({super.key, required this.chapter});

  @override
  State<ChapterDetailScreen> createState() => _ChapterDetailScreenState();
}

class _ChapterDetailScreenState extends State<ChapterDetailScreen> {
  int? _selected;
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.chapter;
    return Scaffold(
      appBar: AppBar(title: Text(c.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: AppColors.surface2,
                child: Image.asset(
                  c.image,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, color: AppColors.muted),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(c.content, style: const TextStyle(fontSize: 14, height: 1.6)),
          const SizedBox(height: 14),
          _infoBox('Ví dụ thực tế', c.example, AppColors.blueSoft, AppColors.blue),
          const SizedBox(height: 10),
          _infoBox('Mẹo ghi nhớ', c.memoryTip, AppColors.primaryPale, AppColors.primary),
          const SizedBox(height: 22),
          const Text('Câu hỏi luyện tập', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 10),
          Text(c.practice.question, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ...List.generate(c.practice.options.length, (i) {
            final isCorrect = i == c.practice.answer;
            final isSelected = i == _selected;
            Color bg = AppColors.surface;
            Color border = AppColors.line;
            if (_submitted && isSelected) {
              bg = isCorrect ? AppColors.primaryPale : AppColors.dangerSoft;
              border = isCorrect ? AppColors.primary : AppColors.danger;
            } else if (_submitted && isCorrect) {
              bg = AppColors.primaryPale;
              border = AppColors.primary;
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _submitted ? null : () => setState(() => _selected = i),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bg,
                    border: Border.all(color: border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(c.practice.options[i], style: const TextStyle(fontSize: 13.5)),
                ),
              ),
            );
          }),
          const SizedBox(height: 6),
          if (!_submitted)
            ElevatedButton(
              onPressed: _selected == null ? null : () => setState(() => _submitted = true),
              child: const Text('Kiểm tra đáp án'),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _selected == c.practice.answer ? AppColors.primaryPale : AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                c.practice.explanation,
                style: TextStyle(
                  fontSize: 12.5,
                  color: _selected == c.practice.answer ? AppColors.primary : AppColors.danger,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoBox(String title, String body, Color bg, Color fg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: fg)),
          const SizedBox(height: 4),
          Text(body, style: TextStyle(fontSize: 12.5, color: fg, height: 1.4)),
        ],
      ),
    );
  }
}
