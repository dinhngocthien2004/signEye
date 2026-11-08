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

-- Seed Users (Tổng: 94 người dùng - 38 Pro, 56 Miễn phí, 14 tài khoản đã đổi Pro bằng xu)
INSERT INTO users (name, email, password_hash, password_salt, is_admin, pro_expires_at, coins, reward_balance, coin_redeem_note, created_at)
VALUES 
  -- 8 tài khoản Pro ban đầu
  ('Lê Trà Gia Lộc', 'leloc2005qn@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 500, 0, '', NOW() - INTERVAL '1 day'),
  ('Trà Thị Mỹ Ngọc', 'tramyngoc1978@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 300, 0, '', NOW() - INTERVAL '1 day'),
  ('Lê Anh Đức', 'duclaqe180080@fpt.edu.vn', '', '', FALSE, NOW() + INTERVAL '30 days', 850, 0, '', NOW() - INTERVAL '2 days'),
  ('Nguyễn Hà Cao Kỳ', 'nguyenhacaoky@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 600, 0, '', NOW() - INTERVAL '2 days'),
  ('Huỳnh Quang Cường', 'cuonghuynh2403@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 450, 0, '', NOW() - INTERVAL '3 days'),
  ('Nguyễn Quốc Huy', 'nguyenquochuy2k71508@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 700, 0, '', NOW() - INTERVAL '3 days'),
  ('Đinh Ngọc Thiện', 'dinhngocthien2004@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 2400, 0, '', NOW() - INTERVAL '4 days'),
  ('Lê Thị Hồng Duyên', 'hongduyen.le@signeye.vn', '', '', FALSE, NOW() + INTERVAL '30 days', 3100, 0, '', NOW() - INTERVAL '5 days'),

  -- 16 tài khoản Pro tiếp theo
  ('Hoàng Minh Tuấn', 'hoangminhtuan.hn@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 800, 0, '', NOW() - INTERVAL '5 days'),
  ('Trần Thị Phương Thảo', 'thaottp.sign@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 650, 0, '', NOW() - INTERVAL '6 days'),
  ('Phạm Đức Anh', 'ducanh.pham99@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 900, 0, '', NOW() - INTERVAL '6 days'),
  ('Vũ Hải Nam', 'namvu.tech@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 750, 0, '', NOW() - INTERVAL '7 days'),
  ('Nguyễn Bảo Ngọc', 'baongoc.sign21@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 850, 0, '', NOW() - INTERVAL '7 days'),
  ('Đặng Thùy Dung', 'thuydung.dang88@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 700, 0, '', NOW() - INTERVAL '8 days'),
  ('Bùi Quang Huy', 'huybq.ptit@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 950, 0, '', NOW() - INTERVAL '8 days'),
  ('Đỗ Thanh Hằng', 'thanhhang.do96@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 800, 0, '', NOW() - INTERVAL '9 days'),
  ('Ngô Minh Quân', 'minhquan.ngo@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 600, 0, '', NOW() - INTERVAL '9 days'),
  ('Phan Anh Khoa', 'khoapa.danang@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 750, 0, '', NOW() - INTERVAL '10 days'),
  ('Trịnh Hoài An', 'hoaian.trinh@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 850, 0, '', NOW() - INTERVAL '10 days'),
  ('Mai Phương Linh', 'linhmp.edu@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 700, 0, '', NOW() - INTERVAL '11 days'),
  ('Lý Gia Hân', 'giahan.ly@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 800, 0, '', NOW() - INTERVAL '11 days'),
  ('Võ Quốc Tuấn', 'voquoctuan2002@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 650, 0, '', NOW() - INTERVAL '12 days'),
  ('Dương Thúy Kiều', 'thuykieu.duong@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 900, 0, '', NOW() - INTERVAL '12 days'),
  ('Lâm Hoài Nam', 'lamhoainam.sign@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 750, 0, '', NOW() - INTERVAL '13 days'),

  -- 14 tài khoản Pro đã đổi bằng xu (tổng cộng 8 + 16 + 14 = 38 Pro users)
  ('Tạ Đình Phong', 'dinhphong.ta@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 1200, 0, 'Đã đổi 1 tháng Pro từ xu tích lũy (39.000đ / 390 xu)', NOW() - INTERVAL '13 days'),
  ('Đoàn Nhật Minh', 'nhatminh.doan@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 1150, 0, 'Đã đổi 1 tháng Pro từ xu tích lũy (39.000đ / 390 xu)', NOW() - INTERVAL '14 days'),
  ('Hồ Quỳnh Nga', 'quynhnga.ho@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 1300, 0, 'Đã đổi 1 tháng Pro từ xu tích lũy (39.000đ / 390 xu)', NOW() - INTERVAL '14 days'),
  ('Trương Trọng Nghĩa', 'nghiatruong.fpt@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 1100, 0, 'Đã đổi 1 tháng Pro từ xu tích lũy (39.000đ / 390 xu)', NOW() - INTERVAL '15 days'),
  ('Đinh Gia Bảo', 'giabao.dinh@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 1250, 0, 'Đã đổi 1 tháng Pro từ xu tích lũy (39.000đ / 390 xu)', NOW() - INTERVAL '15 days'),
  ('Cao Thị Bích Ngọc', 'bichngoc.cao@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 1400, 0, 'Đã đổi 1 tháng Pro từ xu tích lũy (39.000đ / 390 xu)', NOW() - INTERVAL '16 days'),
  ('Châu Khải Phong', 'khaiphong.chau@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 1150, 0, 'Đã đổi 1 tháng Pro từ xu tích lũy (39.000đ / 390 xu)', NOW() - INTERVAL '16 days'),
  ('Lương Triều Vĩ', 'trieuviluong@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 1350, 0, 'Đã đổi 1 tháng Pro từ xu tích lũy (39.000đ / 390 xu)', NOW() - INTERVAL '17 days'),
  ('Văn Đình Dũng', 'van.dinhdung@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 1200, 0, 'Đã đổi 1 tháng Pro từ xu tích lũy (39.000đ / 390 xu)', NOW() - INTERVAL '17 days'),
  ('Tô Hoài Bảo', 'hoaibao.to@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 1100, 0, 'Đã đổi 1 tháng Pro từ xu tích lũy (39.000đ / 390 xu)', NOW() - INTERVAL '18 days'),
  ('Chu Khánh Huyền', 'khanhhuyen.chu@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 1300, 0, 'Đã đổi 1 tháng Pro từ xu tích lũy (39.000đ / 390 xu)', NOW() - INTERVAL '18 days'),
  ('Quách Tuấn Du', 'tuandu.quach@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 1250, 0, 'Đã đổi 1 tháng Pro từ xu tích lũy (39.000đ / 390 xu)', NOW() - INTERVAL '19 days'),
  ('Thân Trọng Phúc', 'trongphuc.than@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 1150, 0, 'Đã đổi 1 tháng Pro từ xu tích lũy (39.000đ / 390 xu)', NOW() - INTERVAL '19 days'),
  ('Thái Thị Mỹ Linh', 'mylinh.thai@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 1400, 0, 'Đã đổi 1 tháng Pro từ xu tích lũy (39.000đ / 390 xu)', NOW() - INTERVAL '20 days'),

  -- 56 Người dùng Thường (Miễn phí) -> Tổng cộng: 38 + 56 = 94 người dùng
  ('Nghiêm Xuân Mạnh', 'xuanmanh.nghiem@gmail.com', '', '', FALSE, NULL, 450, 0, '', NOW() - INTERVAL '2 days'),
  ('Tạ Quốc Bảo', 'quocbao.ta@gmail.com', '', '', FALSE, NULL, 500, 0, '', NOW() - INTERVAL '2 days'),
  ('Lưu Đình Triệu', 'dinhtrieu.luu@gmail.com', '', '', FALSE, NULL, 350, 0, '', NOW() - INTERVAL '3 days'),
  ('Phùng Thanh Độ', 'do.phungthanh@gmail.com', '', '', FALSE, NULL, 600, 0, '', NOW() - INTERVAL '3 days'),
  ('Tiêu Thục Trinh', 'thuctrinh.tieu@gmail.com', '', '', FALSE, NULL, 400, 0, '', NOW() - INTERVAL '4 days'),
  ('Đào Văn Nam', 'namdv.signeye@gmail.com', '', '', FALSE, NULL, 550, 0, '', NOW() - INTERVAL '4 days'),
  ('Bạch Quốc Toản', 'quoctoan.bach@gmail.com', '', '', FALSE, NULL, 300, 0, '', NOW() - INTERVAL '5 days'),
  ('Giang Mỹ Uyên', 'myuyen.giang@gmail.com', '', '', FALSE, NULL, 650, 0, '', NOW() - INTERVAL '5 days'),
  ('Kiều Anh Tuấn', 'anhtuan.kieu@gmail.com', '', '', FALSE, NULL, 400, 0, '', NOW() - INTERVAL '6 days'),
  ('Nông Đức Mạnh', 'nongducmanh.sign@gmail.com', '', '', FALSE, NULL, 500, 0, '', NOW() - INTERVAL '6 days'),
  ('Lã Thanh Huyền', 'thanhhuyen.la@gmail.com', '', '', FALSE, NULL, 350, 0, '', NOW() - INTERVAL '7 days'),
  ('Thạch Kim Tuấn', 'kimtuan.thach@gmail.com', '', '', FALSE, NULL, 600, 0, '', NOW() - INTERVAL '7 days'),
  ('Cù Thị Hương', 'huongct.spkt@gmail.com', '', '', FALSE, NULL, 450, 0, '', NOW() - INTERVAL '8 days'),
  ('Tôn Nữ Bích Trâm', 'bichtram.tonnu@gmail.com', '', '', FALSE, NULL, 550, 0, '', NOW() - INTERVAL '8 days'),
  ('Ôn Gia Bảo', 'giabao.on@gmail.com', '', '', FALSE, NULL, 300, 0, '', NOW() - INTERVAL '9 days'),
  ('Nguyễn Phương Nam', 'phuongnam.sign@gmail.com', '', '', FALSE, NULL, 650, 0, '', NOW() - INTERVAL '9 days'),
  ('Lê Thùy Trang', 'thuytrang.le@gmail.com', '', '', FALSE, NULL, 400, 0, '', NOW() - INTERVAL '10 days'),
  ('Trần Thanh Vinh', 'thanhvinh.tran@gmail.com', '', '', FALSE, NULL, 500, 0, '', NOW() - INTERVAL '10 days'),
  ('Đặng Minh Châu', 'minhchau.dang@gmail.com', '', '', FALSE, NULL, 350, 0, '', NOW() - INTERVAL '11 days'),
  ('Phạm Hoàng Việt', 'hoangviet.pham@gmail.com', '', '', FALSE, NULL, 600, 0, '', NOW() - INTERVAL '11 days'),
  ('Võ Kim Ngân', 'kimngan.vo@gmail.com', '', '', FALSE, NULL, 450, 0, '', NOW() - INTERVAL '12 days'),
  ('Bùi Đức Duy', 'ducduy.bui@gmail.com', '', '', FALSE, NULL, 550, 0, '', NOW() - INTERVAL '12 days'),
  ('Ngô Anh Thư', 'anhthu.ngo@gmail.com', '', '', FALSE, NULL, 300, 0, '', NOW() - INTERVAL '13 days'),
  ('Hồ Quang Khải', 'quangkhai.ho@gmail.com', '', '', FALSE, NULL, 650, 0, '', NOW() - INTERVAL '13 days'),
  ('Lâm Yến Nhi', 'yennhilam@gmail.com', '', '', FALSE, NULL, 400, 0, '', NOW() - INTERVAL '14 days'),
  ('Dương Tuấn Anh', 'tuananh.duong@gmail.com', '', '', FALSE, NULL, 500, 0, '', NOW() - INTERVAL '14 days'),
  ('Vũ Thu Thảo', 'thuthao.vu@gmail.com', '', '', FALSE, NULL, 350, 0, '', NOW() - INTERVAL '15 days'),
  ('Phan Quang Minh', 'quangminh.phan@gmail.com', '', '', FALSE, NULL, 600, 0, '', NOW() - INTERVAL '15 days'),
  ('Đỗ Hồng Nhung', 'hongnhung.do@gmail.com', '', '', FALSE, NULL, 450, 0, '', NOW() - INTERVAL '16 days'),
  ('Mai Đình Khoa', 'dinhkhoa.mai@gmail.com', '', '', FALSE, NULL, 550, 0, '', NOW() - INTERVAL '16 days'),
  ('Trịnh Bảo Châu', 'baochau.trinh@gmail.com', '', '', FALSE, NULL, 300, 0, '', NOW() - INTERVAL '17 days'),
  ('Lý Thanh Phong', 'thanhphong.ly@gmail.com', '', '', FALSE, NULL, 650, 0, '', NOW() - INTERVAL '17 days'),
  ('Nguyễn Cẩm Tú', 'camtu.nguyen@gmail.com', '', '', FALSE, NULL, 400, 0, '', NOW() - INTERVAL '18 days'),
  ('Hà Việt Anh', 'vietanh.ha@gmail.com', '', '', FALSE, NULL, 500, 0, '', NOW() - INTERVAL '18 days'),
  ('Đinh Ngọc Mai', 'ngocmai.dinh@gmail.com', '', '', FALSE, NULL, 350, 0, '', NOW() - INTERVAL '19 days'),
  ('Tạ Quốc Việt', 'quocviet.ta@gmail.com', '', '', FALSE, NULL, 600, 0, '', NOW() - INTERVAL '19 days'),
  ('Cao Mỹ Hạnh', 'myhanh.cao@gmail.com', '', '', FALSE, NULL, 450, 0, '', NOW() - INTERVAL '20 days'),
  ('Đoàn Hoàng Long', 'hoanglong.doan@gmail.com', '', '', FALSE, NULL, 550, 0, '', NOW() - INTERVAL '20 days'),
  ('Trương Thu Hà', 'thuha.truong@gmail.com', '', '', FALSE, NULL, 300, 0, '', NOW() - INTERVAL '21 days'),
  ('Lương Đức Mạnh', 'ducmanh.luong@gmail.com', '', '', FALSE, NULL, 650, 0, '', NOW() - INTERVAL '21 days'),
  ('Châu Phương Uyên', 'phuonguyen.chau@gmail.com', '', '', FALSE, NULL, 400, 0, '', NOW() - INTERVAL '22 days'),
  ('Tô Tấn Phát', 'tanphat.to@gmail.com', '', '', FALSE, NULL, 500, 0, '', NOW() - INTERVAL '22 days'),
  ('Chu Khánh Linh', 'khanhlinh.chu@gmail.com', '', '', FALSE, NULL, 350, 0, '', NOW() - INTERVAL '23 days'),
  ('Quách Thành Đạt', 'thanhdat.quach@gmail.com', '', '', FALSE, NULL, 600, 0, '', NOW() - INTERVAL '23 days'),
  ('Thân Ngọc Ánh', 'ngocanh.than@gmail.com', '', '', FALSE, NULL, 450, 0, '', NOW() - INTERVAL '24 days'),
  ('Thái Hữu Phước', 'huuphuoc.thai@gmail.com', '', '', FALSE, NULL, 550, 0, '', NOW() - INTERVAL '24 days'),
  ('Lưu Minh Thuận', 'minhthuan.luu@gmail.com', '', '', FALSE, NULL, 300, 0, '', NOW() - INTERVAL '25 days'),
  ('Tiêu Quỳnh Trâm', 'quynhtram.tieu@gmail.com', '', '', FALSE, NULL, 650, 0, '', NOW() - INTERVAL '25 days'),
  ('Bạch Hoàng Hải', 'hoanghai.bach@gmail.com', '', '', FALSE, NULL, 400, 0, '', NOW() - INTERVAL '26 days'),
  ('Kiều Bích Thảo', 'bichthao.kieu@gmail.com', '', '', FALSE, NULL, 500, 0, '', NOW() - INTERVAL '26 days'),
  ('Nông Văn Hùng', 'vanhung.nong@gmail.com', '', '', FALSE, NULL, 350, 0, '', NOW() - INTERVAL '27 days'),
  ('Thạch Mỹ Linh', 'mylinh.thach@gmail.com', '', '', FALSE, NULL, 600, 0, '', NOW() - INTERVAL '27 days'),
  ('Cù Thanh Sơn', 'thanhson.cu@gmail.com', '', '', FALSE, NULL, 450, 0, '', NOW() - INTERVAL '28 days'),
  ('Tôn Nữ Ngọc Diệp', 'ngocdiep.tonnu@gmail.com', '', '', FALSE, NULL, 550, 0, '', NOW() - INTERVAL '28 days'),
  ('Ôn Tuấn Kiệt', 'tuankiet.on@gmail.com', '', '', FALSE, NULL, 300, 0, '', NOW() - INTERVAL '29 days'),
  ('Hoàng Thị Yến', 'hoangyen.sign@gmail.com', '', '', FALSE, NULL, 850, 0, '', NOW() - INTERVAL '30 days')
ON CONFLICT (email) DO UPDATE SET 
  name = EXCLUDED.name,
  pro_expires_at = COALESCE(users.pro_expires_at, EXCLUDED.pro_expires_at),
  coins = GREATEST(users.coins, EXCLUDED.coins),
  coin_redeem_note = CASE WHEN EXCLUDED.coin_redeem_note != '' THEN EXCLUDED.coin_redeem_note ELSE users.coin_redeem_note END;

-- Seed Orders (Đúng 38 đơn đã duyệt, mỗi đơn 39.000đ => Tổng doanh thu: 1.482.000đ)
INSERT INTO pro_orders (email, name, plan, amount, status, transfer_ref, created_at, paid_at, payment_method, admin_note)
VALUES
  ('leloc2005qn@gmail.com', 'Lê Trà Gia Lộc', 'month', 39000, 'paid', 'SE04815737', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('tramyngoc1978@gmail.com', 'Trà Thị Mỹ Ngọc', 'month', 39000, 'paid', 'SE05016739', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('duclaqe180080@fpt.edu.vn', 'Lê Anh Đức', 'month', 39000, 'paid', 'SE15753966', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('nguyenhacaoky@gmail.com', 'Nguyễn Hà Cao Kỳ', 'month', 39000, 'paid', 'SE60471724', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('cuonghuynh2403@gmail.com', 'Huỳnh Quang Cường', 'month', 39000, 'paid', 'SE56947789', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('nguyenquochuy2k71508@gmail.com', 'Nguyễn Quốc Huy', 'month', 39000, 'paid', 'SE92771083', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('dinhngocthien2004@gmail.com', 'Đinh Ngọc Thiện', 'month', 39000, 'paid', 'SE1792889201550', NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('hongduyen.le@signeye.vn', 'Lê Thị Hồng Duyên', 'month', 39000, 'paid', 'SE1792654318992', NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('hoangminhtuan.hn@gmail.com', 'Hoàng Minh Tuấn', 'month', 39000, 'paid', 'SE28471920', NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('thaottp.sign@gmail.com', 'Trần Thị Phương Thảo', 'month', 39000, 'paid', 'SE91823746', NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('ducanh.pham99@gmail.com', 'Phạm Đức Anh', 'month', 39000, 'paid', 'SE56192837', NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('namvu.tech@gmail.com', 'Vũ Hải Nam', 'month', 39000, 'paid', 'SE73829104', NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('baongoc.sign21@gmail.com', 'Nguyễn Bảo Ngọc', 'month', 39000, 'paid', 'SE84920193', NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('thuydung.dang88@gmail.com', 'Đặng Thùy Dung', 'month', 39000, 'paid', 'SE61928475', NOW() - INTERVAL '8 days', NOW() - INTERVAL '8 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('huybq.ptit@gmail.com', 'Bùi Quang Huy', 'month', 39000, 'paid', 'SE48291039', NOW() - INTERVAL '8 days', NOW() - INTERVAL '8 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('thanhhang.do96@gmail.com', 'Đỗ Thanh Hằng', 'month', 39000, 'paid', 'SE93820194', NOW() - INTERVAL '9 days', NOW() - INTERVAL '9 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('minhquan.ngo@gmail.com', 'Ngô Minh Quân', 'month', 39000, 'paid', 'SE71928405', NOW() - INTERVAL '9 days', NOW() - INTERVAL '9 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('khoapa.danang@gmail.com', 'Phan Anh Khoa', 'month', 39000, 'paid', 'SE82910394', NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('hoaian.trinh@gmail.com', 'Trịnh Hoài An', 'month', 39000, 'paid', 'SE59281039', NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('linhmp.edu@gmail.com', 'Mai Phương Linh', 'month', 39000, 'paid', 'SE91827364', NOW() - INTERVAL '11 days', NOW() - INTERVAL '11 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('giahan.ly@gmail.com', 'Lý Gia Hân', 'month', 39000, 'paid', 'SE48291726', NOW() - INTERVAL '11 days', NOW() - INTERVAL '11 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('voquoctuan2002@gmail.com', 'Võ Quốc Tuấn', 'month', 39000, 'paid', 'SE73918204', NOW() - INTERVAL '12 days', NOW() - INTERVAL '12 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('thuykieu.duong@gmail.com', 'Dương Thúy Kiều', 'month', 39000, 'paid', 'SE82917402', NOW() - INTERVAL '12 days', NOW() - INTERVAL '12 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('lamhoainam.sign@gmail.com', 'Lâm Hoài Nam', 'month', 39000, 'paid', 'SE61928374', NOW() - INTERVAL '13 days', NOW() - INTERVAL '13 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('dinhphong.ta@gmail.com', 'Tạ Đình Phong', 'month', 39000, 'paid', 'SE93810294', NOW() - INTERVAL '13 days', NOW() - INTERVAL '13 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('nhatminh.doan@gmail.com', 'Đoàn Nhật Minh', 'month', 39000, 'paid', 'SE72819304', NOW() - INTERVAL '14 days', NOW() - INTERVAL '14 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('quynhnga.ho@gmail.com', 'Hồ Quỳnh Nga', 'month', 39000, 'paid', 'SE84910293', NOW() - INTERVAL '14 days', NOW() - INTERVAL '14 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('nghiatruong.fpt@gmail.com', 'Trương Trọng Nghĩa', 'month', 39000, 'paid', 'SE59182736', NOW() - INTERVAL '15 days', NOW() - INTERVAL '15 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('giabao.dinh@gmail.com', 'Đinh Gia Bảo', 'month', 39000, 'paid', 'SE92817402', NOW() - INTERVAL '15 days', NOW() - INTERVAL '15 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('bichngoc.cao@gmail.com', 'Cao Thị Bích Ngọc', 'month', 39000, 'paid', 'SE61928471', NOW() - INTERVAL '16 days', NOW() - INTERVAL '16 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('khaiphong.chau@gmail.com', 'Châu Khải Phong', 'month', 39000, 'paid', 'SE73829103', NOW() - INTERVAL '16 days', NOW() - INTERVAL '16 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('trieuviluong@gmail.com', 'Lương Triều Vĩ', 'month', 39000, 'paid', 'SE84910284', NOW() - INTERVAL '17 days', NOW() - INTERVAL '17 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('van.dinhdung@gmail.com', 'Văn Đình Dũng', 'month', 39000, 'paid', 'SE59182740', NOW() - INTERVAL '17 days', NOW() - INTERVAL '17 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('hoaibao.to@gmail.com', 'Tô Hoài Bảo', 'month', 39000, 'paid', 'SE92817492', NOW() - INTERVAL '18 days', NOW() - INTERVAL '18 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('khanhhuyen.chu@gmail.com', 'Chu Khánh Huyền', 'month', 39000, 'paid', 'SE61928405', NOW() - INTERVAL '18 days', NOW() - INTERVAL '18 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('tuandu.quach@gmail.com', 'Quách Tuấn Du', 'month', 39000, 'paid', 'SE73829184', NOW() - INTERVAL '19 days', NOW() - INTERVAL '19 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('trongphuc.than@gmail.com', 'Thân Trọng Phúc', 'month', 39000, 'paid', 'SE84910275', NOW() - INTERVAL '19 days', NOW() - INTERVAL '19 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng'),
  ('mylinh.thai@gmail.com', 'Thái Thị Mỹ Linh', 'month', 39000, 'paid', 'SE59182719', NOW() - INTERVAL '20 days', NOW() - INTERVAL '20 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng')
ON CONFLICT (transfer_ref) DO UPDATE SET
  status = EXCLUDED.status,
  paid_at = EXCLUDED.paid_at,
  name = EXCLUDED.name;
