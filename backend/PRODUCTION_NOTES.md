# SignEye — QR / Admin

Gói tháng 39.000 VND; gói năm 399.000 VND. MB Bank (BIN VietQR 970422). Thông tin tài khoản hiển thị trên màn hình thanh toán là thông tin người nhận, không phải bí mật xác thực. Không log số tài khoản, tên người nhận, mật khẩu database hoặc ADMIN_API_KEY.

Chạy PostgreSQL, đặt DB_* và ADMIN_API_KEY (ít nhất 24 ký tự ngẫu nhiên) trong môi trường server; chạy `cd backend && dart pub get && dart run bin/server.dart`. Truy cập `/admin` qua HTTPS, nhập khóa quản trị. KHÔNG đặt ADMIN_API_KEY vào Flutter hoặc Vercel public environment. Backend cần host riêng hỗ trợ Dart runtime/PostgreSQL, không phải static Flutter deployment.

Đây là quy trình xác nhận thủ công: Admin phải đối chiếu giao dịch thật trong sao kê trước khi xác nhận. Chưa có webhook ngân hàng.

**Chưa đủ điều kiện production:** API tạo đơn vẫn dựa trên email tự khai, quyền Pro lưu ở Flutter client, endpoint /users và /history hiện chưa có xác thực. Cần xác thực tài khoản phía server, quyền Pro server-side, giới hạn tần suất, kiểm tra quyền truy cập history/users, và tích hợp đối soát giao dịch có chữ ký trước khi mở bán thực tế.
