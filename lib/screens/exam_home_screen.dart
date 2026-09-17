import 'package:flutter/material.dart';

import '../models/exam_models.dart';
import '../services/data_service.dart';
import '../theme.dart';
import 'exam_take_screen.dart';

class ExamHomeScreen extends StatefulWidget {
  const ExamHomeScreen({super.key});

  @override
  State<ExamHomeScreen> createState() => _ExamHomeScreenState();
}

class _ExamHomeScreenState extends State<ExamHomeScreen> {
  ExamBank? _bank;

  @override
  void initState() {
    super.initState();
    DataService.instance.loadExamBank().then((b) => setState(() => _bank = b));
  }

  @override
  Widget build(BuildContext context) {
    final bank = _bank;
    return Scaffold(
      appBar: AppBar(title: const Text('Thi thử lý thuyết GPLX')),
      body: bank == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    final all = List<ExamQuestion>.from(bank.questions)..shuffle();
                    final picked = all.take(25).toList();
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ExamTakeScreen(questions: picked, topicLabel: 'Đề thi tổng hợp 25 câu'),
                    ));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primary2]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt_rounded, color: Colors.white, size: 26),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Thi thử tổng hợp',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                              SizedBox(height: 2),
                              Text('25 câu ngẫu nhiên · Cần đạt ≥ 90%',
                                  style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.white),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Ôn theo chủ đề', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 10),
                ...bank.topics.map((t) {
                  final qs = bank.questions.where((q) => q.topicId == t.id).toList();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: qs.isEmpty
                          ? null
                          : () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => ExamTakeScreen(questions: qs, topicLabel: t.name),
                              )),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.line),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                                  const SizedBox(height: 2),
                                  Text('${qs.length} câu hỏi',
                                      style: const TextStyle(fontSize: 11.5, color: AppColors.text2)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
