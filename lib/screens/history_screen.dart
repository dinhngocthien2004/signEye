import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/traffic_sign.dart';
import '../services/app_state.dart';
import '../services/data_service.dart';
import '../theme.dart';
import '../widgets/sign_detail_sheet.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<TrafficSign> _signs = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    DataService.instance.loadSigns().then((s) => setState(() => _signs = s));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  TrafficSign? _findSign(String maBien) {
    for (final s in _signs) {
      if (s.maBien == maBien) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final df = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử'),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'Tra cứu & Quét'), Tab(text: 'Kết quả thi')],
        ),
        actions: [
          if (_tab.index == 0 && state.history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => state.clearHistory(),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          if (state.history.isEmpty)
            const Center(child: Text('Chưa có lịch sử tra cứu', style: TextStyle(color: AppColors.muted)))
          else
            ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final h = state.history[i];
                final sign = _findSign(h.maBien);
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        h.source == 'scan' ? Icons.camera_alt_rounded : Icons.search_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${h.maBien}${sign != null ? " · ${sign.tenBien}" : ""}',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                            const SizedBox(height: 2),
                            Text(df.format(h.date), style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
                          ],
                        ),
                      ),
                      if (sign != null)
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded),
                          onPressed: () => showSignDetailSheet(context, sign, allSigns: _signs),
                        ),
                    ],
                  ),
                );
              },
            ),
          if (state.examAttempts.isEmpty)
            const Center(child: Text('Chưa có bài thi nào', style: TextStyle(color: AppColors.muted)))
          else
            ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.examAttempts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final a = state.examAttempts[i];
                final color = a.passed ? AppColors.success : AppColors.danger;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text('${a.correct}/${a.total}',
                            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.topicLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                            const SizedBox(height: 2),
                            Text(df.format(a.date), style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
                          ],
                        ),
                      ),
                      Text(a.passed ? 'Đạt' : 'Chưa đạt',
                          style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
