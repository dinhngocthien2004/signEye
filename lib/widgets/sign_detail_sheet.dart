import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/traffic_sign.dart';
import '../services/app_state.dart';
import '../services/tts_service.dart';
import '../theme.dart';

/// Shows a sign's full detail (image, meaning, fines, legal basis, similar
/// signs) as a modal bottom sheet — mirroring `.modal-overlay`/`.modal-sheet`
/// and the "🔊 read aloud" button from the original web app.
Future<void> showSignDetailSheet(
  BuildContext context,
  TrafficSign sign, {
  List<TrafficSign> allSigns = const [],
  String source = 'search',
}) {
  context.read<AppState>().addHistory(sign.maBien, source: source);
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SignDetailSheet(sign: sign, allSigns: allSigns),
  );
}

class _SignDetailSheet extends StatelessWidget {
  final TrafficSign sign;
  final List<TrafficSign> allSigns;

  const _SignDetailSheet({required this.sign, required this.allSigns});

  @override
  Widget build(BuildContext context) {
    final similar = allSigns.where((s) => sign.similarSigns.contains(s.maBien)).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        sign.image,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.image_not_supported_outlined, color: AppColors.muted),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPale,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(sign.maBien,
                              style: const TextStyle(
                                  color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 12)),
                        ),
                        const SizedBox(height: 6),
                        Text(sign.tenBien,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                        const SizedBox(height: 2),
                        Text(sign.nhomBien,
                            style: const TextStyle(color: AppColors.text2, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => TtsService.instance.speak(sign.speechText),
                    icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
                    style: IconButton.styleFrom(backgroundColor: AppColors.primaryPale),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _sectionTitle('Ý nghĩa'),
              _sectionBody(sign.yNghia),
              const SizedBox(height: 14),
              _sectionTitle('Mức phạt'),
              _fineRow('Xe máy', sign.mucPhatXeMay),
              const SizedBox(height: 6),
              _fineRow('Ô tô', sign.mucPhatOto),
              const SizedBox(height: 6),
              _fineRow('Trừ điểm GPLX', sign.truDiemGPLX),
              const SizedBox(height: 14),
              _sectionTitle('Căn cứ pháp lý'),
              _sectionBody(sign.canCuPhapLy),
              if (similar.isNotEmpty) ...[
                const SizedBox(height: 18),
                _sectionTitle('Biển dễ nhầm lẫn'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: similar.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final s = similar[i];
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          showSignDetailSheet(context, s, allSigns: allSigns, source: 'search');
                        },
                        child: Container(
                          width: 78,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surface2,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: Image.asset(s.image,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, size: 20)),
                              ),
                              const SizedBox(height: 4),
                              Text(s.maBien,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String text) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.text));

  Widget _sectionBody(String text) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(text.isEmpty ? '—' : text,
            style: const TextStyle(color: AppColors.text2, fontSize: 13.5, height: 1.5)),
      );

  Widget _fineRow(String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: AppColors.text2, fontSize: 13)),
          ),
          Expanded(
            child: Text(value.isEmpty ? '—' : value,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ],
      );
}
