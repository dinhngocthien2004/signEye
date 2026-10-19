import 'package:flutter/material.dart';

import '../models/traffic_sign.dart';
import '../services/data_service.dart';
import '../theme.dart';
import '../widgets/sign_card.dart';
import '../widgets/sign_detail_sheet.dart';
import 'chatbot_screen.dart';

class SearchScreen extends StatefulWidget {
  final String? initialGroup;
  const SearchScreen({super.key, this.initialGroup});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<TrafficSign> _all = [];
  List<TrafficSign> _filtered = [];
  String? _group;

  static const _groups = [
    'Biển báo cấm',
    'Biển báo nguy hiểm',
    'Biển hiệu lệnh',
    'Biển chỉ dẫn',
    'Biển phụ',
  ];

  @override
  void initState() {
    super.initState();
    _group = widget.initialGroup;
    DataService.instance.loadSigns().then((s) {
      setState(() {
        _all = s;
        _applyFilters();
      });
    });
  }

  void _applyFilters() {
    var list = DataService.search(_all, _controller.text);
    if (_group != null) {
      list = list.where((s) => s.nhomBien == _group).toList();
    }
    setState(() => _filtered = list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tra cứu biển báo'),
        actions: [
          IconButton(
            tooltip: 'Hỏi & gửi ảnh cho Chatbot AI',
            icon: const Text('🤖', style: TextStyle(fontSize: 22)),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AiChatbotScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _controller,
              onChanged: (_) => _applyFilters(),
              decoration: InputDecoration(
                hintText: 'Tìm theo mã biển, tên biển...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _controller.clear();
                          _applyFilters();
                        },
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _chip('Tất cả', _group == null, () {
                  setState(() => _group = null);
                  _applyFilters();
                }),
                ..._groups.map((g) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _chip(g.replaceFirst('Biển ', '').replaceFirst('báo ', ''), _group == g, () {
                        setState(() => _group = g);
                        _applyFilters();
                      }),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Chatbot AI Helper Banner
          InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AiChatbotScreen()),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: const Row(
                children: [
                  Text('🤖', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Không rõ mã biển? Gửi ảnh vào Chatbot AI để nhận diện ngay!',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4338CA),
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Color(0xFF4338CA)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),

          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off_rounded, size: 48, color: AppColors.muted),
                          const SizedBox(height: 10),
                          const Text(
                            'Không tìm thấy biển báo phù hợp',
                            style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AiChatbotScreen()),
                            ),
                            icon: const Text('🤖', style: TextStyle(fontSize: 16)),
                            label: const Text('Gửi ảnh hoặc hỏi Chatbot AI'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final sign = _filtered[i];
                      return SignCard(
                        sign: sign,
                        onTap: () => showSignDetailSheet(context, sign, allSigns: _all),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface2,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.text2,
          ),
        ),
      ),
    );
  }
}
