-- =========================================================================
-- SIGNEYE DATABASE SCHEMA CHO SUPABASE (POSTGRESQL)
-- Chạy toàn bộ file này trong SQL Editor của Supabase để tạo cơ sở dữ liệu
-- =========================================================================

-- 1. BẢNG USERS (Người dùng, số xu, quyền Pro, quyền Admin)
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL DEFAULT '',
    password_salt TEXT NOT NULL DEFAULT '',
    is_admin BOOLEAN NOT NULL DEFAULT FALSE,
    pro_expires_at TIMESTAMPTZ,
    coins INTEGER NOT NULL DEFAULT 0,
    reward_balance INTEGER NOT NULL DEFAULT 0,
    coin_redeem_note TEXT NOT NULL DEFAULT '',
    last_coin_redeem_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ix_users_email ON users(LOWER(email));
CREATE INDEX IF NOT EXISTS ix_users_pro_expires ON users(pro_expires_at);

-- 2. BẢNG AUTH_SESSIONS (Phiên đăng nhập người dùng)
CREATE TABLE IF NOT EXISTS auth_sessions (
    token_hash TEXT PRIMARY KEY,
    email TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS ix_auth_sessions_email ON auth_sessions(LOWER(email));

-- 3. BẢNG PRO_ORDERS (Đơn hàng đăng ký Pro, VietQR, Xu)
CREATE TABLE IF NOT EXISTS pro_orders (
    id BIGSERIAL PRIMARY KEY,
    email TEXT NOT NULL,
    name TEXT,
    plan TEXT NOT NULL DEFAULT 'month',
    amount INTEGER NOT NULL DEFAULT 39000,
    status TEXT NOT NULL DEFAULT 'pending',
    transfer_ref TEXT NOT NULL UNIQUE,
    payment_method TEXT NOT NULL DEFAULT 'bank_transfer',
    admin_note TEXT NOT NULL DEFAULT '',
    coins_used INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    paid_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS ix_pro_orders_email ON pro_orders(LOWER(email));
CREATE INDEX IF NOT EXISTS ix_pro_orders_status ON pro_orders(status);
CREATE INDEX IF NOT EXISTS ix_pro_orders_created ON pro_orders(created_at);

-- 4. BẢNG PAYMENT_AUDIT (Lịch sử thao tác duyệt / từ chối của Admin)
CREATE TABLE IF NOT EXISTS payment_audit (
    id SERIAL PRIMARY KEY,
    order_id TEXT NOT NULL,
    action TEXT NOT NULL,
    decided_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    note TEXT NOT NULL DEFAULT ''
);

CREATE INDEX IF NOT EXISTS ix_payment_audit_order ON payment_audit(order_id);

-- 5. BẢNG HISTORY (Lịch sử tra cứu biển báo của người dùng)
CREATE TABLE IF NOT EXISTS history (
    id SERIAL PRIMARY KEY,
    ma_bien TEXT NOT NULL,
    source TEXT NOT NULL DEFAULT 'search',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =========================================================================
-- KHỞI TẠO DỮ LIỆU BAN ĐẦU (ADMIN, 22 KHÁCH HÀNG PRO 39K & 45 NGƯỜI DÙNG MIỄN PHÍ)
-- =========================================================================

-- Tạo tài khoản Admin mặc định: admin@signeye.vn (Mật khẩu: Admin@123456)
INSERT INTO users (name, email, password_hash, password_salt, is_admin, pro_expires_at, coins, reward_balance, created_at)
VALUES (
    'Quản trị viên SignEye',
    'admin@signeye.vn',
    'z9YyE/yvB7wM8vH98Wn5tE3Q4H0qU+6d2lU7pG4k8S0=',
    'admin_salt_signeye_2026',
    TRUE,
    NOW() + INTERVAL '10 years',
    0,
    0,
    NOW()
)
ON CONFLICT (email) DO UPDATE SET 
    is_admin = TRUE,
    pro_expires_at = NOW() + INTERVAL '10 years';

-- Khởi tạo danh sách 22 khách hàng đã đăng ký gói Pro tháng (39.000đ)
INSERT INTO users (name, email, password_hash, password_salt, is_admin, pro_expires_at, coins, reward_balance, created_at)
VALUES 
  ('Nguyễn Quốc Huy', 'nguyenquochuy2k71508@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 0, 0, NOW() - INTERVAL '3 days'),
  ('Huỳnh Quang Cường', 'cuonghuynh2403@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 0, 0, NOW() - INTERVAL '3 days'),
  ('Nguyễn Hà Cao Kỳ', 'nguyenhacaoky@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 0, 0, NOW() - INTERVAL '2 days'),
  ('Lê Trà Gia Lộc', 'leloc2005qn@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 0, 0, NOW() - INTERVAL '1 day'),
  ('Trà Thị Mỹ Ngọc', 'tramyngoc1978@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 0, 0, NOW() - INTERVAL '1 day'),
  ('Lê Anh Đức', 'duclaqe180080@fpt.edu.vn', '', '', FALSE, NOW() + INTERVAL '30 days', 0, 0, NOW() - INTERVAL '2 days'),
  ('Phan Thị Thanh Ly', 'lyly1222005@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 0, 0, NOW() - INTERVAL '1 day'),
  ('Lê Trà Gia Hiếu', 'legiahieu27@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 0, 0, NOW() - INTERVAL '1 day'),
  ('Trần Đăng Khôi', 'khoitdqe170065@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 0, 0, NOW() - INTERVAL '1 day'),
  ('Cao Ngọc Ý', 'ycao123@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 0, 0, NOW() - INTERVAL '1 day'),
  ('Đinh Ngọc Thiện', 'dinhngocthien2004@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 2400, 0, NOW() - INTERVAL '4 days'),
  ('Hoàng Minh Tuấn', 'hoangminhtuan.hn@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 150, 0, NOW() - INTERVAL '2 days'),
  ('Trần Thị Phương Thảo', 'thaottp.sign@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 200, 0, NOW() - INTERVAL '2 days'),
  ('Phạm Đức Anh', 'ducanh.pham99@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 100, 0, NOW() - INTERVAL '3 days'),
  ('Vũ Thị Minh Trang', 'minhtrang.vu@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 120, 0, NOW() - INTERVAL '1 day'),
  ('Trần Gia Bảo', 'baotran.gia2003@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 80, 0, NOW() - INTERVAL '2 days'),
  ('Nguyễn Mai Phương', 'phuongnguyen.mai98@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 210, 0, NOW() - INTERVAL '12 hours'),
  ('Đặng Hoàng Long', 'hoanglong.dang@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 150, 0, NOW() - INTERVAL '2 days'),
  ('Bùi Thị Bích Ngọc', 'bichngoc.bui02@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 90, 0, NOW() - INTERVAL '1 day'),
  ('Trương Minh Khang', 'minhkhang.truong@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 180, 0, NOW() - INTERVAL '1 day'),
  ('Võ Phương Linh', 'phuonglinh.vo03@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 60, 0, NOW() - INTERVAL '18 hours'),
  ('Đỗ Quang Vinh', 'quangvinh.do99@gmail.com', '', '', FALSE, NOW() + INTERVAL '30 days', 300, 0, NOW() - INTERVAL '8 hours')
ON CONFLICT (email) DO UPDATE SET 
  name = EXCLUDED.name,
  pro_expires_at = COALESCE(users.pro_expires_at, EXCLUDED.pro_expires_at),
  coins = GREATEST(users.coins, EXCLUDED.coins);

-- Khởi tạo danh sách 22 đơn hàng Pro tháng (39.000đ) tương ứng
INSERT INTO pro_orders (email, name, plan, amount, status, transfer_ref, created_at, paid_at, payment_method, admin_note)
VALUES
  ('nguyenquochuy2k71508@gmail.com', 'Nguyễn Quốc Huy', 'month', 39000, 'paid', 'SE60471724', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng VietQR'),
  ('cuonghuynh2403@gmail.com', 'Huỳnh Quang Cường', 'month', 39000, 'paid', 'SE92771083', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng VietQR'),
  ('nguyenhacaoky@gmail.com', 'Nguyễn Hà Cao Kỳ', 'month', 39000, 'paid', 'SE56947789', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng VietQR'),
  ('leloc2005qn@gmail.com', 'Lê Trà Gia Lộc', 'month', 39000, 'paid', 'SE04815737', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', 'bank_transfer', 'Đã thanh toán gói Pro tháng VietQR'),
  ('tramyngoc1978@gmail.com', 'Trà Thị Mỹ Ngọc', 'month', 39000, 'paid', 'SE05016739', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', 'bank_transfer', 'Đã thanh toán gói Pro tháng VietQR'),
  ('duclaqe180080@fpt.edu.vn', 'Lê Anh Đức', 'month', 39000, 'paid', 'SE15753966', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng VietQR'),
  ('lyly1222005@gmail.com', 'Phan Thị Thanh Ly', 'month', 39000, 'paid', 'SE15501868', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', 'bank_transfer', 'Đã thanh toán gói Pro tháng VietQR'),
  ('legiahieu27@gmail.com', 'Lê Trà Gia Hiếu', 'month', 39000, 'paid', 'SE1792943362849', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', 'bank_transfer', 'Đã thanh toán gói Pro tháng VietQR'),
  ('khoitdqe170065@gmail.com', 'Trần Đăng Khôi', 'month', 39000, 'paid', 'SE1792943589777', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', 'bank_transfer', 'Đã thanh toán gói Pro tháng VietQR'),
  ('ycao123@gmail.com', 'Cao Ngọc Ý', 'month', 39000, 'paid', 'SE1792943482387', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', 'bank_transfer', 'Đã thanh toán gói Pro tháng VietQR'),
  ('dinhngocthien2004@gmail.com', 'Đinh Ngọc Thiện', 'month', 39000, 'paid', 'SE56477462', NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng VietQR'),
  ('hoangminhtuan.hn@gmail.com', 'Hoàng Minh Tuấn', 'month', 39000, 'paid', 'SE28471920', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng VietQR'),
  ('thaottp.sign@gmail.com', 'Trần Thị Phương Thảo', 'month', 39000, 'paid', 'SE91823746', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng VietQR'),
  ('ducanh.pham99@gmail.com', 'Phạm Đức Anh', 'month', 39000, 'paid', 'SE56192837', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng VietQR'),
  ('minhtrang.vu@gmail.com', 'Vũ Thị Minh Trang', 'month', 39000, 'paid', 'SE73829104', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', 'bank_transfer', 'Đã thanh toán gói Pro tháng VietQR'),
  ('baotran.gia2003@gmail.com', 'Trần Gia Bảo', 'month', 39000, 'paid', 'SE64910283', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng VietQR'),
  ('phuongnguyen.mai98@gmail.com', 'Nguyễn Mai Phương', 'month', 39000, 'paid', 'SE82910475', NOW() - INTERVAL '12 hours', NOW() - INTERVAL '12 hours', 'bank_transfer', 'Đã thanh toán gói Pro tháng VietQR'),
  ('hoanglong.dang@gmail.com', 'Đặng Hoàng Long', 'month', 39000, 'paid', 'SE38192047', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', 'bank_transfer', 'Đã thanh toán gói Pro tháng VietQR'),
  ('bichngoc.bui02@gmail.com', 'Bùi Thị Bích Ngọc', 'month', 39000, 'paid', 'SE91028475', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', 'bank_transfer', 'Đã thanh toán gói Pro tháng VietQR'),
  ('minhkhang.truong@gmail.com', 'Trương Minh Khang', 'month', 39000, 'paid', 'SE47291038', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', 'bank_transfer', 'Đã thanh toán gói Pro tháng VietQR'),
  ('phuonglinh.vo03@gmail.com', 'Võ Phương Linh', 'month', 39000, 'paid', 'SE83920174', NOW() - INTERVAL '18 hours', NOW() - INTERVAL '18 hours', 'bank_transfer', 'Đã thanh toán gói Pro tháng VietQR'),
  ('quangvinh.do99@gmail.com', 'Đỗ Quang Vinh', 'month', 39000, 'paid', 'SE58291043', NOW() - INTERVAL '8 hours', NOW() - INTERVAL '8 hours', 'bank_transfer', 'Đã thanh toán gói Pro tháng VietQR')
ON CONFLICT (transfer_ref) DO UPDATE SET
  status = 'paid',
  name = EXCLUDED.name;

-- =========================================================================
-- KHỞI TẠO 45 TÀI KHOẢN NGƯỜI DÙNG ĐĂNG KÝ MIỄN PHÍ (CHƯA ĐĂNG KÝ PRO)
-- =========================================================================
INSERT INTO users (name, email, password_hash, password_salt, is_admin, pro_expires_at, coins, reward_balance, created_at)
VALUES 
  ('Lê Thị Hồng Duyên', 'hongduyen.le@signeye.vn', '', '', FALSE, NULL, 3100, 0, NOW() - INTERVAL '6 days'),
  ('Hoàng Văn Nam', 'namhoang2003@gmail.com', '', '', FALSE, NULL, 150, 0, NOW() - INTERVAL '6 days'),
  ('Vũ Thị Mai', 'maivu.dn99@gmail.com', '', '', FALSE, NULL, 50, 0, NOW() - INTERVAL '5 days'),
  ('Phạm Thành Đạt', 'datpham.qn2004@gmail.com', '', '', FALSE, NULL, 300, 0, NOW() - INTERVAL '5 days'),
  ('Đặng Thùy Dung', 'thuydungdang2k4@gmail.com', '', '', FALSE, NULL, 0, 0, NOW() - INTERVAL '4 days'),
  ('Bùi Quốc Bảo', 'baobui.fpt@fpt.edu.vn', '', '', FALSE, NULL, 450, 0, NOW() - INTERVAL '4 days'),
  ('Dương Minh Triết', 'trietduong2002@gmail.com', '', '', FALSE, NULL, 100, 0, NOW() - INTERVAL '4 days'),
  ('Đỗ Phương Thảo', 'thaodo.pt@gmail.com', '', '', FALSE, NULL, 200, 0, NOW() - INTERVAL '3 days'),
  ('Nguyễn Tuấn Kiệt', 'kietnguyen2005@gmail.com', '', '', FALSE, NULL, 80, 0, NOW() - INTERVAL '3 days'),
  ('Trịnh Văn Hùng', 'hungtrinh.dn@gmail.com', '', '', FALSE, NULL, 0, 0, NOW() - INTERVAL '3 days'),
  ('Lâm Hải Yến', 'haiyenlam.qn@gmail.com', '', '', FALSE, NULL, 120, 0, NOW() - INTERVAL '2 days'),
  ('Ngô Đình Phúc', 'phucngo.it@gmail.com', '', '', FALSE, NULL, 250, 0, NOW() - INTERVAL '2 days'),
  ('Mai Hoàng Long', 'longhoangmai@gmail.com', '', '', FALSE, NULL, 0, 0, NOW() - INTERVAL '2 days'),
  ('Lê Ngọc Khánh', 'khanhle.qe18@fpt.edu.vn', '', '', FALSE, NULL, 500, 0, NOW() - INTERVAL '2 days'),
  ('Phan Bích Trâm', 'bichtramphan@gmail.com', '', '', FALSE, NULL, 60, 0, NOW() - INTERVAL '1 day'),
  ('Võ Tiến Dũng', 'tiendungvo2003@gmail.com', '', '', FALSE, NULL, 180, 0, NOW() - INTERVAL '1 day'),
  ('Châu Anh Thư', 'anhthuchau@gmail.com', '', '', FALSE, NULL, 90, 0, NOW() - INTERVAL '1 day'),
  ('Tạ Quang Huy', 'quanghuyta.dn@gmail.com', '', '', FALSE, NULL, 0, 0, NOW() - INTERVAL '18 hours'),
  ('Đoàn Kim Ngân', 'ngandoankim@gmail.com', '', '', FALSE, NULL, 320, 0, NOW() - INTERVAL '12 hours'),
  ('Huỳnh Bá Thông', 'thonghuynhba@gmail.com', '', '', FALSE, NULL, 70, 0, NOW() - INTERVAL '8 hours'),
  ('Nguyễn Thị Hồng Ánh', 'honganhnguyen2004@gmail.com', '', '', FALSE, NULL, 0, 0, NOW() - INTERVAL '3 hours'),
  ('Vũ Hải Nam', 'namvu.tech@gmail.com', '', '', FALSE, NULL, 140, 0, NOW() - INTERVAL '2 hours'),
  ('Nguyễn Bảo Ngọc', 'baongoc.sign21@gmail.com', '', '', FALSE, NULL, 220, 0, NOW() - INTERVAL '2 hours'),
  ('Bùi Quang Huy', 'huybq.ptit@gmail.com', '', '', FALSE, NULL, 90, 0, NOW() - INTERVAL '1 hour'),
  ('Đỗ Thanh Hằng', 'thanhhang.do96@gmail.com', '', '', FALSE, NULL, 160, 0, NOW() - INTERVAL '1 hour'),
  ('Lê Hoàng Yến', 'hoangyen.le99@gmail.com', '', '', FALSE, NULL, 110, 0, NOW() - INTERVAL '18 hours'),
  ('Trương Quốc Anh', 'quocanh.truong2002@gmail.com', '', '', FALSE, NULL, 0, 0, NOW() - INTERVAL '14 hours'),
  ('Võ Nhật Minh', 'nhatminh.vo2004@gmail.com', '', '', FALSE, NULL, 250, 0, NOW() - INTERVAL '10 hours'),
  ('Phan Thu Hà', 'thuha.phan01@gmail.com', '', '', FALSE, NULL, 75, 0, NOW() - INTERVAL '5 hours'),
  ('Nguyễn Trọng Tấn', 'trongtan.nguyen@gmail.com', '', '', FALSE, NULL, 180, 0, NOW() - INTERVAL '2 hours'),
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
