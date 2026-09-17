class VisualFeatures {
  final String shape;
  final String background;
  final String border;
  final String symbol;
  final String orientation;

  VisualFeatures({
    required this.shape,
    required this.background,
    required this.border,
    required this.symbol,
    required this.orientation,
  });

  factory VisualFeatures.fromJson(Map<String, dynamic>? json) {
    json ??= const {};
    return VisualFeatures(
      shape: json['shape']?.toString() ?? '',
      background: json['background']?.toString() ?? '',
      border: json['border']?.toString() ?? '',
      symbol: json['symbol']?.toString() ?? '',
      orientation: json['orientation']?.toString() ?? '',
    );
  }
}

/// Mirrors an entry from the original `public/data.js` (BIEN_BAO_DATA).
class TrafficSign {
  final int stt;
  final String maBien; // sign code, e.g. "P.101"
  final String tenBien; // sign name
  final String nhomBien; // sign group (cấm / nguy hiểm / hiệu lệnh / chỉ dẫn / phụ)
  final String yNghia; // meaning
  final String mucPhatXeMay; // fine for motorbikes
  final String mucPhatOto; // fine for cars
  final String truDiemGPLX; // whether license points are deducted
  final String canCuPhapLy; // legal basis
  final String keywords;
  final String image; // relative asset path (already normalized to assets/images/...)
  final VisualFeatures visualFeatures;
  final List<String> similarSigns;

  TrafficSign({
    required this.stt,
    required this.maBien,
    required this.tenBien,
    required this.nhomBien,
    required this.yNghia,
    required this.mucPhatXeMay,
    required this.mucPhatOto,
    required this.truDiemGPLX,
    required this.canCuPhapLy,
    required this.keywords,
    required this.image,
    required this.visualFeatures,
    required this.similarSigns,
  });

  factory TrafficSign.fromJson(Map<String, dynamic> json) {
    final rawImage = json['image']?.toString() ?? '';
    final normalized = rawImage.replaceFirst('/assets/trafficSigns/', 'assets/images/');
    return TrafficSign(
      stt: json['stt'] is int ? json['stt'] as int : int.tryParse('${json['stt']}') ?? 0,
      maBien: json['maBien']?.toString() ?? '',
      tenBien: json['tenBien']?.toString() ?? '',
      nhomBien: json['nhomBien']?.toString() ?? '',
      yNghia: json['yNghia']?.toString() ?? '',
      mucPhatXeMay: json['mucPhatXeMay']?.toString() ?? '',
      mucPhatOto: json['mucPhatOto']?.toString() ?? '',
      truDiemGPLX: json['truDiemGPLX']?.toString() ?? '',
      canCuPhapLy: json['canCuPhapLy']?.toString() ?? '',
      keywords: json['keywords']?.toString() ?? '',
      image: normalized,
      visualFeatures: VisualFeatures.fromJson(json['visualFeatures'] as Map<String, dynamic>?),
      similarSigns: (json['similarSigns'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  /// A voice-friendly summary used by text-to-speech, mirroring the
  /// "read aloud" button behaviour from the original web app.
  String get speechText =>
      'Biển $maBien, $tenBien. $yNghia. Mức phạt xe máy: $mucPhatXeMay. '
      'Mức phạt ô tô: $mucPhatOto.';
}
