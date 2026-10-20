# SignEye — đánh giá trước phát hành thương mại

## Đã thêm trong bản này
- Backend từ chối khởi động production nếu thiếu cấu hình trọng yếu, dùng khóa Admin cũ hoặc chưa chỉ định vị trí lưu DB bền vững.
- TrustedHostMiddleware giới hạn hostname production; thêm HSTS (chỉ khi triển khai HTTPS qua reverse proxy), Permissions-Policy và các security headers hiện có.
- Mẫu cấu hình production; tuyệt đối không commit file .env thật, token, mật khẩu hoặc thông tin giao dịch riêng tư.

## Chặn phát hành — bắt buộc thực hiện
1. Chuyển nhận diện AI từ thiết bị sang endpoint backend thực hiện **chính thao tác AI** sau khi xác thực và kiểm tra quota trong cùng giao dịch. Endpoint /features/scan/consume hiện chỉ cấp lượt, không ngăn app đã chỉnh sửa chạy AI cục bộ.
2. Kiểm tra và chuyển toàn bộ chức năng Pro còn xử lý local sang backend; loại bỏ bất kỳ đường nâng cấp Pro cục bộ nào.
3. Đưa database lên PostgreSQL được sao lưu và có migration; SQLite hiện chỉ thích hợp một instance có volume bền vững, không phù hợp scale-out.
4. Dùng Redis/shared store để rate limit đa instance; thêm chống brute-force phân tán, giám sát và cảnh báo.
5. Admin cần MFA, phân quyền theo vai trò, CSRF/cookie security nếu chuyển sang session cookie; review XSS/CSP (dashboard hiện còn inline script).
6. Xác minh email, khôi phục mật khẩu an toàn, quy trình xóa dữ liệu/tài khoản, chính sách riêng tư và điều khoản bán hàng.
7. Chạy flutter analyze/test/build và test trên thiết bị Android/iOS thật; test payment end-to-end trên máy chủ HTTPS và kiểm tra hoàn tiền/gia hạn.
8. Pentest độc lập, backup/restore drill, giám sát, log redaction, bảo vệ dữ liệu cá nhân và quy định hóa đơn/thuế liên quan.
9. Admin **phải đối chiếu tiền thực nhận, số tiền, mã nội dung chuyển khoản và mã tham chiếu** trên ngân hàng trước khi duyệt. Backend không thể tự xác minh số tiền thực nhận bằng QR tĩnh.

## Kết luận
**CHƯA ĐẠT điều kiện phát hành thương mại.** Các thay đổi trong bản này là tăng cường an toàn, không phải chứng nhận an ninh hay kiểm thử thiết bị. Không nhận thanh toán thật trước khi hoàn tất các mục chặn phát hành.
