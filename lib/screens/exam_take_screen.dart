import 'package:flutter/material.dart';

import '../models/exam_models.dart';
import '../models/traffic_sign.dart';
import '../services/data_service.dart';
import '../theme.dart';
import 'exam_result_screen.dart';

class ExamTakeScreen extends StatefulWidget {
  final List<ExamQuestion> questions;
  final String topicLabel;

  const ExamTakeScreen(
      {super.key, required this.questions, required this.topicLabel});

  @override
  State<ExamTakeScreen> createState() => _ExamTakeScreenState();
}

class _ExamTakeScreenState extends State<ExamTakeScreen> {
  int _index = 0;
  int? _selected;
  bool _submitted = false;
  final List<int?> _answers = [];
  List<TrafficSign> _signs = const [];

  ExamQuestion get _current => widget.questions[_index];

  @override
  void initState() {
    super.initState();
    DataService.instance.loadSigns().then((signs) {
      if (mounted) setState(() => _signs = signs);
    });
  }

  void _submitAnswer() {
    setState(() => _submitted = true);
  }

  void _next() {
    _answers.add(_selected);
    if (_index == widget.questions.length - 1) {
      final correct = _answers.asMap().entries.where((e) {
        return e.value == widget.questions[e.key].answer;
      }).length;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => ExamResultScreen(
          total: widget.questions.length,
          correct: correct,
          topicLabel: widget.topicLabel,
        ),
      ));
      return;
    }
    setState(() {
      _index += 1;
      _selected = null;
      _submitted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _current;
    final progress = (_index + 1) / widget.questions.length;
    final sign = q.signCode == null
        ? null
        : _signs.cast<TrafficSign?>().firstWhere(
              (item) => item?.maBien.toUpperCase() == q.signCode!.toUpperCase(),
              orElse: () => null,
            );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topicLabel),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.of(context).pop()),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.surface2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text('Câu ${_index + 1}/${widget.questions.length}',
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.text2,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            if (sign != null) ...[
              Container(
                height: 154,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Image.asset(
                  sign.image,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.image_not_supported_outlined,
                      size: 42,
                      color: AppColors.muted),
                ),
              ),
              const SizedBox(height: 14),
              Text('Quan sát biển ${sign.maBien}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
            ],
            Text(q.question,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, height: 1.4)),
            const SizedBox(height: 18),
            Expanded(
              child: ListView.separated(
                itemCount: q.options.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final isCorrect = i == q.answer;
                  final isSelected = i == _selected;
                  Color bg = AppColors.surface;
                  Color border = AppColors.line;
                  if (_submitted && isSelected) {
                    bg = isCorrect
                        ? AppColors.primaryPale
                        : AppColors.dangerSoft;
                    border = isCorrect ? AppColors.primary : AppColors.danger;
                  } else if (_submitted && isCorrect) {
                    bg = AppColors.primaryPale;
                    border = AppColors.primary;
                  } else if (isSelected) {
                    border = AppColors.primary;
                  }
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap:
                        _submitted ? null : () => setState(() => _selected = i),
                    child: Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: bg,
                        border: Border.all(
                            color: border,
                            width: isSelected || (_submitted && isCorrect)
                                ? 1.4
                                : 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(q.options[i],
                          style: const TextStyle(fontSize: 13.5)),
                    ),
                  );
                },
              ),
            ),
            if (_submitted)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _selected == q.answer
                      ? AppColors.primaryPale
                      : AppColors.dangerSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  q.explanation,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: _selected == q.answer
                        ? AppColors.primary
                        : AppColors.danger,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selected == null
                    ? null
                    : (_submitted ? _next : _submitAnswer),
                child: Text(!_submitted
                    ? 'Kiểm tra đáp án'
                    : (_index == widget.questions.length - 1
                        ? 'Xem kết quả'
                        : 'Câu tiếp theo')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
