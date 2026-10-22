# SignEye Pro — QR và thống kê

- Frontend và backend đều dùng Dart; dữ liệu lưu PostgreSQL trong bảng `pro_orders`.
- Backend: cấu hình `ADMIN_API_KEY` bí mật trong môi trường server, `PORT` tùy chọn. Chạy từ thư mục backend bằng `dart pub get && dart run lib/server.dart` (yêu cầu PostgreSQL như cấu hình trong database.dart).
- Flutter web: cấu hình lúc build với `--dart-define=SIGN_EYE_API_URL=https://YOUR_API_HOST --dart-define=VIETQR_BANK_ID=9704xx --dart-define=VIETQR_ACCOUNT_NO=YOUR_ACCOUNT --dart-define=VIETQR_ACCOUNT_NAME=YOUR_NAME`. Dùng mã BIN ngân hàng tương thích VietQR và số tài khoản ngân hàng thật; không dùng tài khoản ví MoMo như số tài khoản ngân hàng VietQR nếu chưa xác minh hỗ trợ.
- POST `/payments/orders` JSON `{ "email":"buyer@example.com", "plan":"month" }` hoặc `year`: tạo đơn pending, giá do server ấn định.
- GET `/payments/orders/{id}?email=...`: kiểm tra trạng thái đơn. Không có quyền tự xác nhận thanh toán từ phía khách.
- GET `/admin/payments` với header `x-admin-key: <ADMIN_API_KEY>`: thống kê số người mua duy nhất, số giao dịch, số gói tháng/năm, doanh thu, và 200 đơn mới nhất.
- POST `/admin/payments/{id}/confirm` cùng header: Admin xác nhận đơn sau khi **kiểm tra sao kê thực tế**. KHÔNG xác nhận chỉ vì khách gửi ảnh hoặc bấm nút.

**Giới hạn cần hoàn thiện trước khi kinh doanh:** Chưa tích hợp webhook xác thực chữ ký từ ngân hàng/cổng thanh toán, chưa có giao diện Admin, chưa có hệ thống đăng nhập/token server xác minh chủ sở hữu đơn, và trạng thái Pro vẫn được lưu cục bộ sau khi kiểm tra đơn (có thể bị giả mạo). Cần chuyển quyền Pro sang server và đồng bộ hạn sử dụng, thay khóa admin tĩnh bằng đăng nhập phân quyền, thêm CORS và cấu hình PostgreSQL qua biến môi trường để triển khai production. Đây là bản tích hợp luồng QR + ghi đơn + báo cáo bước đầu, không phải hệ thống thanh toán production-ready.
