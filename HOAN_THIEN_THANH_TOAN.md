# SignEye – quy trình thanh toán QR và xét duyệt

- Flutter/Dart giữ nguyên các màn hình gốc; gói tháng 39.000đ, gói năm 399.000đ.
- Tạo đơn và mã chuyển khoản độc nhất qua backend Dart/PostgreSQL; quét VietQR MB Bank.
- Sau chuyển khoản, nhấn **Gửi yêu cầu / kiểm tra thanh toán** để gửi yêu cầu cho Admin; nhấn lại để kiểm tra kết quả.
- Admin mở `/admin`, nhập `ADMIN_API_KEY` của backend, kiểm tra sao kê thật trước khi duyệt/từ chối.
- Chỉ đơn `paid` được ghi nhận doanh thu; cập nhật thời hạn Pro và trạng thái đơn trong cùng transaction PostgreSQL.
- Không in thông tin ngân hàng trong log ứng dụng. Không đưa ADMIN_API_KEY hoặc DB_PASSWORD vào Flutter.

## Cấu hình

Backend: cấu hình `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `ADMIN_API_KEY` (>=24 ký tự), `PORT` theo `backend/.env.example`; chạy `dart pub get` và `dart run bin/server.dart` trong `backend/`.

Flutter: `flutter pub get`, sau đó `flutter run --dart-define=SIGN_EYE_API_URL=https://TEN-MIEN-BACKEND`.

## Những giới hạn bảo mật quan trọng trước khi chạy production

**Chưa an toàn để thu tiền thật.** API người dùng hiện nhận email từ client mà chưa xác minh token đăng nhập; người khác có thể giả mạo email để tạo/đọc đơn hoặc xem quyền Pro. Trạng thái Pro còn được cache ở thiết bị và các cơ chế đổi xu của app gốc có thể tự cấp Pro. Admin đang dùng API key nhập trên trang web, chưa có phiên đăng nhập/RBAC. Cần tích hợp xác thực thực sự cho mọi endpoint, bắt buộc HTTPS, rate-limit, audit log xét duyệt, xác minh quyền Pro ở backend tại các tính năng trả phí và kiểm thử end-to-end. Không có kết nối sao kê ngân hàng tự động.

**Chưa kiểm thử được Flutter/Dart và PostgreSQL trong môi trường tạo file này.**
