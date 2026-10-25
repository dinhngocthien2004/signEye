import 'package:flutter/material.dart';

import '../models/traffic_sign.dart';
import '../services/data_service.dart';
import '../theme.dart';

/// Màn hình So sánh biển báo giao thông trực quan, giúp người dùng
/// phân biệt các biển báo tương đồng, hay gây nhầm lẫn theo QCVN 41:2019.
class CompareScreen extends StatefulWidget {
  final TrafficSign? initialSignA;
  final TrafficSign? initialSignB;

  const CompareScreen({super.key, this.initialSignA, this.initialSignB});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  List<TrafficSign> _all = [];
  final List<TrafficSign> _selected = [];

  // Danh sách các cặp biển thường gây nhầm lẫn nhất
  static const _presets = [
    {
      'title': 'Cấm Dừng vs Cấm Đỗ',
      'icon': '🚫',
      'codeA': 'P.130',
      'codeB': 'P.131a',
    },
    {
      'title': 'Cấm Ngược Chiều vs Đường 1 Chiều',
      'icon': '⛔',
      'codeA': 'P.102',
      'codeB': 'I.407a',
    },
    {
      'title': 'Đường Ưu Tiên vs Không Ưu Tiên',
      'icon': '🔀',
      'codeA': 'I.401',
      'codeB': 'W.208',
    },
    {
      'title': 'Cấm Ô Tô vs Cấm Xe Tải',
      'icon': '🚚',
      'codeA': 'P.103a',
      'codeB': 'P.106a',
    },
    {
      'title': 'Vòng Xuyến: Hiệu Lệnh vs Nguy Hiểm',
      'icon': '🔄',
      'codeA': 'R.303',
      'codeB': 'W.206',
    },
    {
      'title': 'Cấm Quay Đầu vs Cấm Rẽ Trái',
      'icon': '↩️',
      'codeA': 'P.124a',
      'codeB': 'P.123a',
    },
  ];

  @override
  void initState() {
    super.initState();
    DataService.instance.loadSigns().then((s) {
      if (mounted) {
        setState(() {
          _all = s;
          if (widget.initialSignA != null) _selected.add(widget.initialSignA!);
          if (widget.initialSignB != null) _selected.add(widget.initialSignB!);

          // Mặc định nạp cặp Cấm Dừng vs Cấm Đỗ nếu chưa chọn biển nào
          if (_selected.isEmpty && _all.isNotEmpty) {
            final signA = _all.firstWhere((x) => x.maBien == 'P.130', orElse: () => _all[0]);
            final signB = _all.firstWhere((x) => x.maBien == 'P.131a', orElse: () => _all.length > 1 ? _all[1] : _all[0]);
            _selected.add(signA);
            if (signA != signB) _selected.add(signB);
          }
        });
      }
    });
  }

  void _applyPreset(String codeA, String codeB) {
    if (_all.isEmpty) return;
    final a = _all.firstWhere((s) => s.maBien.toLowerCase() == codeA.toLowerCase(), orElse: () => _all[0]);
    final b = _all.firstWhere((s) => s.maBien.toLowerCase() == codeB.toLowerCase(), orElse: () => _all.length > 1 ? _all[1] : _all[0]);
    setState(() {
      _selected.clear();
      _selected.add(a);
      if (a != b) _selected.add(b);
    });
  }

  Future<void> _pickSign() async {
    if (_selected.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chỉ có thể so sánh tối đa 3 biển báo cùng lúc.')),
      );
      return;
    }
    final chosen = await showModalBottomSheet<TrafficSign>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SignPickerSheet(all: _all, excluding: _selected),
    );
    if (chosen != null && mounted) {
      setState(() => _selected.add(chosen));
    }
  }

  void _remove(TrafficSign s) => setState(() => _selected.remove(s));

  Color _groupColor(String group) {
    final g = group.toLowerCase();
    if (g.contains('cấm')) return const Color(0xFFDC2626);
    if (g.contains('nguy hiểm')) return const Color(0xFFD97706);
    if (g.contains('hiệu lệnh')) return const Color(0xFF2563EB);
    if (g.contains('chỉ dẫn')) return const Color(0xFF059669);
    return const Color(0xFF4B5563);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('So sánh biển báo', style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
        actions: [
          if (_selected.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Xóa hết', style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () => setState(() => _selected.clear()),
            ),
        ],
      ),
      body: Column(
        children: [
          // ─── 1. Thanh gợi ý các cặp biển hay nhầm lẫn ───
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: AppColors.line)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.tips_and_updates_rounded, size: 14, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'CÁC CẶP BIỂN DỄ NHẦM LẪN (CHẠM ĐỂ SO SÁNH):',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 0.2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _presets.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final p = _presets[i];
                      return ActionChip(
                        avatar: Text(p['icon']!, style: const TextStyle(fontSize: 12)),
                        label: Text(p['title']!, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        backgroundColor: isDark ? const Color(0xFF334155) : Colors.white,
                        side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        onPressed: () => _applyPreset(p['codeA']!, p['codeB']!),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ─── 2. Hàng chọn biển báo (Visual Slots) ───
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                for (final s in _selected)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _slotFilled(s, isDark),
                    ),
                  ),
                if (_selected.length < 3)
                  Expanded(
                    child: _slotEmpty(isDark),
                  ),
              ],
            ),
          ),

          // ─── 3. Nội dung so sánh chi tiết dạng Bảng trực quan ───
          Expanded(
            child: _selected.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.compare_arrows_rounded, size: 54, color: AppColors.muted),
                        const SizedBox(height: 12),
                        const Text(
                          'Chưa chọn biển báo nào để so sánh',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppColors.text2),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Bấm vào ô (+) hoặc chọn các cặp gợi ý ở trên',
                          style: TextStyle(fontSize: 12, color: AppColors.muted),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _pickSign,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Thêm biển báo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      _compareSection(
                        title: '🏷️ Tên & Phân nhóm',
                        isDark: isDark,
                        children: _selected.map((s) {
                          final gColor = _groupColor(s.nhomBien);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: gColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: gColor.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  s.nhomBien,
                                  style: TextStyle(color: gColor, fontWeight: FontWeight.w800, fontSize: 10.5),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                s.tenBien,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, height: 1.3),
                              ),
                            ],
                          );
                        }).toList(),
                      ),

                      _compareSection(
                        title: '💡 Ý nghĩa & Hiệu lực áp dụng',
                        isDark: isDark,
                        children: _selected.map((s) {
                          return Text(
                            s.yNghia.isEmpty ? '—' : s.yNghia,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.45,
                              color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                            ),
                          );
                        }).toList(),
                      ),

                      _compareSection(
                        title: '🏍️ Mức phạt xe máy',
                        isDark: isDark,
                        children: _selected.map((s) {
                          final isNoFine = s.mucPhatXeMay.toLowerCase().contains('không');
                          return Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isNoFine
                                  ? (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9))
                                  : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isNoFine
                                    ? Colors.transparent
                                    : const Color(0xFFFECACA),
                              ),
                            ),
                            child: Text(
                              s.mucPhatXeMay,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isNoFine ? AppColors.muted : const Color(0xFFDC2626),
                                height: 1.3,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      _compareSection(
                        title: '🚗 Mức phạt xe ô tô',
                        isDark: isDark,
                        children: _selected.map((s) {
                          final isNoFine = s.mucPhatOto.toLowerCase().contains('không');
                          return Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isNoFine
                                  ? (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9))
                                  : const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isNoFine
                                    ? Colors.transparent
                                    : const Color(0xFFFDE68A),
                              ),
                            ),
                            child: Text(
                              s.mucPhatOto,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isNoFine ? AppColors.muted : const Color(0xFFB45309),
                                height: 1.3,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      _compareSection(
                        title: '⚠️ Trừ điểm GPLX (Nghị định 168/2024)',
                        isDark: isDark,
                        children: _selected.map((s) {
                          final hasPoints = s.truDiemGPLX.toLowerCase().contains('điểm') &&
                              !s.truDiemGPLX.toLowerCase().contains('không');
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: hasPoints ? const Color(0xFFEEF2FF) : (isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC)),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: hasPoints ? const Color(0xFFC7D2FE) : Colors.transparent),
                            ),
                            child: Text(
                              s.truDiemGPLX,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: hasPoints ? const Color(0xFF4338CA) : AppColors.muted,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      _compareSection(
                        title: '⚖️ Căn cứ pháp lý',
                        isDark: isDark,
                        children: _selected.map((s) {
                          return Text(
                            s.canCuPhapLy.isEmpty ? 'QCVN 41:2019/BGTVT' : s.canCuPhapLy,
                            style: const TextStyle(fontSize: 11, color: AppColors.muted, fontStyle: FontStyle.italic),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _slotEmpty(bool isDark) {
    return GestureDetector(
      onTap: _pickSign,
      child: Container(
        height: 104,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 28),
            SizedBox(height: 4),
            Text(
              'Thêm biển',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slotFilled(TrafficSign s, bool isDark) {
    return Container(
      height: 104,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border.all(color: _groupColor(s.nhomBien).withValues(alpha: 0.4), width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Image.asset(
                    s.image,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.traffic_rounded, size: 36, color: AppColors.muted),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _groupColor(s.nhomBien).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  s.maBien,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: _groupColor(s.nhomBien),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: -2,
            right: -2,
            child: GestureDetector(
              onTap: () => _remove(s),
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compareSection({
    required String title,
    required List<Widget> children,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children
                .map((child) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: child,
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
  String? _selectedGroup;

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
    _filtered = widget.all.where((s) => !widget.excluding.contains(s)).toList();
  }

  void _applyFilter() {
    var list = DataService.search(widget.all, _ctrl.text)
        .where((s) => !widget.excluding.contains(s))
        .toList();
    if (_selectedGroup != null) {
      list = list.where((s) => s.nhomBien == _selectedGroup).toList();
    }
    setState(() => _filtered = list);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chọn biển báo để so sánh',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _ctrl,
              onChanged: (_) => _applyFilter(),
              decoration: InputDecoration(
                hintText: 'Tìm theo mã biển (P.101, W.205) hoặc tên...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ChoiceChip(
                    label: const Text('Tất cả', style: TextStyle(fontSize: 11)),
                    selected: _selectedGroup == null,
                    onSelected: (_) {
                      setState(() => _selectedGroup = null);
                      _applyFilter();
                    },
                  ),
                  const SizedBox(width: 6),
                  ..._groups.map((g) {
                    final isSel = _selectedGroup == g;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(g.replaceFirst('Biển ', '').replaceFirst('báo ', ''), style: const TextStyle(fontSize: 11)),
                        selected: isSel,
                        onSelected: (_) {
                          setState(() => _selectedGroup = g);
                          _applyFilter();
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(child: Text('Không tìm thấy biển báo nào phù hợp', style: TextStyle(color: AppColors.muted)))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _filtered.length,
                      itemBuilder: (context, i) {
                        final s = _filtered[i];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          leading: Container(
                            width: 44,
                            height: 44,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Image.asset(
                              s.image,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(Icons.traffic_rounded, size: 24, color: AppColors.muted),
                            ),
                          ),
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  s.maBien,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, color: Color(0xFF0D9488)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  s.tenBien,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            s.nhomBien,
                            style: const TextStyle(fontSize: 11, color: AppColors.muted),
                          ),
                          trailing: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 20),
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
