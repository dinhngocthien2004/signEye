import 'package:flutter/material.dart';

import '../models/traffic_sign.dart';
import '../services/data_service.dart';
import '../theme.dart';

/// Mirrors `screen-compare` in the original app: pick up to 3 signs and see
/// their image, meaning and fines side by side.
class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  List<TrafficSign> _all = [];
  final List<TrafficSign> _selected = [];

  @override
  void initState() {
    super.initState();
    DataService.instance.loadSigns().then((s) => setState(() => _all = s));
  }

  Future<void> _pickSign() async {
    if (_selected.length >= 3) return;
    final chosen = await showModalBottomSheet<TrafficSign>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SignPickerSheet(all: _all, excluding: _selected),
    );
    if (chosen != null) {
      setState(() => _selected.add(chosen));
    }
  }

  void _remove(TrafficSign s) => setState(() => _selected.remove(s));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('So sánh biển báo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Chọn đồng thời tối đa 3 biển để xem hình ảnh, ý nghĩa và mức phạt.',
              style: TextStyle(fontSize: 12.5, color: AppColors.text2),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (final s in _selected)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _slotFilled(s),
                    ),
                  ),
                if (_selected.length < 3)
                  Expanded(child: _slotEmpty()),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _selected.isEmpty
                  ? const Center(
                      child: Text('Chưa chọn biển nào để so sánh', style: TextStyle(color: AppColors.muted)))
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          _compareRow('Mã biển', _selected.map((s) => s.maBien).toList()),
                          _compareRow('Tên biển', _selected.map((s) => s.tenBien).toList()),
                          _compareRow('Ý nghĩa', _selected.map((s) => s.yNghia).toList()),
                          _compareRow('Phạt xe máy', _selected.map((s) => s.mucPhatXeMay).toList()),
                          _compareRow('Phạt ô tô', _selected.map((s) => s.mucPhatOto).toList()),
                          _compareRow('Trừ điểm GPLX', _selected.map((s) => s.truDiemGPLX).toList()),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slotEmpty() {
    return GestureDetector(
      onTap: _pickSign,
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line, style: BorderStyle.solid),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.add_rounded, color: AppColors.muted, size: 28),
      ),
    );
  }

  Widget _slotFilled(TrafficSign s) {
    return Container(
      height: 96,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Image.asset(s.image,
                    fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined)),
              ),
              const SizedBox(height: 2),
              Text(s.maBien, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
            ],
          ),
          Positioned(
            top: -4,
            right: -4,
            child: GestureDetector(
              onTap: () => _remove(s),
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compareRow(String label, List<String> values) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.primary)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: values
                .map((v) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(v.isEmpty ? '—' : v, style: const TextStyle(fontSize: 12, height: 1.4)),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SignPickerSheet extends StatefulWidget {
  final List<TrafficSign> all;
  final List<TrafficSign> excluding;

  const _SignPickerSheet({required this.all, required this.excluding});

  @override
  State<_SignPickerSheet> createState() => _SignPickerSheetState();
}

class _SignPickerSheetState extends State<_SignPickerSheet> {
  final _ctrl = TextEditingController();
  late List<TrafficSign> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.all;
  }

  void _search(String q) {
    setState(() {
      _filtered = DataService.search(widget.all, q)
          .where((s) => !widget.excluding.contains(s))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          children: [
            TextField(
              controller: _ctrl,
              onChanged: _search,
              decoration: const InputDecoration(hintText: 'Tìm mã biển, tên biển...'),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _filtered.length,
                itemBuilder: (context, i) {
                  final s = _filtered[i];
                  return ListTile(
                    leading: SizedBox(
                      width: 40,
                      height: 40,
                      child: Image.asset(s.image,
                          fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined)),
                    ),
                    title: Text('${s.maBien} · ${s.tenBien}', style: const TextStyle(fontSize: 13.5)),
                    onTap: () => Navigator.pop(context, s),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
