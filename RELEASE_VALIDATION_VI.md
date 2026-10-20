# Kiểm tra trước khi phát hành SignEye

## Đã bổ sung
- Dashboard Admin đăng nhập bằng mật khẩu băm PBKDF2; phiên 8 giờ, có logout và giới hạn số lần thử.
- API `/entitlements/pro` kiểm tra quyền Pro từ database và phiên người dùng.
- Mặc định vô hiệu hóa API key Admin dùng chung.
- Không đưa thông tin ngân hàng vào log ứng dụng.

## Thiết lập
1. `cd backend`, `pip install -r requirements.txt`.
2. Chạy `python create_admin_hash.py`, sao chép giá trị in ra vào `ADMIN_PASSWORD_HASH` trong `.env` (không commit `.env`).
3. Thiết lập thông tin MB Bank và giá trong `.env` như trước.
4. Chạy server sau reverse proxy HTTPS. Đặt `ALLOW_LEGACY_ADMIN_KEY=0`.

## Điều kiện chưa đạt để phát hành thương mại
- Chưa chạy build/test Flutter trên Android/iOS thật do môi trường không có Flutter SDK và thiết bị.
- Client vẫn có một số trạng thái/giới hạn quét thực thi cục bộ. Cần bảo vệ toàn bộ dịch vụ trả phí ở backend, không chỉ kiểm tra giao diện.
- Cần thay SQLite bằng PostgreSQL có migration, backup/restore và khóa giao dịch phù hợp đa instance.
- Cần xác minh email, khôi phục mật khẩu, xác thực Admin MFA, audit có định danh admin, kiểm thử bảo mật độc lập.
- Cần triển khai HTTPS, cấu hình secret manager, giám sát, điều khoản bán hàng, chính sách hoàn tiền, kiểm tra pháp lý/thuế.
- Đối chiếu chuyển khoản thực tế vẫn là thủ công; không tự động coi lời khai của người mua là đã thanh toán.

## Kiểm thử thiết bị cần thực hiện
`flutter doctor -v`; `flutter pub get`; `flutter analyze`; `flutter test`; `flutter devices`; `flutter run --release --dart-define=PAYMENT_API_URL=https://your-api.example`.
Kiểm tra Android/iOS: đăng ký, đăng nhập, quét QR, đơn chờ duyệt, Admin duyệt, đồng bộ Pro, đăng xuất, mất mạng, hết hạn Pro, mua gia hạn, từ chối và hoàn tiền.
