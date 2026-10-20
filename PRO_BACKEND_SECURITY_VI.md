# Quyền Pro phía backend – phạm vi và giới hạn

- `/entitlements/pro` kiểm tra quyền Pro từ đơn đã duyệt, không tin trạng thái local.
- `/features/scan/consume` bắt buộc Bearer token, dùng transaction SQLite và hạn mức 5 lượt/ngày UTC cho Free; Pro không giới hạn.
- Flutter gọi API trước khi nhận diện, từ chối khi mất kết nối hoặc hết hạn mức.
- Lịch sử local vẫn có thể bị thay đổi trên thiết bị; không được dùng nó làm căn cứ phân quyền thương mại.

**Cảnh báo quan trọng:** Mô hình nhận diện hiện chạy từ Flutter với khóa AI và xử lý tại client. Người dùng sửa ứng dụng có thể bỏ qua bước gọi `/features/scan/consume`. Muốn bảo vệ **toàn diện**, phải đưa việc nhận diện AI vào backend, giữ khóa nhà cung cấp trên server, kiểm tra entitlement + quota và thực thi nhận diện trong cùng luồng server. Không thể khẳng định hoàn tất bảo vệ toàn bộ tính năng Pro ở phiên bản này.

Chưa kiểm thử Flutter trên thiết bị; không coi đây là bản phát hành thương mại.
