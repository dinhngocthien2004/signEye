# SignEye – QR chuyển khoản duyệt thủ công

## Chạy backend + dashboard

```powershell
cd backend
python -m pip install -r requirements.txt
copy .env.example .env
# Thay ADMIN_API_KEY trong .env bằng chuỗi bí mật ngẫu nhiên dài >= 32 ký tự.
python -m uvicorn main:app --env-file .env --host 127.0.0.1 --port 8000
```

Mở **http://localhost:8000/admin** để vào dashboard, nhập `ADMIN_API_KEY` (chỉ lưu trong bộ nhớ tab). Backend sử dụng SQLite tại `backend/signeye.sqlite3` và tự tạo bảng. Nếu chạy trên server, dùng HTTPS, đặt sau reverse proxy và backup DB thường xuyên. Không đưa file `.env`, database, khóa admin lên Git.

Giá cố định từ `.env`: **39.000đ/tháng**, **399.000đ/năm**. VietQR: MB Bank BIN `970422`, số tài khoản `0000708578761`, tên người nhận `Lê Thị Hồng Duyên`. Mỗi đơn có mã nội dung riêng. Chỉ Admin được duyệt sau khi đối chiếu **số tiền, tài khoản nhận, nội dung chuyển khoản** trên ứng dụng ngân hàng. Chuyển khoản không được phát hiện tự động.

## Flutter

```powershell
cd ..
flutter pub get
flutter run --dart-define=PAYMENT_API_URL=http://10.0.2.2:8000
```

`10.0.2.2` dùng cho Android emulator, **không phải điện thoại thật**. Điện thoại thật cần API HTTPS công khai, ví dụ `--dart-define=PAYMENT_API_URL=https://api.example.com`. Dashboard là **web Admin** được phục vụ bởi backend, không nằm trong Flutter. Kiểm thử backend: `cd backend && python -m unittest test_payments.py`.

## API xác thực và thanh toán

- `POST /auth/register`: `{ "name":"...", "email":"...", "password":"..." }` (mật khẩu tối thiểu 10 ký tự).
- `POST /auth/login`: `{ "email":"...", "password":"..." }`, trả về bearer token.
- `POST /auth/logout`, `GET /me`: cần `Authorization: Bearer <token>`.
- `GET /config`: giá và thông tin nhận tiền.
- `POST /orders`: `{ "plan":"month|year" }` và bearer token. Email lấy từ phiên đăng nhập trên server.
- `GET /orders/{id}`: bearer token, chỉ chủ đơn mới xem được.
- `GET /admin/orders`, `GET /admin/stats?year=2026`: `X-Admin-Key`.
- `POST /admin/orders/{id}/approve|reject`: `X-Admin-Key`, JSON `{ "note":"..." }`.

## Phạm vi hoàn thành và lưu ý khi triển khai

Backend xác thực email + mật khẩu bằng PBKDF2, phiên opaque token 30 ngày lưu hash trong SQLite; duyệt đơn và thống kê hoạt động qua API. Flutter đã nối đăng nhập/đăng ký và màn thanh toán với API. Token hiện **chỉ giữ trong RAM**, nên cần đăng nhập lại sau khi đóng ứng dụng. Chức năng đổi xu thành Pro đã bị vô hiệu hóa để tránh tự cấp Pro ở phía client.

**Chưa đủ điều kiện triển khai production:** email đăng ký chưa được xác minh, chưa có khôi phục mật khẩu, giới hạn tốc độ/khóa tài khoản, audit log Admin bất biến, phân quyền Admin theo tài khoản, backup tự động, kiểm tra quyền Pro phía server cho toàn bộ tính năng premium, kiểm thử Flutter trên thiết bị và kiểm thử bảo mật độc lập. Những tính năng Flutter hoạt động offline vẫn có thể bị sửa bằng bản ứng dụng tùy biến; kiểm tra quyền ở client không thay thế xác thực server. Cần HTTPS bắt buộc và cấu hình CORS/reverse proxy an toàn khi public. Không in `.env`, mật khẩu, token, khóa Admin vào log. Thông tin tài khoản nhận tiền được hiển thị có chủ đích cho người mua trong QR.
