-- Schema adjustments
ALTER TABLE users ADD COLUMN IF NOT EXISTS coins INTEGER NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS reward_balance INTEGER NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS coin_redeem_note TEXT NOT NULL DEFAULT '';
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_coin_redeem_at TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE pro_orders ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE pro_orders ADD COLUMN IF NOT EXISTS payment_method TEXT NOT NULL DEFAULT 'bank_transfer';
ALTER TABLE pro_orders ADD COLUMN IF NOT EXISTS admin_note TEXT NOT NULL DEFAULT '';
ALTER TABLE pro_orders ADD COLUMN IF NOT EXISTS coins_used INTEGER NOT NULL DEFAULT 0;
ALTER TABLE pro_orders DROP CONSTRAINT IF EXISTS pro_orders_plan_check;
ALTER TABLE pro_orders DROP CONSTRAINT IF EXISTS pro_orders_status_check;

-- Seed Users (14 khách hàng Pro 39k + 25 khách hàng chưa đăng ký Pro)
INSERT INTO users (name, email, password_hash, password_salt, is_admin, pro_expires_at, coins, reward_balance, coin_redeem_note, created_at)
VALUES 
  -- 14 khách hàng Pro tháng (39.000đ)
  ('Nguyễn Quốc Huy', 'nguyenquochuy2k71508@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 0, 0, '', NOW() - INTERVAL '3 days'),
  ('Huỳnh Quang Cường', 'cuonghuynh2403@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 0, 0, '', NOW() - INTERVAL '3 days'),
  ('Nguyễn Hà Cao Kỳ', 'nguyenhacaoky@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 0, 0, '', NOW() - INTERVAL '2 days'),
  ('Lê Trà Gia Lộc', 'leloc2005qn@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 0, 0, '', NOW() - INTERVAL '1 day'),
  ('Trà Thị Mỹ Ngọc', 'tramyngoc1978@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 0, 0, '', NOW() - INTERVAL '1 day'),
  ('Lê Anh Đức', 'duclaqe180080@fpt.edu.vn', '', '', FALSE, NOW() + INTERVAL '30 days', 0, 0, '', NOW() - INTERVAL '2 days'),
  ('Phan Thị Thanh Ly', 'lyly1222005@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 0, 0, '', NOW() - INTERVAL '1 day'),
  ('Lê Trà Gia Hiếu', 'legiahieu27@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 0, 0, '', NOW() - INTERVAL '1 day'),
  ('Trần Đăng Khôi', 'khoitdqe170065@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 0, 0, '', NOW() - INTERVAL '1 day'),
  ('Cao Ngọc Ý', 'ycao123@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 0, 0, '', NOW() - INTERVAL '1 day'),
  ('Đinh Ngọc Thiện', 'dinhngocthien2004@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 2400, 0, '', NOW() - INTERVAL '4 days'),
  ('Hoàng Minh Tuấn', 'hoangminhtuan.hn@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 150, 0, '', NOW() - INTERVAL '2 days'),
  ('Trần Thị Phương Thảo', 'thaottp.sign@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 200, 0, '', NOW() - INTERVAL '2 days'),
  ('Phạm Đức Anh', 'ducanh.pham99@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 100, 0, '', NOW() - INTERVAL '3 days'),

  -- 25 người dùng chưa đăng ký Pro (Free)
  ('Lê Thị Hồng Duyên', 'hongduyen.le@signeye.vn', '', '', FALSE, NULL, 3100, 0, '', NOW() - INTERVAL '6 days'),
  ('Hoàng Văn Nam', 'namhoang2003@gmail.com', '', '', FALSE, NULL, 150, 0, '', NOW() - INTERVAL '6 days'),
  ('Vũ Thị Mai', 'maivu.dn99@gmail.com', '', '', FALSE, NULL, 50, 0, '', NOW() - INTERVAL '5 days'),
  ('Phạm Thành Đạt', 'datpham.qn2004@gmail.com', '', '', FALSE, NULL, 300, 0, '', NOW() - INTERVAL '5 days'),
  ('Đặng Thùy Dung', 'thuydungdang2k4@gmail.com', '', '', FALSE, NULL, 0, 0, '', NOW() - INTERVAL '4 days'),
  ('Bùi Quốc Bảo', 'baobui.fpt@fpt.edu.vn', '', '', FALSE, NULL, 450, 0, '', NOW() - INTERVAL '4 days'),
  ('Dương Minh Triết', 'trietduong2002@gmail.com', '', '', FALSE, NULL, 100, 0, '', NOW() - INTERVAL '4 days'),
  ('Đỗ Phương Thảo', 'thaodo.pt@gmail.com', '', '', FALSE, NULL, 200, 0, '', NOW() - INTERVAL '3 days'),
  ('Nguyễn Tuấn Kiệt', 'kietnguyen2005@gmail.com', '', '', FALSE, NULL, 80, 0, '', NOW() - INTERVAL '3 days'),
  ('Trịnh Văn Hùng', 'hungtrinh.dn@gmail.com', '', '', FALSE, NULL, 0, 0, '', NOW() - INTERVAL '3 days'),
  ('Lâm Hải Yến', 'haiyenlam.qn@gmail.com', '', '', FALSE, NULL, 120, 0, '', NOW() - INTERVAL '2 days'),
  ('Ngô Đình Phúc', 'phucngo.it@gmail.com', '', '', FALSE, NULL, 250, 0, '', NOW() - INTERVAL '2 days'),
  ('Mai Hoàng Long', 'longhoangmai@gmail.com', '', '', FALSE, NULL, 0, 0, '', NOW() - INTERVAL '2 days'),
  ('Lê Ngọc Khánh', 'khanhle.qe18@fpt.edu.vn', '', '', FALSE, NULL, 500, 0, '', NOW() - INTERVAL '2 days'),
  ('Phan Bích Trâm', 'bichtramphan@gmail.com', '', '', FALSE, NULL, 60, 0, '', NOW() - INTERVAL '1 day'),
  ('Võ Tiến Dũng', 'tiendungvo2003@gmail.com', '', '', FALSE, NULL, 180, 0, '', NOW() - INTERVAL '1 day'),
  ('Châu Anh Thư', 'anhthuchau@gmail.com', '', '', FALSE, NULL, 90, 0, '', NOW() - INTERVAL '1 day'),
  ('Tạ Quang Huy', 'quanghuyta.dn@gmail.com', '', '', FALSE, NULL, 0, 0, '', NOW() - INTERVAL '18 hours'),
  ('Đoàn Kim Ngân', 'ngandoankim@gmail.com', '', '', FALSE, NULL, 320, 0, '', NOW() - INTERVAL '12 hours'),
  ('Huỳnh Bá Thông', 'thonghuynhba@gmail.com', '', '', FALSE, NULL, 70, 0, '', NOW() - INTERVAL '8 hours'),
  ('Nguyễn Thị Hồng Ánh', 'honganhnguyen2004@gmail.com', '', '', FALSE, NULL, 0, 0, '', NOW() - INTERVAL '3 hours'),
  ('Vũ Hải Nam', 'namvu.tech@gmail.com', '', '', FALSE, NULL, 140, 0, '', NOW() - INTERVAL '2 hours'),
  ('Nguyễn Bảo Ngọc', 'baongoc.sign21@gmail.com', '', '', FALSE, NULL, 220, 0, '', NOW() - INTERVAL '2 hours'),
  ('Bùi Quang Huy', 'huybq.ptit@gmail.com', '', '', FALSE, NULL, 90, 0, '', NOW() - INTERVAL '1 hour'),
  ('Đỗ Thanh Hằng', 'thanhhang.do96@gmail.com', '', '', FALSE, NULL, 160, 0, '', NOW() - INTERVAL '1 hour')
ON CONFLICT (email) DO UPDATE SET 
  name = EXCLUDED.name,
  pro_expires_at = COALESCE(users.pro_expires_at, EXCLUDED.pro_expires_at),
  coins = GREATEST(users.coins, EXCLUDED.coins),
  coin_redeem_note = CASE WHEN EXCLUDED.coin_redeem_note != '' THEN EXCLUDED.coin_redeem_note ELSE users.coin_redeem_note END;

-- Seed Orders (14 đơn đã duyệt, mỗi đơn 39.000đ)
INSERT INTO pro_orders (email, name, plan, amount, status, transfer_ref, created_at, paid_at, payment_method, admin_note)
VALUES
  ('nguyenquochuy2k71508@gmail.com', 'Nguyễn Quốc Huy', 'month', 39000, 'paid', 'SE60471724', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('cuonghuynh2403@gmail.com', 'Huỳnh Quang Cường', 'month', 39000, 'paid', 'SE92771083', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('nguyenhacaoky@gmail.com', 'Nguyễn Hà Cao Kỳ', 'month', 39000, 'paid', 'SE56947789', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('leloc2005qn@gmail.com', 'Lê Trà Gia Lộc', 'month', 39000, 'paid', 'SE04815737', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('tramyngoc1978@gmail.com', 'Trà Thị Mỹ Ngọc', 'month', 39000, 'paid', 'SE05016739', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('duclaqe180080@fpt.edu.vn', 'Lê Anh Đức', 'month', 39000, 'paid', 'SE15753966', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('lyly1222005@gmail.com', 'Phan Thị Thanh Ly', 'month', 39000, 'paid', 'SE15501868', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('legiahieu27@gmail.com', 'Lê Trà Gia Hiếu', 'month', 39000, 'paid', 'SE1792943362849', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('khoitdqe170065@gmail.com', 'Trần Đăng Khôi', 'month', 39000, 'paid', 'SE1792943589777', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('ycao123@gmail.com', 'Cao Ngọc Ý', 'month', 39000, 'paid', 'SE1792943482387', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('dinhngocthien2004@gmail.com', 'Đinh Ngọc Thiện', 'month', 39000, 'paid', 'SE56477462', NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('hoangminhtuan.hn@gmail.com', 'Hoàng Minh Tuấn', 'month', 39000, 'paid', 'SE28471920', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('thaottp.sign@gmail.com', 'Trần Thị Phương Thảo', 'month', 39000, 'paid', 'SE91823746', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('ducanh.pham99@gmail.com', 'Phạm Đức Anh', 'month', 39000, 'paid', 'SE56192837', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng')
ON CONFLICT (transfer_ref) DO UPDATE SET
  status = EXCLUDED.status,
  paid_at = EXCLUDED.paid_at,
  name = EXCLUDED.name;
