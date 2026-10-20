# SignEye — Hướng dẫn triển khai và giới hạn an toàn

## Thanh toán
- Gói tháng: 39.000 VNĐ; gói năm: 399.000 VNĐ.
- VietQR MB Bank (`BANK_ID=970422`) với nội dung chuyển khoản riêng cho từng đơn.
- **Không tự động xác minh tiền về.** Admin phải mở ứng dụng ngân hàng, đối chiếu số tiền, mã đơn, người nhận và mã tham chiếu giao dịch trước khi duyệt.
- Mã tham chiếu ngân hàng chỉ dùng được một lần trên toàn hệ thống; không thể duyệt lại đơn đã xử lý.
- Số liệu doanh thu chỉ tính đơn được duyệt. Số người mua là số tài khoản khác nhau.

## Chạy backend
```sh
cd backend
python -m venv .venv
# Windows: .venv\\Scripts\\activate
pip install -r requirements.txt
cp .env.example .env  # Windows: copy .env.example .env
# Sửa ADMIN_API_KEY thành chuỗi ngẫu nhiên dài, giữ file .env ngoài Git
python -m uvicorn main:app --env-file .env --host 127.0.0.1 --port 8000
python -m unittest test_payments.py
```
Dashboard: http://127.0.0.1:8000/admin

## Chạy Flutter
```sh
flutter pub get
flutter run --dart-define=PAYMENT_API_URL=http://10.0.2.2:8000
```
Android emulator sử dụng 10.0.2.2; máy thật cần địa chỉ backend mà máy truy cập được. Production bắt buộc HTTPS.

## Cần làm trước khi bán thật
1. Xác thực email, khôi phục mật khẩu an toàn, xác thực nhiều yếu tố cho admin.
2. Chuyển quản trị từ khóa API dùng chung sang tài khoản admin, session HttpOnly, CSRF protection, phân quyền và audit theo từng nhân viên.
3. Dùng PostgreSQL, migrations, sao lưu/khôi phục, rate limiting dùng Redis cho nhiều instance.
4. Kiểm tra quyền Pro phía server ở **mọi** API trả phí; trạng thái hiển thị Flutter không phải bằng chứng quyền truy cập.
5. Kiểm thử Flutter trên Android/iOS thật, kiểm tra thanh toán sai số tiền, chuyển trùng, hoàn tiền, đối soát kế toán.
6. Không ghi token, mật khẩu, số tài khoản hoặc QR URL vào log; kiểm tra cấu hình log reverse proxy/CDN.
7. Bật HTTPS, quản lý secrets và kiểm tra bảo mật trước phát hành.

**Trạng thái:** bản phát triển có luồng thanh toán thủ công, không được xác nhận đủ điều kiện vận hành thương mại.
