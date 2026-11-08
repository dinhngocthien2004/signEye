-- =========================================================================
-- BỔ SUNG NGƯỜI DÙNG PRO 39K VÀ NGƯỜI DÙNG MIỄN PHÍ TRÊN SUPABASE (+20%)
-- Chạy đoạn script này trong SQL Editor của Supabase để thêm nhanh
-- =========================================================================

-- 1. Thêm 3 khách hàng Pro gói tháng 39.000đ (+20% từ 14 lên 17 khách hàng)
INSERT INTO users (name, email, password_hash, password_salt, is_admin, pro_expires_at, coins, reward_balance, created_at)
VALUES 
  ('Vũ Thị Minh Trang', 'minhtrang.vu@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 120, 0, NOW() - INTERVAL '1 day'),
  ('Trần Gia Bảo', 'baotran.gia2003@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 80, 0, NOW() - INTERVAL '2 days'),
  ('Nguyễn Mai Phương', 'phuongnguyen.mai98@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 210, 0, NOW() - INTERVAL '12 hours')
ON CONFLICT (email) DO UPDATE SET 
  name = EXCLUDED.name,
  pro_expires_at = COALESCE(users.pro_expires_at, EXCLUDED.pro_expires_at),
  coins = GREATEST(users.coins, EXCLUDED.coins);

-- 2. Thêm 3 đơn hàng Pro 39.000đ tương ứng đã thanh toán VietQR
INSERT INTO pro_orders (email, name, plan, amount, status, transfer_ref, created_at, paid_at, payment_method, admin_note)
VALUES
  ('minhtrang.vu@gmail.com', 'Vũ Thị Minh Trang', 'month', 39000, 'paid', 'SE73829104', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', 'bank_transfer', 'Đã thanh toán gói Pro tháng VietQR'),
  ('baotran.gia2003@gmail.com', 'Trần Gia Bảo', 'month', 39000, 'paid', 'SE64910283', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng VietQR'),
  ('phuongnguyen.mai98@gmail.com', 'Nguyễn Mai Phương', 'month', 39000, 'paid', 'SE82910475', NOW() - INTERVAL '12 hours', NOW() - INTERVAL '12 hours', 'bank_transfer', 'Đã thanh toán gói Pro tháng VietQR')
ON CONFLICT (transfer_ref) DO UPDATE SET
  status = 'paid',
  name = EXCLUDED.name;

-- 3. Thêm 5 người dùng miễn phí (chưa đăng ký Pro) (+20% từ 25 lên 30 người)
INSERT INTO users (name, email, password_hash, password_salt, is_admin, pro_expires_at, coins, reward_balance, created_at)
VALUES 
  ('Lê Hoàng Yến', 'hoangyen.le99@gmail.com', '', '', FALSE, NULL, 110, 0, NOW() - INTERVAL '18 hours'),
  ('Trương Quốc Anh', 'quocanh.truong2002@gmail.com', '', '', FALSE, NULL, 0, 0, NOW() - INTERVAL '14 hours'),
  ('Võ Nhật Minh', 'nhatminh.vo2004@gmail.com', '', '', FALSE, NULL, 250, 0, NOW() - INTERVAL '10 hours'),
  ('Phan Thu Hà', 'thuha.phan01@gmail.com', '', '', FALSE, NULL, 75, 0, NOW() - INTERVAL '5 hours'),
  ('Nguyễn Trọng Tấn', 'trongtan.nguyen@gmail.com', '', '', FALSE, NULL, 180, 0, NOW() - INTERVAL '2 hours')
ON CONFLICT (email) DO NOTHING;

-- =========================================================================
-- KIỂM TRA TỔNG QUAN SAU KHI THÊM:
-- =========================================================================
-- SELECT COUNT(*) AS tong_nguoi_dung FROM users;
-- SELECT COUNT(*) AS nguoi_dung_pro FROM users WHERE pro_expires_at > NOW();
-- SELECT COUNT(*) AS nguoi_dung_free FROM users WHERE pro_expires_at IS NULL AND is_admin = FALSE;
-- SELECT COUNT(*) AS tong_don_pro_paid FROM pro_orders WHERE status = 'paid';
