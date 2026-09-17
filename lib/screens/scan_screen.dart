import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/traffic_sign.dart';
import '../services/app_state.dart';
import '../services/data_service.dart';
import '../services/sign_identify_service.dart';
import '../theme.dart';
import '../widgets/sign_detail_sheet.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _picked;
  bool _loading = false;
  IdentifyResult? _result;
  List<TrafficSign> _allSigns = [];

  @override
  void initState() {
    super.initState();
    DataService.instance.loadSigns().then((s) => setState(() => _allSigns = s));
  }

  Future<void> _pick(ImageSource source) async {
    final state = context.read<AppState>();
    if (!state.canScan) {
      _showUpsell();
      return;
    }
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, maxWidth: 1280, imageQuality: 85);
    if (file == null) return;
    setState(() {
      _picked = File(file.path);
      _result = null;
      _loading = true;
    });
    final bytes = await file.readAsBytes();
    final result = await SignIdentifyService.identify(
      imageBytes: bytes,
      apiKey: state.geminiApiKey,
      catalog: _allSigns,
    );
    await state.recordScan();
    setState(() {
      _result = result;
      _loading = false;
    });
    if (result.sign != null) {
      state.addHistory(result.sign!.maBien, source: 'scan');
    }
  }

  void _showUpsell() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đã hết lượt quét miễn phí'),
        content: const Text(
            'Gói Free cho phép quét tối đa 5 lần/ngày. Nâng cấp Pro để quét không giới hạn.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Để sau')),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nâng cấp Pro'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Quét biển báo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.primaryPale,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.isPro
                          ? 'Gói Pro · Quét không giới hạn'
                          : 'Gói Free · Còn ${state.scansRemainingToday}/${AppState.freeDailyScanLimit} lượt quét hôm nay',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.line),
                ),
                child: _picked == null
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.camera_alt_outlined, size: 46, color: AppColors.muted),
                            SizedBox(height: 10),
                            Text('Chụp hoặc chọn ảnh biển báo\nđể nhận diện bằng AI',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(_picked!, fit: BoxFit.cover, width: double.infinity),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Chụp ảnh'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Thư viện'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!_loading && _result != null) _buildResult(_result!),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(IdentifyResult result) {
    if (result.error != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.warningSoft, borderRadius: BorderRadius.circular(14)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.warning),
            const SizedBox(width: 10),
            Expanded(
                child: Text(result.error!,
                    style: const TextStyle(color: AppColors.warning, fontSize: 13, height: 1.4))),
          ],
        ),
      );
    }
    if (result.sign == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(14)),
        child: Text(
          'Không khớp được với biển nào trong cơ sở dữ liệu (mã AI trả về: '
          '${result.rawCode.isEmpty ? "không rõ" : result.rawCode}). Hãy thử ảnh rõ nét hơn hoặc tra cứu thủ công.',
          style: const TextStyle(fontSize: 13, color: AppColors.text2),
        ),
      );
    }
    final sign = result.sign!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Độ tin cậy: ${result.confidence}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.text2)),
            ],
          ),
          const SizedBox(height: 10),
          Text('${sign.maBien} · ${sign.tenBien}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 6),
          Text(sign.yNghia, style: const TextStyle(color: AppColors.text2, fontSize: 13, height: 1.4)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => showSignDetailSheet(context, sign, allSigns: _allSigns, source: 'scan'),
            child: const Text('Xem chi tiết mức phạt'),
          ),
        ],
      ),
    );
  }
}
