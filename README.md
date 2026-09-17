# SignEye (Flutter) — Tra cứu biển báo giao thông

Bản chuyển đổi sang **Flutter** của ứng dụng web `SignEye-Full-Complete-2026-v3-RealTrafficSigns`.
Toàn bộ dữ liệu (109 biển báo, ngân hàng câu hỏi thi GPLX, nội dung học lý thuyết,
cẩm nang lái xe, 119 ảnh biển báo thật) đã được giữ nguyên và chuyển sang JSON/asset
để dùng trực tiếp trong Flutter — không cần backend.

## Cách chạy dự án

Thư mục này chỉ chứa mã nguồn Dart (`lib/`), `pubspec.yaml` và `assets/` — chưa có
các thư mục nền tảng `android/`, `ios/`, `web/` (chúng khá nặng và được Flutter CLI
sinh tự động). Làm theo các bước sau:

```bash
# 1. Giải nén xong, vào thư mục dự án
cd signeye_flutter

# 2. Sinh thư mục android/ios/web (Flutter đã cài sẵn máy bạn)
flutter create . --project-name signeye_flutter --org com.signeye

# 3. Cài dependency
flutter pub get

# 4. Chạy thử (máy ảo hoặc thiết bị thật)
flutter run
```

> Yêu cầu Flutter SDK ≥ 3.22 (Dart ≥ 3.3). Kiểm tra bằng `flutter --version`.

### Quyền camera (Android/iOS)

Tính năng "Quét biển báo" dùng `image_picker` để chụp ảnh, cần khai báo quyền:

**Android** — thêm vào `android/app/src/main/AndroidManifest.xml` (trong thẻ `<manifest>`, trước `<application>`):
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
```

**iOS** — thêm vào `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Ứng dụng cần quyền camera để chụp ảnh biển báo và nhận diện.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Ứng dụng cần quyền thư viện ảnh để chọn ảnh biển báo.</string>
```

## Cấu trúc dự án

```text
lib/
├── main.dart                     # Điểm khởi động, chọn Auth/RootShell
├── theme.dart                    # Bảng màu teal (light/dark) giống bản web
├── models/                       # TrafficSign, ExamQuestion, LearningChapter, HandbookPost...
├── services/
│   ├── data_service.dart         # Đọc assets/data/*.json + tìm kiếm không dấu
│   ├── app_state.dart            # Đăng nhập, Free/Pro, lịch sử, quota quét, kết quả thi (SharedPreferences)
│   ├── tts_service.dart          # Đọc biển báo bằng giọng nói (flutter_tts)
│   └── sign_identify_service.dart# Gọi Gemini Vision để nhận diện mã biển từ ảnh
├── screens/                      # Auth, Home, Search, Scan, History, Account,
│                                   Learning (+chapter), Exam (home/take/result),
│                                   Handbook (+post detail), Compare
└── widgets/                      # sign_card, sign_detail_sheet (bottom sheet chi tiết biển)

assets/
├── data/                         # signs.json, exam.json, learning.json, handbook.json
│                                   (chuyển đổi 1:1 từ data.js/exam-data.js/... của bản web)
└── images/{guide,mandatory,prohibition,supplementary,warning}/*.jpg
                                    # 119 ảnh biển báo gốc, copy nguyên từ bản web
```

## Ánh xạ tính năng so với bản web

| Bản web (`public/*.js`)                | Bản Flutter                                              |
|-----------------------------------------|-----------------------------------------------------------|
| `index.html` 5-tab bottom nav            | `screens/root_shell.dart`                                  |
| `data.js` (109 biển, mức phạt)           | `assets/data/signs.json` + `models/traffic_sign.dart`      |
| Tìm kiếm / tra cứu trong `app.js`        | `screens/search_screen.dart` + `DataService.search`        |
| Nút 🔊 đọc biển báo (SpeechSynthesis)    | `services/tts_service.dart` (flutter_tts)                  |
| `api/identify.js` (Gemini Vision)        | `services/sign_identify_service.dart` (gọi thẳng từ máy)   |
| Lịch sử & giới hạn Free (localStorage)   | `services/app_state.dart` (SharedPreferences)               |
| `exam-data.js` + `screen-exam*`          | `screens/exam_home_screen.dart`, `exam_take_screen.dart`, `exam_result_screen.dart` |
| `learning-data.js` + `screen-learning`   | `screens/learning_screen.dart`                              |
| `handbook-data.js` + `screen-handbook*`  | `screens/handbook_screen.dart`, `handbook_post_screen.dart` |
| `screen-compare`                         | `screens/compare_screen.dart`                               |
| Modal thanh toán Pro (demo)              | Bottom sheet trong `screens/account_screen.dart`             |

## Giới hạn kỹ thuật cần biết (giống bản web)

- **Thanh toán**: màn hình nâng cấp Pro vẫn là **luồng demo trên thiết bị**, lưu trạng
  thái bằng `shared_preferences`, **chưa thu tiền thật**. Cần tích hợp cổng thanh toán
  thật + xác thực thuê bao từ server trước khi vận hành thương mại.
- **Nhận diện ảnh AI**: cần người dùng tự nhập **Gemini API Key** trong
  Tài khoản → "Gemini API Key (cho quét AI)". Khóa chỉ lưu cục bộ trên máy, gọi thẳng
  tới Google Generative Language API — không có backend trung gian như bản web gốc
  (`api/identify.js`). AI chỉ được dùng để nhận diện **mã biển báo**; toàn bộ ý nghĩa,
  mức phạt, trừ điểm, căn cứ pháp lý luôn lấy từ `assets/data/signs.json`, không để AI
  tự sinh ra dữ liệu pháp lý.
- **Dữ liệu pháp luật**: dữ liệu mức phạt/căn cứ pháp lý được giữ nguyên từ bản đóng gói
  gốc (tham chiếu Nghị định 168/2024/NĐ-CP và các sửa đổi liên quan) — cần người có
  chuyên môn rà soát trước khi phát hành chính thức, không tự động cập nhật.
- **Chế độ tối**: đã bật công tắc và đổi màu khung (AppBar/nút bấm/nền), nhưng phần lớn
  thẻ nội dung vẫn dùng bảng màu sáng cố định để giữ thời gian phát triển hợp lý — có
  thể mở rộng bằng cách thay các tham chiếu `AppColors.*` trong `screens/` bằng
  `Theme.of(context).colorScheme` nếu cần dark mode đầy đủ.
- **Giọng nói**: `flutter_tts` dùng giọng đọc hệ thống (`vi-VN`); chất lượng phụ thuộc
  vào giọng đọc tiếng Việt đã cài trên thiết bị/máy ảo.
