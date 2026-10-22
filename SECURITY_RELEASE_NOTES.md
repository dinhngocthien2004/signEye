# SignEye - cập nhật xác thực và thanh toán

- Đăng ký/đăng nhập bằng mật khẩu (tối thiểu 10 ký tự), token ngẫu nhiên, chỉ lưu hash token trong PostgreSQL.
- API tạo đơn, gửi xác nhận, xem đơn và quyền Pro yêu cầu Bearer token; email lấy từ phiên, không tin email client.
- Đơn được duyệt chỉ một lần nhờ UPDATE điều kiện và transaction; doanh thu chỉ tính đơn paid.
- Flutter gửi token và kiểm tra quyền Pro với backend khi khởi động.
- Admin dùng ADMIN_API_KEY ở server; tuyệt đối không nhúng vào Flutter.

## Hạn chế cần xử lý trước production

1. Chưa kiểm thử Dart/Flutter/PostgreSQL trong môi trường tạo bản này. Chạy `dart pub get`, `dart analyze`, `dart test` trong backend và `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build web` trong root.
2. Mật khẩu dùng SHA-256 lặp với salt, nên chuyển sang Argon2id hoặc PBKDF2 chuẩn với tham số kiểm định trước khi vận hành thật.
3. Chưa có rate limiting đăng nhập, chống brute-force, email verification, quên mật khẩu, CORS whitelist, bảo vệ token bằng secure storage và Admin login chuẩn. Các user cũ chưa có mật khẩu cần quy trình đặt mật khẩu an toàn.
4. Thanh toán là đối soát thủ công. Admin phải đối chiếu đúng số tiền, mã chuyển khoản, tài khoản nguồn và sao kê thật trước khi duyệt; không có webhook ngân hàng.
5. Kiểm tra HTTPS, cấu hình SSL PostgreSQL, secrets, backup và logs trên hạ tầng trước khi mở public. Backend Shelf chạy dài hạn, không được giả định deploy nguyên server trên Vercel Functions.
6. Các endpoint khác ngoài thanh toán cần audit quyền sở hữu dữ liệu, đặc biệt lịch sử và tính năng AI.
7. Cần kiểm tra lại khởi tạo quyền Pro khi offline; chỉ backend được xem là nguồn sự thật.

Không ghi mật khẩu, bearer token, API key hay thông tin ngân hàng vào log.
