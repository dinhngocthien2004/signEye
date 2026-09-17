import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exam_models.dart';
import '../services/app_state.dart';
import '../theme.dart';

class ExamResultScreen extends StatefulWidget {
  final int total;
  final int correct;
  final String topicLabel;

  const ExamResultScreen({
    super.key,
    required this.total,
    required this.correct,
    required this.topicLabel,
  });

  @override
  State<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends State<ExamResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().saveExamAttempt(ExamAttempt(
            date: DateTime.now(),
            total: widget.total,
            correct: widget.correct,
            topicLabel: widget.topicLabel,
          ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final percent = widget.total == 0 ? 0.0 : (widget.correct / widget.total) * 100;
    final passed = percent >= 90;

    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả thi'), automaticallyImplyLeading: false),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (passed ? AppColors.success : AppColors.danger).withOpacity(0.12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: passed ? AppColors.success : AppColors.danger,
                  size: 64,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                passed ? 'Chúc mừng, bạn đã đạt!' : 'Chưa đạt, cố gắng thêm nhé!',
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(widget.topicLabel, style: const TextStyle(color: AppColors.text2, fontSize: 13)),
              const SizedBox(height: 18),
              Text('${widget.correct}/${widget.total}',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.primary)),
              const SizedBox(height: 4),
              Text('${percent.toStringAsFixed(0)}% câu đúng',
                  style: const TextStyle(color: AppColors.text2, fontSize: 13)),
              const SizedBox(height: 6),
              const Text('Điều kiện đạt: ≥ 90% số câu đúng',
                  style: TextStyle(color: AppColors.muted, fontSize: 11.5)),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  child: const Text('Về trang chủ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
