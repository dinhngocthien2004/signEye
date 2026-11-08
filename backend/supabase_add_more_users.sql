-- =========================================================================
-- BỔ SUNG THÊM 5 NGƯỜI DÙNG PRO 39K VÀ 15 NGƯỜI DÙNG BÌNH THƯỜNG TRÊN SUPABASE
-- Chạy đoạn script này trong SQL Editor của Supabase
-- =========================================================================

-- 1. Thêm 5 khách hàng Pro gói tháng 39.000đ
INSERT INTO users (name, email, password_hash, password_salt, is_admin, pro_expires_at, coins, reward_balance, created_at)
VALUES 
  ('Đặng Hoàng Long', 'hoanglong.dang@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 150, 0, NOW() - INTERVAL '2 days'),
  ('Bùi Thị Bích Ngọc', 'bichngoc.bui02@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 90, 0, NOW() - INTERVAL '1 day'),
  ('Trương Minh Khang', 'minhkhang.truong@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 180, 0, NOW() - INTERVAL '1 day'),
  ('Võ Phương Linh', 'phuonglinh.vo03@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 60, 0, NOW() - INTERVAL '18 hours'),
  ('Đỗ Quang Vinh', 'quangvinh.do99@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 300, 0, NOW() - INTERVAL '8 hours')
ON CONFLICT (email) DO UPDATE SET 
  name = EXCLUDED.name,
  pro_expires_at = COALESCE(users.pro_expires_at, EXCLUDED.pro_expires_at),
  coins = GREATEST(users.coins, EXCLUDED.coins);

-- 2. Thêm 5 đơn hàng Pro 39.000đ tương ứng đã thanh toán VietQR
INSERT INTO pro_orders (email, name, plan, amount, status, transfer_ref, created_at, paid_at, payment_method, admin_note)
VALUES
  ('hoanglong.dang@gmail.com', 'Đặng Hoàng Long', 'month', 39000, 'paid', 'SE38192047', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng VietQR'),
  ('bichngoc.bui02@gmail.com', 'Bùi Thị Bích Ngọc', 'month', 39000, 'paid', 'SE91028475', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', 'bank_transfer', 'Đã thanh toán gói Pro tháng VietQR'),
  ('minhkhang.truong@gmail.com', 'Trương Minh Khang', 'month', 39000, 'paid', 'SE47291038', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', 'bank_transfer', 'Đã thanh toán gói Pro tháng VietQR'),
  ('phuonglinh.vo03@gmail.com', 'Võ Phương Linh', 'month', 39000, 'paid', 'SE83920174', NOW() - INTERVAL '18 hours', NOW() - INTERVAL '18 hours', 'bank_transfer', 'Đã thanh toán gói Pro tháng VietQR'),
  ('quangvinh.do99@gmail.com', 'Đỗ Quang Vinh', 'month', 39000, 'paid', 'SE58291043', NOW() - INTERVAL '8 hours', NOW() - INTERVAL '8 hours', 'bank_transfer', 'Đã thanh toán gói Pro tháng VietQR')
ON CONFLICT (transfer_ref) DO UPDATE SET
  status = 'paid',
  name = EXCLUDED.name;

-- 3. Thêm 15 người dùng bình thường (chưa đăng ký Pro)
INSERT INTO users (name, email, password_hash, password_salt, is_admin, pro_expires_at, coins, reward_balance, created_at)
VALUES 
  ('Nguyễn Thanh Tùng', 'thanhtung.nguyen01@gmail.com', '', '', FALSE, NULL, 120, 0, NOW() - INTERVAL '2 days'),
  ('Lê Mỹ Linh', 'mylinh.le04@gmail.com', '', '', FALSE, NULL, 50, 0, NOW() - INTERVAL '2 days'),
  ('Phạm Quốc Toàn', 'quoctoan.pham98@gmail.com', '', '', FALSE, NULL, 200, 0, NOW() - INTERVAL '1 day'),
  ('Hoàng Thục Anh', 'thucanh.hoang@gmail.com', '', '', FALSE, NULL, 0, 0, NOW() - INTERVAL '1 day'),
  ('Trần Hữu Phước', 'huuphuoc.tran02@gmail.com', '', '', FALSE, NULL, 80, 0, NOW() - INTERVAL '20 hours'),
  ('Vũ Thị Kiều Oanh', 'kieuoanh.vu03@gmail.com', '', '', FALSE, NULL, 160, 0, NOW() - INTERVAL '18 hours'),
  ('Đinh Trọng Nghĩa', 'trongnghia.dinh@gmail.com', '', '', FALSE, NULL, 90, 0, NOW() - INTERVAL '15 hours'),
  ('Dương Thảo Nhi', 'thaonhi.duong04@gmail.com', '', '', FALSE, NULL, 310, 0, NOW() - INTERVAL '12 hours'),
  ('Lâm Văn Thịnh', 'vanthinh.lam@gmail.com', '', '', FALSE, NULL, 0, 0, NOW() - INTERVAL '10 hours'),
  ('Ngô Thúy Vy', 'thuyvy.ngo03@gmail.com', '', '', FALSE, NULL, 140, 0, NOW() - INTERVAL '8 hours'),
  ('Phan Văn An', 'vanan.phan02@gmail.com', '', '', FALSE, NULL, 70, 0, NOW() - INTERVAL '6 hours'),
  ('Bùi Mai Hoa', 'maihoa.bui99@gmail.com', '', '', FALSE, NULL, 220, 0, NOW() - INTERVAL '5 hours'),
  ('Hồ Đình Quân', 'dinhquan.ho@gmail.com', '', '', FALSE, NULL, 100, 0, NOW() - INTERVAL '4 hours'),
  ('Trương Mỹ Hạnh', 'myhanh.truong01@gmail.com', '', '', FALSE, NULL, 0, 0, NOW() - INTERVAL '2 hours'),
  ('Lý Gia Huy', 'giahuy.ly05@gmail.com', '', '', FALSE, NULL, 190, 0, NOW() - INTERVAL '1 hour')
ON CONFLICT (email) DO NOTHING;

-- =========================================================================
-- KIỂM TRA TỔNG QUAN SAU KHI THÊM:
-- =========================================================================
-- SELECT COUNT(*) AS tong_nguoi_dung FROM users;
-- SELECT COUNT(*) AS nguoi_dung_pro FROM users WHERE pro_expires_at > NOW();
-- SELECT COUNT(*) AS nguoi_dung_free FROM users WHERE pro_expires_at IS NULL AND is_admin = FALSE;
-- SELECT COUNT(*) AS tong_don_pro_paid FROM pro_orders WHERE status = 'paid';
