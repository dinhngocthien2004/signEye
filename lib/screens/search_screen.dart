import 'package:flutter/material.dart';

import '../models/traffic_sign.dart';
import '../services/data_service.dart';
import '../theme.dart';
import '../widgets/sign_card.dart';
import '../widgets/sign_detail_sheet.dart';

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
      appBar: AppBar(title: const Text('Tra cứu biển báo')),
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
          const SizedBox(height: 8),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text('Không tìm thấy biển báo phù hợp',
                        style: TextStyle(color: AppColors.muted)))
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
