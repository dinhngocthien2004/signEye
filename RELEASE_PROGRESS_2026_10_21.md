# SignEye – Tiến độ hoàn thiện phát hành (21/10/2026)

## Thay đổi lần này
- Admin chỉ có thể duyệt đơn nếu nhập/đối chiếu **đúng số tiền** và **nội dung chuyển khoản** với đơn đang chờ; giao dịch ngân hàng vẫn cần kiểm tra thủ công.
- Mã tham chiếu ngân hàng được ràng buộc duy nhất, tránh sử dụng cho hai đơn.
- Sửa lỗi Flutter trừ lượt quét khi người dùng hủy chọn ảnh: chỉ gọi API ghi nhận lượt sau khi đã chọn ảnh.
- Bổ sung `/ready` kiểm tra kết nối SQLite và index phục vụ báo cáo.
- Kiểm thử tích hợp backend: `cd backend && python -m unittest discover -v`.

## Chưa đủ điều kiện công bố sẵn sàng thương mại
1. AI nhận diện vẫn thực thi ở client; cần đưa xử lý thực sự lên backend, không chỉ API `consume`.
2. Backend SQLite chưa phải cấu hình HA/multi-instance; cần PostgreSQL, migration, backup/restore và kiểm thử khôi phục.
3. Chưa có MFA cho Admin, xác minh email, quy trình quên mật khẩu và quản lý thiết bị.
4. Chưa chạy Flutter SDK trên Android/iOS thật, kiểm thử release build, ký ứng dụng, chính sách bảo mật và quy trình phát hành cửa hàng.
5. Chưa kiểm thử độc lập về bảo mật, tải, gián đoạn mạng, đối soát sao kê ngân hàng thực tế.

**Không được coi việc Admin nhập đúng số tiền/mã đơn là bằng chứng ngân hàng đã nhận tiền.** Admin phải tự kiểm tra giao dịch đã ghi có và mã tham chiếu trên kênh ngân hàng tin cậy.

## Chạy test
```bash
cd backend
pip install -r requirements.txt
pip install httpx
python -m unittest discover -v
```
