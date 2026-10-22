# Rà soát an toàn thanh toán SignEye

## Đã sửa trong bản này
- Khóa các phương thức Flutter tự cấp Pro qua nâng cấp trực tiếp hoặc đổi xu.
- Không tin cờ Pro lưu trên máy khi khởi động.
- Ghi nhật ký phê duyệt/từ chối đơn trong cùng transaction với thay đổi trạng thái; không ghi số tài khoản vào audit.
- Đơn chỉ được duyệt khi đã gửi yêu cầu và chỉ duyệt một lần; thống kê doanh thu chỉ lấy đơn `paid`.

## Chặn triển khai thu tiền thật (chưa hoàn thành)
- Đăng nhập Flutter hiện chỉ nhập email, không xác thực mật khẩu; các API thanh toán dựa trên email tự khai. Người khác có thể giả danh email.
- API `/users` và `/history` chưa có xác thực và phân quyền.
- `ADMIN_API_KEY` nhập trong trang Admin chưa phải cơ chế phiên đăng nhập/RBAC hoàn chỉnh.
- Backend PostgreSQL hiện `useSSL: false`; cần cấu hình TLS cho môi trường production.
- Chưa có rate limiting, chống dò đoán, quản lý session, xác minh quyền Pro cho mọi tính năng trả phí từ server.
- Chưa kiểm thử Dart/Flutter/PostgreSQL end-to-end trong môi trường hiện tại.

**Không triển khai thu tiền thật trước khi khắc phục các điểm chặn trên.**
