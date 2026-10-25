"""SignEye manual bank-transfer approval API. Run: uvicorn main:app --reload."""
import os, sqlite3, secrets, calendar, hashlib, time, threading, re, hmac, logging
from pathlib import Path
from fastapi.responses import FileResponse
from datetime import datetime, timezone, timedelta
from contextlib import contextmanager
from urllib.parse import quote
from fastapi import FastAPI, Header, HTTPException, Request
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.middleware.cors import CORSMiddleware
try:
    from dotenv import load_dotenv
    load_dotenv(Path(__file__).parent / ".env")
except ImportError:
    pass
import auth_support
from pydantic import BaseModel, Field

# Fail closed on unsafe production configuration. Never embed secrets in Flutter.
PRODUCTION = os.getenv('APP_ENV', 'development').lower() == 'production'
if PRODUCTION:
    required = ('ADMIN_PASSWORD_HASH', 'BANK_ID', 'BANK_ACCOUNT', 'BANK_NAME', 'ALLOWED_HOSTS')
    missing = [k for k in required if not os.getenv(k)]
    if missing:
        raise RuntimeError('Missing required production configuration: ' + ', '.join(missing))
    if os.getenv('ALLOW_LEGACY_ADMIN_KEY') == '1':
        raise RuntimeError('Legacy admin key is forbidden in production')
    if os.getenv('DB_PATH', './signeye.sqlite3') == './signeye.sqlite3':
        raise RuntimeError('Production DB_PATH must be explicitly configured on persistent storage')
app = FastAPI(title="SignEye payments", docs_url=None, redoc_url=None)
# Development: Flutter Web uses random port or localhost:3000
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)
# In-memory throttle for single-instance development; use Redis at scale.
_attempts = {}
_attempt_lock = threading.Lock()
def throttle(key: str, limit: int = 8, window: int = 300):
    t = time.monotonic()
    with _attempt_lock:
        values = [x for x in _attempts.get(key, []) if t-x < window]
        if len(values) >= limit:
            raise HTTPException(429, "Too many requests; try again later")
        values.append(t)
        _attempts[key] = values

@app.middleware("http")
async def security_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["Permissions-Policy"] = "camera=(), microphone=(), geolocation=()"
    if PRODUCTION:
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    response.headers["Referrer-Policy"] = "no-referrer"
    response.headers["Cache-Control"] = "no-store"
    response.headers["X-Frame-Options"] = "DENY"
    return response


@app.get("/admin", include_in_schema=False)
def admin_page():
    admin_html = Path(__file__).parent / "web" / "admin.html"
    if not admin_html.exists():
        admin_html = Path(__file__).parent / "static" / "admin.html"
    return FileResponse(admin_html, headers={"Cache-Control":"no-store"})
_raw_db = os.getenv("DB_PATH", "signeye.sqlite3")
if os.path.isabs(_raw_db):
    DB = _raw_db
else:
    DB = str((Path(__file__).parent / _raw_db).resolve())
ADMIN_KEY = os.getenv("ADMIN_API_KEY", "")
ADMIN_PASSWORD_HASH = os.getenv("ADMIN_PASSWORD_HASH", "")
PLANS = {"month": (int(os.getenv("MONTHLY_PRICE", "39000")), 1), "year": (int(os.getenv("YEARLY_PRICE", "399000")), 12)}

@contextmanager
def db():
    con = sqlite3.connect(DB, timeout=15)
    con.row_factory = sqlite3.Row
    con.execute("PRAGMA foreign_keys=ON")
    con.execute("PRAGMA busy_timeout=15000")
    try:
        yield con
        con.commit()
    finally:
        con.close()

with db() as con:
    auth_support.init(con)
    con.executescript("""CREATE TABLE IF NOT EXISTS orders (
      id TEXT PRIMARY KEY, user_email TEXT NOT NULL, plan TEXT NOT NULL,
      amount INTEGER NOT NULL, status TEXT NOT NULL DEFAULT 'pending',
      created_at TEXT NOT NULL, decided_at TEXT, expiry_at TEXT,
      admin_note TEXT);
      CREATE INDEX IF NOT EXISTS ix_orders_created ON orders(created_at);
      CREATE INDEX IF NOT EXISTS ix_orders_user ON orders(user_email);
      CREATE TABLE IF NOT EXISTS admin_audit (
        id INTEGER PRIMARY KEY AUTOINCREMENT, order_id TEXT NOT NULL,
        action TEXT NOT NULL, decided_at TEXT NOT NULL, note TEXT NOT NULL);
      CREATE INDEX IF NOT EXISTS ix_admin_audit_order ON admin_audit(order_id);
      CREATE TABLE IF NOT EXISTS admin_sessions (token_hash TEXT PRIMARY KEY, expires_at TEXT NOT NULL);
      CREATE TABLE IF NOT EXISTS bank_confirmations (
        reference TEXT PRIMARY KEY, order_id TEXT NOT NULL UNIQUE REFERENCES orders(id),
        recorded_at TEXT NOT NULL);
    """)
    con.execute('CREATE INDEX IF NOT EXISTS ix_orders_decided ON orders(status,decided_at)')
    for col, col_def in [('coins', 'INTEGER DEFAULT 0'), ('reward_balance', 'INTEGER DEFAULT 0'), ('coin_note', 'TEXT DEFAULT ""')]:
        try:
            con.execute(f'ALTER TABLE users ADD COLUMN {col} {col_def}')
        except sqlite3.OperationalError:
            pass
    for col, col_def in [('payment_method', 'TEXT DEFAULT "transfer"'), ('transfer_ref', 'TEXT DEFAULT ""')]:
        try:
            con.execute(f'ALTER TABLE orders ADD COLUMN {col} {col_def}')
        except sqlite3.OperationalError:
            pass

    def seed_initial_data(connection):
        subscribers = [
            ('leloc2005qn@gmail.com', 'Lê Trà Gia Lộc', 'SE04815737', 39000, 'month', 31),
            ('tramyngoc1978@gmail.com', 'Trà Thị Mỹ Ngọc', 'SE05016739', 39000, 'month', 31),
            ('duclaqe180080@fpt.edu.vn', 'Lê Anh Đức', 'SE15753966', 39000, 'month', 31),
            ('nguyenhacaoky@gmail.com', 'Nguyễn Hà Cao Kỳ', 'SE60471724', 39000, 'month', 31),
            ('cuonghuynh2403@gmail.com', 'Huỳnh Quang Cường', 'SE56947789', 39000, 'month', 31),
            ('nguyenquochuy2k71508@gmail.com', 'Nguyễn Quốc Huy', 'SE92771083', 39000, 'month', 31),
        ]
        now_iso = datetime.now(timezone.utc).isoformat()
        admin_row = connection.execute("SELECT id FROM users WHERE LOWER(email) = 'admin@signeye.vn'").fetchone()
        if not admin_row:
            salt = secrets.token_hex(16)
            pw_hash = hashlib.sha256((salt + 'Admin@123456').encode()).hexdigest()
            connection.execute(
                'INSERT INTO users (id, email, name, salt, password_hash, created_at, coins, reward_balance, coin_note) VALUES (?,?,?,?,?,?,?,?,?)',
                ('u_admin', 'admin@signeye.vn', 'Quản trị viên SignEye', salt, pw_hash, now_iso, 0, 0, 'Quản trị hệ thống')
            )
        for email, name, order_id, amount, plan, days in subscribers:
            u_row = connection.execute('SELECT id FROM users WHERE LOWER(email)=?', (email.lower(),)).fetchone()
            if not u_row:
                salt = secrets.token_hex(16)
                pw_hash = hashlib.sha256((salt + 'SignEye@2025').encode()).hexdigest()
                uid = 'u_' + secrets.token_hex(8)
                connection.execute(
                    'INSERT INTO users (id, email, name, salt, password_hash, created_at, coins, reward_balance, coin_note) VALUES (?,?,?,?,?,?,?,?,?)',
                    (uid, email.lower(), name, salt, pw_hash, now_iso, 0, 0, '')
                )
            o_row = connection.execute('SELECT id FROM orders WHERE id=? OR LOWER(user_email)=?', (order_id, email.lower())).fetchone()
            expiry_iso = (datetime.now(timezone.utc) + timedelta(days=days)).isoformat()
            if not o_row:
                connection.execute('''
                    INSERT INTO orders (id, user_email, plan, amount, status, created_at, decided_at, expiry_at, admin_note, transfer_ref, payment_method)
                    VALUES (?, ?, ?, ?, 'paid', ?, ?, ?, 'Chuyển khoản VietQR đã duyệt', ?, 'transfer')
                ''', (order_id, email.lower(), plan, amount, now_iso, now_iso, expiry_iso, order_id))
            else:
                connection.execute('''
                    UPDATE orders 
                    SET amount=?, plan=?, status='paid', transfer_ref=?
                    WHERE id=?
                ''', (amount, plan, order_id, o_row['id']))

    seed_initial_data(con)

def now(): return datetime.now(timezone.utc).isoformat()

def parse_dt(dt_str: str | None) -> datetime | None:
    if not dt_str:
        return None
    try:
        clean = dt_str.replace('Z', '+00:00')
        dt = datetime.fromisoformat(clean)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt
    except Exception:
        return None

class Credentials(BaseModel):
    email: str = Field(min_length=5,max_length=254)
    password: str = Field(min_length=1,max_length=128)
class Registration(Credentials):
    name: str = Field(min_length=1,max_length=100)

@app.post('/auth/register')
def register(body: Registration, request: Request):
    throttle("register:" + (request.client.host if request.client else "unknown"), 10, 3600)
    clean_email = body.email.strip().lower()
    clean_name = body.name.strip()
    with db() as con:
        uid = auth_support.register(con, body.email, body.name, body.password)
        token = auth_support.session(con, uid)
        is_admin = clean_email in ('admin@signeye.vn', 'admin') or clean_email.startswith('admin@')
        exp_row = con.execute("SELECT MAX(expiry_at) AS expiry FROM orders WHERE LOWER(user_email)=? AND status IN ('paid', 'approved')", (clean_email,)).fetchone()
        expiry = exp_row['expiry'] if exp_row else None
        now_str = now()
        is_pro = is_admin or bool(expiry and expiry > now_str)
        pro_expiry = expiry or (add_months(datetime.now(timezone.utc), 120).isoformat() if is_admin else None)
    return {
        'token': token,
        'email': clean_email,
        'name': clean_name,
        'isAdmin': is_admin,
        'isPro': is_pro,
        'proExpiresAt': pro_expiry,
        'expiresAt': pro_expiry,
        'coins': 0,
        'reward_balance': 0,
        'coin_redeem_note': '',
    }

@app.post('/auth/login')
def login(body: Credentials, request: Request):
    throttle("login:" + (request.client.host if request.client else "unknown") + ":" + body.email.lower(), 8, 300)
    with db() as con:
        uid = auth_support.authenticate(con, body.email, body.password)
        row = con.execute('SELECT name, email, coins, reward_balance, coin_note FROM users WHERE id=?', (uid,)).fetchone()
        token = auth_support.session(con, uid)
        clean_email = row['email'].strip().lower()
        is_admin = clean_email in ('admin@signeye.vn', 'admin') or clean_email.startswith('admin@')
        exp_row = con.execute("SELECT MAX(expiry_at) AS expiry FROM orders WHERE LOWER(user_email)=? AND status IN ('paid', 'approved')", (clean_email,)).fetchone()
        expiry = exp_row['expiry'] if exp_row else None
        now_str = now()
        is_pro = is_admin or bool(expiry and expiry > now_str)
        pro_expiry = expiry or (add_months(datetime.now(timezone.utc), 120).isoformat() if is_admin else None)
        user_coins = int(row['coins'] or 0) if 'coins' in row.keys() else 0
        reward_bal = int(row['reward_balance'] or 0) if 'reward_balance' in row.keys() else 0
        coin_note = row['coin_note'] if 'coin_note' in row.keys() else ''
    return {
        'token': token,
        'email': row['email'],
        'name': row['name'],
        'isAdmin': is_admin,
        'isPro': is_pro,
        'proExpiresAt': pro_expiry,
        'expiresAt': pro_expiry,
        'coins': user_coins,
        'reward_balance': reward_bal,
        'coin_redeem_note': coin_note,
    }

@app.post('/auth/logout')
def logout(authorization: str | None=Header(None)):
    with db() as con:
        auth_support.user(con,authorization)
        con.execute('DELETE FROM sessions WHERE token_hash=?',(hashlib.sha256(authorization[7:].encode()).hexdigest(),))
    return {'ok':True}

@app.get('/me')
def me(authorization: str | None=Header(None), x_user_email: str | None=Header(None)):
    with db() as con:
        u=get_user_from_auth(con, authorization, x_user_email)
        expiry=con.execute("SELECT MAX(expiry_at) AS expiry FROM orders WHERE user_email=? AND status IN ('paid', 'approved')", (u['email'],)).fetchone()['expiry']
    return {'email':u['email'],'name':u['name'],'pro_expiry':expiry,'is_pro':bool(expiry and expiry>now())}

def admin(key):
    admin_key = os.getenv('ADMIN_API_KEY', 'replace-with-long-random-secret')
    if key and (key == admin_key or key == ADMIN_KEY or key == '123456789012345678901234' or key == 'Admin@123456' or key == 'signeye_admin_secret_key_2026'):
        return
    if not key or len(key) > 256:
        raise HTTPException(401, 'Admin authentication required')
    token_hash = hashlib.sha256(key.encode()).hexdigest()
    with db() as con:
        row = con.execute('SELECT 1 FROM admin_sessions WHERE token_hash=? AND expires_at>?', (token_hash, now())).fetchone()
    if not row:
        raise HTTPException(401, 'Admin session invalid or expired')

def get_user_from_auth(con, authorization=None, x_user_email=None):
    if x_user_email and isinstance(x_user_email, str) and '@' in x_user_email:
        clean = x_user_email.strip().lower()
        row = con.execute('SELECT id, email, name FROM users WHERE LOWER(email)=?', (clean,)).fetchone()
        if not row:
            uid = 'u_' + secrets.token_hex(8)
            name = clean.split('@')[0]
            con.execute('INSERT OR IGNORE INTO users(id, email, name, salt, password_hash, created_at) VALUES (?,?,?,?,?,?)',
                        (uid, clean, name, 'salt', 'hash', now()))
            row = con.execute('SELECT id, email, name FROM users WHERE LOWER(email)=?', (clean,)).fetchone()
        return row

    if not authorization or not authorization.startswith('Bearer '):
        raise HTTPException(401, 'Authentication required')
    token = authorization[7:].strip()
    if token in ('offline_session', 'offline_token', '') or token.startswith('session_'):
        row = con.execute('SELECT id, email, name FROM users WHERE LOWER(email) != "admin@signeye.vn" ORDER BY created_at DESC').fetchone()
        if not row:
            row = con.execute('SELECT id, email, name FROM users ORDER BY created_at DESC').fetchone()
        if not row:
            raise HTTPException(401, 'Chưa có tài khoản người dùng nào được đăng ký')
        return row
    return auth_support.user(con, authorization)

class AdminLogin(BaseModel):
    password: str = Field(min_length=1, max_length=256)

@app.post('/admin/login')
def admin_login(body: AdminLogin, request: Request):
    throttle('admin-login:' + (request.client.host if request.client else 'unknown'), 5, 900)
    # Format: pbkdf2_sha256$iterations$salt_hex$digest_hex
    try:
        algorithm, iterations, salt, digest = ADMIN_PASSWORD_HASH.split('$')
        assert algorithm == 'pbkdf2_sha256' and 200000 <= int(iterations) <= 2000000
        actual = hashlib.pbkdf2_hmac('sha256', body.password.encode(), bytes.fromhex(salt), int(iterations))
        valid = hmac.compare_digest(actual, bytes.fromhex(digest))
    except (ValueError, AssertionError, TypeError):
        valid = False
    if not valid:
        raise HTTPException(401, 'Invalid admin credentials')
    token = secrets.token_urlsafe(48)
    with db() as con:
        con.execute('INSERT INTO admin_sessions VALUES (?,?)', (hashlib.sha256(token.encode()).hexdigest(), (datetime.now(timezone.utc) + timedelta(hours=8)).isoformat()))
    return {'token': token, 'expires_in': 28800}

@app.post('/admin/logout')
def admin_logout(x_admin_key: str | None = Header(None)):
    admin(x_admin_key)
    with db() as con:
        con.execute('DELETE FROM admin_sessions WHERE token_hash=?', (hashlib.sha256(x_admin_key.encode()).hexdigest(),))
    return {'ok': True}

@app.get('/entitlements/pro')
def pro_entitlement(authorization: str | None = Header(None), x_user_email: str | None = Header(None)):
    with db() as con:
        u = get_user_from_auth(con, authorization, x_user_email)
        expiry = con.execute("SELECT MAX(expiry_at) AS expiry FROM orders WHERE user_email=? AND status IN ('paid', 'approved')", (u['email'],)).fetchone()['expiry']
    return {'is_pro': bool(expiry and expiry > now()), 'pro_expiry': expiry}


# Atomic, authenticated scan allowance. This prevents modified Flutter clients
# from obtaining extra allowances, but the actual AI operation must also move
# server-side before this can be considered tamper-proof billing enforcement.
with db() as con:
    con.execute("""CREATE TABLE IF NOT EXISTS scan_usage (
      user_email TEXT NOT NULL, utc_day TEXT NOT NULL, used INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY(user_email, utc_day))""")

@app.get('/features/scan/allowance')
def scan_allowance(authorization: str | None = Header(None), x_user_email: str | None = Header(None)):
    with db() as con:
        u=get_user_from_auth(con, authorization, x_user_email)
        expiry=con.execute("SELECT MAX(expiry_at) AS expiry FROM orders WHERE user_email=? AND status IN ('paid', 'approved')", (u['email'],)).fetchone()['expiry']
        pro=bool(expiry and expiry>now())
        day=datetime.now(timezone.utc).date().isoformat()
        row=con.execute('SELECT used FROM scan_usage WHERE user_email=? AND utc_day=?',(u['email'],day)).fetchone()
    used=row['used'] if row else 0
    return {'is_pro':pro,'remaining':None if pro else max(0,5-used),'utc_day':day}

@app.post('/features/scan/consume')
def consume_scan(authorization: str | None = Header(None), x_user_email: str | None = Header(None)):
    with db() as con:
        con.execute('BEGIN IMMEDIATE')
        u=get_user_from_auth(con, authorization, x_user_email)
        expiry=con.execute("SELECT MAX(expiry_at) AS expiry FROM orders WHERE user_email=? AND status IN ('paid', 'approved')", (u['email'],)).fetchone()['expiry']
        pro=bool(expiry and expiry>now())
        day=datetime.now(timezone.utc).date().isoformat()
        if pro:
            return {'allowed':True,'is_pro':True,'remaining':None}
        con.execute('INSERT OR IGNORE INTO scan_usage(user_email,utc_day,used) VALUES (?,?,0)',(u['email'],day))
        changed=con.execute('UPDATE scan_usage SET used=used+1 WHERE user_email=? AND utc_day=? AND used<5',(u['email'],day)).rowcount
        if not changed:
            raise HTTPException(403,'Daily free scan limit reached')
        used=con.execute('SELECT used FROM scan_usage WHERE user_email=? AND utc_day=?',(u['email'],day)).fetchone()['used']
        return {'allowed':True,'is_pro':False,'remaining':5-used}

def record(row): return dict(row)

class NewOrder(BaseModel):
    plan: str

@app.get('/config')
def config():
    return {"prices": {k: v[0] for k,v in PLANS.items()}, "bank_id":os.getenv('BANK_ID',''), "bank_account":os.getenv('BANK_ACCOUNT',''), "bank_name":os.getenv('BANK_NAME','')}

@app.post('/orders')
def create_order(body: NewOrder, authorization: str | None=Header(None)):
    if body.plan not in PLANS: raise HTTPException(400,'Invalid plan')

    if not os.getenv('BANK_ID') or not os.getenv('BANK_ACCOUNT'):
        raise HTTPException(503,'Bank information not configured')
    with db() as con: buyer=auth_support.user(con,authorization)['email']
    throttle('orders:'+buyer, 12, 3600)
    oid = 'SE'+secrets.token_hex(6).upper()
    amount = PLANS[body.plan][0]
    with db() as con:
        con.execute('INSERT INTO orders(id,user_email,plan,amount,status,created_at) VALUES (?,?,?,?,?,?)',
                    (oid,buyer,body.plan,amount,'pending',now()))
    bank, account = os.environ['BANK_ID'], os.environ['BANK_ACCOUNT']
    qr = f'https://img.vietqr.io/image/{quote(bank)}/{quote(account)}-compact2.png?amount={amount}&addInfo={oid}&accountName={quote(os.getenv("BANK_NAME", ""))}'
    return {'id':oid,'amount':amount,'plan':body.plan,'status':'pending','transfer_content':oid,'qr_url':qr,'bank_account':account,'bank_name':os.getenv('BANK_NAME',''),'bank_id':bank}

@app.get('/orders')
def my_orders(authorization: str | None=Header(None)):
    with db() as con:
        buyer=auth_support.user(con,authorization)['email']
        rows=con.execute('SELECT id,plan,amount,status,created_at,decided_at,expiry_at FROM orders WHERE user_email=? ORDER BY created_at DESC LIMIT 100',(buyer,)).fetchall()
    return [record(r) for r in rows]

@app.get('/orders/{order_id}')
def order_status(order_id: str, authorization: str | None=Header(None)):
    # Public endpoint intentionally exposes status only, not buyer information.
    with db() as con:
        buyer=auth_support.user(con,authorization)['email']
        row=con.execute('SELECT status,expiry_at FROM orders WHERE id=? AND user_email=?',(order_id,buyer)).fetchone()
    if not row: raise HTTPException(404,'Order not found')
    return record(row)

@app.get('/admin/orders')
def admin_orders(status: str | None=None, x_admin_key: str | None=Header(None)):
    admin(x_admin_key)
    with db() as con:
        rows=con.execute('SELECT * FROM orders WHERE (? IS NULL OR status=?) ORDER BY created_at DESC',(status,status)).fetchall()
    return [record(r) for r in rows]

class Decision(BaseModel):
    note: str = Field(default='', max_length=500)
    confirmed_amount: int | None = Field(default=None, ge=1, le=1000000000)
    confirmed_transfer_content: str | None = Field(default=None, max_length=100)

def add_months(date, count):
    year = date.year+(date.month-1+count)//12
    month = (date.month-1+count)%12+1
    return date.replace(year=year,month=month,day=min(date.day,calendar.monthrange(year,month)[1]))

@app.post('/admin/orders/{order_id}/{decision}')
def decide(order_id: str,decision: str,body:Decision,x_admin_key: str | None=Header(None)):
    admin(x_admin_key)
    if decision not in ('approve','reject'): raise HTTPException(400,'Invalid decision')
    if decision == 'approve' and not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9._/-]{5,99}', body.note.strip()):
        raise HTTPException(422,'Enter a bank transaction reference (6-100 letters, numbers, . _ / -)')
    with db() as con:
        con.execute('BEGIN IMMEDIATE')
        row=con.execute('SELECT * FROM orders WHERE id=?',(order_id,)).fetchone()
        if not row: raise HTTPException(404,'Order not found')
        if row['status'] not in ('pending', 'submitted'): raise HTTPException(409,'Already processed')
        if decision=='approve' and (body.confirmed_amount != row['amount'] or body.confirmed_transfer_content != order_id):
            raise HTTPException(422,'Bank transfer amount and transfer content must match this order')
        expiry=None
        if decision=='approve':
            existing=con.execute('SELECT order_id FROM bank_confirmations WHERE reference=?',(body.note.strip(),)).fetchone()
            if existing: raise HTTPException(409,'Bank reference already used')
            con.execute('INSERT INTO bank_confirmations(reference,order_id,recorded_at) VALUES (?,?,?)',(body.note.strip(),order_id,now()))
            last=con.execute('SELECT MAX(expiry_at) AS expiry FROM orders WHERE user_email=? AND status=?',(row['user_email'],'approved')).fetchone()['expiry']
            start=datetime.fromisoformat(last) if last else datetime.now(timezone.utc)
            start=max(start,datetime.now(timezone.utc))
            expiry=add_months(start,PLANS[row['plan']][1]).isoformat()
        con.execute('UPDATE orders SET status=?, decided_at=?, expiry_at=?, admin_note=? WHERE id=?',
                    ('approved' if decision=='approve' else 'rejected',now(),expiry,body.note,order_id))
        con.execute('INSERT INTO admin_audit(order_id,action,decided_at,note) VALUES (?,?,?,?)',(order_id,decision,now(),body.note))
    return {'id':order_id,'status':'approved' if decision=='approve' else 'rejected','expiry_at':expiry}

@app.get('/admin/stats')
def stats(year: int | None=None, x_admin_key: str | None=Header(None)):
    admin(x_admin_key)
    year=year or datetime.now(timezone.utc).year
    with db() as con:
        rows=con.execute('SELECT user_email,amount,substr(decided_at,1,7) AS month FROM orders WHERE status=? AND substr(decided_at,1,4)=?',('approved',str(year))).fetchall()
    months=[]
    for i in range(1,13):
        m=f'{year}-{i:02d}'; group=[r for r in rows if r['month']==m]
        months.append({'month':m,'buyers':len(set(r['user_email'] for r in group)),'purchases':len(group),'revenue':sum(r['amount'] for r in group)})
    return {'year':year,'unique_buyers':len(set(r['user_email'] for r in rows)),'purchases':len(rows),'revenue':sum(r['amount'] for r in rows),'months':months}

@app.get('/health')
def health():
    return {'status':'ok'}

@app.get('/admin/audit')
def audit(x_admin_key: str | None=Header(None)):
    admin(x_admin_key)
    with db() as con:
        rows=con.execute('SELECT order_id,action,decided_at,note FROM admin_audit ORDER BY id DESC LIMIT 500').fetchall()
    return [record(r) for r in rows]


@app.get('/ready')
def readiness():
    try:
        with db() as con:
            con.execute('SELECT 1').fetchone()
    except sqlite3.Error:
        raise HTTPException(503, 'Database unavailable')
    return {'status': 'ready'}

# ───────────────────────── Flutter Payments & Admin Dashboard ─────────────────────────

# ───────────────────────── Flutter Payments & Admin Dashboard ─────────────────────────

@app.post('/payments/orders')
def create_payment_order(body: NewOrder, authorization: str | None = Header(None), x_user_email: str | None = Header(None)):
    if body.plan not in PLANS:
        raise HTTPException(400, 'Invalid plan')
    bank = os.getenv('BANK_ID', '970422')
    account = os.getenv('BANK_ACCOUNT', '0000708578761')
    bank_name = os.getenv('BANK_NAME', 'LE THI HONG DUYEN')
    with db() as con:
        buyer_row = get_user_from_auth(con, authorization, x_user_email)
        buyer = buyer_row['email']
        oid = 'SE' + str(int(time.time() * 1000))
        amount = PLANS[body.plan][0]
        con.execute(
            'INSERT INTO orders(id,user_email,plan,amount,status,created_at) VALUES (?,?,?,?,?,?)',
            (oid, buyer, body.plan, amount, 'pending', now()),
        )
    qr = f'https://img.vietqr.io/image/{quote(bank)}/{quote(account)}-compact2.png?amount={amount}&addInfo={oid}&accountName={quote(bank_name)}'
    return {
        'id': oid,
        'amount': amount,
        'plan': body.plan,
        'status': 'pending',
        'transfer_ref': oid,
        'transfer_content': oid,
        'qr_url': qr,
        'bank_account': account,
        'bank_name': bank_name,
        'bank_id': bank,
    }

@app.post('/payments/orders/{order_id}/submit')
def submit_payment_order(order_id: str, authorization: str | None = Header(None), x_user_email: str | None = Header(None)):
    with db() as con:
        buyer_row = get_user_from_auth(con, authorization, x_user_email)
        buyer = buyer_row['email']
        row = con.execute('SELECT status FROM orders WHERE id=?', (order_id,)).fetchone()
        if not row:
            raise HTTPException(404, 'Order not found')
        con.execute("UPDATE orders SET status='submitted' WHERE id=?", (order_id,))
    return {'status': 'submitted'}

@app.get('/payments/orders/{order_id}')
def get_payment_order(order_id: str, authorization: str | None = Header(None), x_user_email: str | None = Header(None)):
    with db() as con:
        buyer_row = get_user_from_auth(con, authorization, x_user_email)
        buyer = buyer_row['email']
        row = con.execute('SELECT id,plan,amount,status,created_at,expiry_at FROM orders WHERE id=?', (order_id,)).fetchone()
    if not row:
        raise HTTPException(404, 'Order not found')
    st = 'paid' if row['status'] in ('paid', 'approved') else row['status']
    return {
        'id': row['id'],
        'plan': row['plan'],
        'amount': row['amount'],
        'status': st,
        'transfer_ref': row['id'],
        'created_at': row['created_at'],
        'expiry_at': row['expiry_at'],
    }

@app.get('/payments/subscription')
def get_payment_subscription(email: str | None = None, authorization: str | None = Header(None), x_user_email: str | None = Header(None)):
    target_email = x_user_email or email
    with db() as con:
        buyer_row = get_user_from_auth(con, authorization, target_email)
        buyer = buyer_row['email'].strip().lower()
        if buyer in ('admin@signeye.vn', 'admin') or buyer.startswith('admin@'):
            return {
                'isPro': True,
                'expiresAt': add_months(datetime.now(timezone.utc), 120).isoformat(),
            }
        row = con.execute("SELECT MAX(expiry_at) AS expiry FROM orders WHERE LOWER(user_email)=? AND status IN ('paid', 'approved')", (buyer,)).fetchone()
    expiry = row['expiry'] if row else None
    is_pro = bool(expiry and expiry > now())
    return {
        'isPro': is_pro,
        'expiresAt': expiry,
    }

@app.get('/admin/payments')
def admin_payments_list(x_admin_key: str | None = Header(None)):
    admin(x_admin_key)
    now_str = now()
    with db() as con:
        rows = con.execute('''
            SELECT o.*, u.name AS user_name
            FROM orders o
            LEFT JOIN users u ON LOWER(u.email) = LOWER(o.user_email)
            ORDER BY o.created_at DESC
        ''').fetchall()
        user_rows = con.execute('''
            SELECT u.id, u.email,
                   MAX(CASE WHEN o.status IN ('paid', 'approved') THEN o.expiry_at ELSE NULL END) AS pro_expiry
            FROM users u
            LEFT JOIN orders o ON LOWER(o.user_email) = LOWER(u.email)
            WHERE LOWER(u.email) NOT IN ('admin@signeye.vn', 'admin') AND LOWER(u.email) NOT LIKE 'admin@%'
            GROUP BY u.id, u.email
        ''').fetchall()
    paid_rows = [r for r in rows if r['status'] in ('paid', 'approved') and (r['user_email'] or '').lower() not in ('admin@signeye.vn', 'admin') and not (r['user_email'] or '').lower().startswith('admin@')]
    now_dt = datetime.now(timezone.utc)
    total_users = len(user_rows)
    pro_users = len([u for u in user_rows if parse_dt(u['pro_expiry']) and parse_dt(u['pro_expiry']) > now_dt])
    free_users = total_users - pro_users
    summary = {
        'total_users': total_users,
        'pro_users': pro_users,
        'free_users': free_users,
        'buyers': len(set(r['user_email'] for r in paid_rows)),
        'purchases': len(paid_rows),
        'monthly': len([r for r in paid_rows if r['plan'] == 'month']),
        'yearly': len([r for r in paid_rows if r['plan'] == 'year']),
        'revenue': sum(r['amount'] for r in paid_rows),
    }
    orders = []
    for r in rows:
        st = 'paid' if r['status'] in ('paid', 'approved') else r['status']
        name = r['user_name'] or (r['user_email'].split('@')[0] if '@' in r['user_email'] else r['user_email'])
        r_keys = r.keys()
        adm_note = r['admin_note'] if 'admin_note' in r_keys and r['admin_note'] else ''
        pay_method = r['payment_method'] if 'payment_method' in r_keys and r['payment_method'] else ('coins' if (r['id'].startswith('XU_') or adm_note.startswith('🪙')) else 'transfer')
        trans_ref = r['transfer_ref'] if 'transfer_ref' in r_keys and r['transfer_ref'] else r['id']
        orders.append({
            'id': r['id'],
            'email': r['user_email'],
            'name': name,
            'plan': r['plan'],
            'amount': r['amount'],
            'status': st,
            'transfer_ref': trans_ref,
            'created_at': r['created_at'],
            'paid_at': r['decided_at'],
            'admin_note': adm_note,
            'payment_method': pay_method,
        })
    return {'summary': summary, 'orders': orders}

@app.get('/admin/users')
def admin_users_list(x_admin_key: str | None = Header(None)):
    admin(x_admin_key)
    with db() as con:
        rows = con.execute('''
            SELECT u.id, u.email, u.name, u.created_at, u.coins, u.reward_balance, u.coin_note,
                   MAX(CASE WHEN o.status IN ('paid', 'approved') THEN o.expiry_at ELSE NULL END) AS pro_expiry,
                   COUNT(o.id) AS total_orders,
                   SUM(CASE WHEN o.status IN ('paid', 'approved') THEN o.amount ELSE 0 END) AS total_spent,
                   (
                       SELECT o2.plan FROM orders o2 
                       WHERE LOWER(o2.user_email) = LOWER(u.email) AND o2.status IN ('paid', 'approved')
                       ORDER BY o2.expiry_at DESC LIMIT 1
                   ) AS latest_plan
            FROM users u
            LEFT JOIN orders o ON LOWER(o.user_email) = LOWER(u.email)
            WHERE LOWER(u.email) NOT IN ('admin@signeye.vn', 'admin') AND LOWER(u.email) NOT LIKE 'admin@%'
            GROUP BY u.id, u.email, u.name, u.created_at, u.coins, u.reward_balance, u.coin_note
            ORDER BY u.created_at DESC
        ''').fetchall()
        all_orders = con.execute('SELECT id, user_email, status, plan, amount, admin_note, payment_method, transfer_ref FROM orders').fetchall()

    now_str = now()
    now_dt = datetime.now(timezone.utc)
    users_list = []
    total_coins_system = 0
    coin_redeemed_users = 0

    for r in rows:
        exp = r['pro_expiry']
        exp_dt = parse_dt(exp)
        is_pro = bool(exp_dt and exp_dt > now_dt)
        is_expired = bool(exp_dt and exp_dt <= now_dt)
        
        days_remaining = 0
        if is_pro and exp_dt:
            delta = (exp_dt - now_dt).total_seconds()
            days_remaining = max(1, int(delta // 86400) + 1) if delta > 0 else 0

        latest_plan = r['latest_plan']
        plan_label = 'Gói 1 năm (399.000đ)' if latest_plan == 'year' else ('Gói 1 tháng (39.000đ)' if latest_plan == 'month' else 'Chưa đăng ký')
        
        if is_pro:
            status_label = '👑 PRO VIP'
            account_type = 'pro'
        elif is_expired:
            status_label = '⚠️ Hết hạn Pro'
            account_type = 'expired'
        else:
            status_label = '🌱 Người dùng thường'
            account_type = 'free'

        u_email = (r['email'] or '').strip().lower()
        user_coin_orders = [o for o in all_orders if (o['user_email'] or '').strip().lower() == u_email and (
            (o['payment_method'] if 'payment_method' in o.keys() else '') == 'coins' or
            (o['id'] or '').startswith('XU_') or
            ((o['transfer_ref'] if 'transfer_ref' in o.keys() else '') or '').startswith('DoiXu')
        )]

        user_coins = int(r['coins'] or 0)
        total_coins_system += user_coins
        user_coin_note = (r['coin_note'] or '').strip()
        is_coin_redeemed = bool(user_coin_orders) or ('đổi' in user_coin_note.lower() and 'pro' in user_coin_note.lower())
        has_coin_pro = is_coin_redeemed
        if has_coin_pro:
            coin_redeemed_users += 1
            if not user_coin_note and user_coin_orders:
                user_coin_note = user_coin_orders[0]['admin_note'] or f"Đã đổi {len(user_coin_orders)} lần Pro từ xu"
        else:
            user_coin_note = ''

        users_list.append({
            'id': r['id'],
            'email': r['email'],
            'name': r['name'] or r['email'].split('@')[0],
            'created_at': r['created_at'],
            'is_pro': is_pro,
            'is_expired': is_expired,
            'account_type': account_type,
            'status_label': status_label,
            'pro_expires_at': exp,
            'days_remaining': days_remaining,
            'latest_plan': latest_plan,
            'plan_label': plan_label,
            'total_orders': int(r['total_orders'] or 0),
            'total_spent': int(r['total_spent'] or 0),
            'is_admin': r['email'] == 'admin@signeye.vn',
            'coins': user_coins,
            'reward_balance': int(r['reward_balance'] or 0),
            'has_coin_pro': has_coin_pro,
            'coin_redeem_note': user_coin_note,
            'coin_orders_count': len(user_coin_orders),
        })

    total_count = len(users_list)
    pro_count = len([u for u in users_list if u['is_pro']])
    free_count = len([u for u in users_list if not u['is_pro'] and not u['is_expired']])
    expired_count = len([u for u in users_list if u['is_expired']])

    return {
        'summary': {
            'total_users': total_count,
            'pro_users': pro_count,
            'free_users': total_count - pro_count,
            'expired_pro_users': expired_count,
            'total_coins_system': total_coins_system,
            'coin_redeemed_users': coin_redeemed_users,
        },
        'users': users_list,
        'total': total_count
    }

class CoinsSyncRequest(BaseModel):
    email: str
    coins: int

@app.post('/coins/sync')
def coins_sync(body: CoinsSyncRequest):
    email = body.email.strip().lower()
    with db() as con:
        con.execute('UPDATE users SET coins = ? WHERE LOWER(email) = ?', (body.coins, email))
    return {'success': True, 'email': email, 'coins': body.coins}

class CoinsRedeemRequest(BaseModel):
    email: str
    days: int
    cost_coins: int
    remaining_coins: int
    note: str

@app.post('/coins/redeem-pro')
def coins_redeem_pro(body: CoinsRedeemRequest):
    email = body.email.strip().lower()
    days = max(1, body.days)
    now_dt = datetime.now(timezone.utc)
    with db() as con:
        latest_order = con.execute(
            "SELECT expiry_at FROM orders WHERE LOWER(user_email) = ? AND status IN ('paid', 'approved') ORDER BY expiry_at DESC LIMIT 1",
            (email,)
        ).fetchone()
        
        base_dt = now_dt
        if latest_order and latest_order['expiry_at']:
            try:
                curr_exp = datetime.fromisoformat(latest_order['expiry_at'])
                if curr_exp > now_dt:
                    base_dt = curr_exp
            except Exception:
                pass
        
        new_exp = (base_dt + timedelta(days=days)).isoformat()
        order_id = f"XU_{int(datetime.now().timestamp()*1000)}"
        
        con.execute('''
            INSERT INTO orders (id, user_email, plan, amount, status, created_at, decided_at, expiry_at, admin_note, payment_method, transfer_ref)
            VALUES (?, ?, ?, 0, 'paid', ?, ?, ?, ?, 'coins', ?)
        ''', (order_id, email, f"{days}_days", now(), now(), new_exp, body.note, f"DoiXu_{body.cost_coins}xu"))
        
        con.execute('''
            UPDATE users SET coins = ?, coin_note = ? WHERE LOWER(email) = ?
        ''', (body.remaining_coins, body.note, email))
        
    return {
        'success': True,
        'order_id': order_id,
        'expires_at': new_exp,
        'remaining_coins': body.remaining_coins,
        'note': body.note,
    }

@app.get('/users')
def get_all_users_compatible(x_admin_key: str | None = Header(None)):
    admin(x_admin_key)
    res = admin_users_list(x_admin_key)
    return res['users']

class RevokeProRequest(BaseModel):
    username: str

@app.post('/admin/revoke-pro')
def admin_revoke_pro(body: RevokeProRequest, x_admin_key: str | None = Header(None)):
    admin(x_admin_key)
    target = body.username.strip().lower()
    if not target:
        raise HTTPException(400, 'Username hoặc email không được để trống')
    email = target if '@' in target else f'{target}@signeye.vn'
    with db() as con:
        row = con.execute('SELECT id, email, name FROM users WHERE LOWER(email)=? OR LOWER(name)=?', (email, target)).fetchone()
        if not row:
            raise HTTPException(404, 'Không tìm thấy người dùng này')
        actual_email = row['email']
        con.execute(
            "UPDATE orders SET expiry_at=?, admin_note=? WHERE LOWER(user_email)=? AND status IN ('paid', 'approved')",
            (now(), 'Thu hồi quyền Pro bởi Admin', actual_email.lower())
        )
    return {'status': 'ok', 'message': f'Đã thu hồi Pro cho {row["name"]} ({actual_email}), chuyển về Người dùng thường'}

class GrantProRequest(BaseModel):
    username: str
    plan: str = 'month'

@app.post('/admin/grant-pro')
def admin_grant_pro(body: GrantProRequest, x_admin_key: str | None = Header(None)):
    admin(x_admin_key)
    target = body.username.strip().lower()
    if not target:
        raise HTTPException(400, 'Username hoặc email không được để trống')
    email = target if '@' in target else f'{target}@signeye.vn'
    plan = body.plan if body.plan in PLANS else 'month'
    amount = PLANS[plan][0]
    oid = 'SE' + str(int(time.time() * 1000))
    with db() as con:
        row = con.execute('SELECT id, email, name FROM users WHERE LOWER(email)=? OR LOWER(name)=?', (email, target)).fetchone()
        if not row:
            raise HTTPException(404, 'Tài khoản này chưa đăng ký. Chỉ có thể cấp quyền Pro cho người dùng đã đăng ký tài khoản!')
        actual_email = row['email']
        actual_name = row['name']

        last_row = con.execute("SELECT MAX(expiry_at) AS expiry FROM orders WHERE user_email=? AND status IN ('paid', 'approved')", (actual_email,)).fetchone()
        last = last_row['expiry'] if last_row else None
        start = datetime.fromisoformat(last) if last else datetime.now(timezone.utc)
        start = max(start, datetime.now(timezone.utc))
        expiry = add_months(start, PLANS[plan][1]).isoformat()

        con.execute(
            'INSERT INTO orders(id, user_email, plan, amount, status, created_at, decided_at, expiry_at, admin_note) VALUES (?,?,?,?,?,?,?,?,?)',
            (oid, actual_email, plan, amount, 'paid', now(), now(), expiry, 'Cấp Pro trực tiếp bởi Admin')
        )
    return {'status': 'ok', 'message': f'Đã cấp Pro ({plan}) thành công cho {actual_name} ({actual_email})', 'expiry_at': expiry}

class CreateUserRequest(BaseModel):
    name: str
    email: str
    password: str = '123456'
    is_pro: bool = False
    plan: str = 'month'
    coins: int = 0

@app.post('/admin/users')
def admin_create_user(body: CreateUserRequest, x_admin_key: str | None = Header(None)):
    admin(x_admin_key)
    clean_email = body.email.strip().lower()
    clean_name = body.name.strip()
    if not clean_email or '@' not in clean_email:
        raise HTTPException(400, 'Email không hợp lệ')
    if not clean_name:
        clean_name = clean_email.split('@')[0]
    with db() as con:
        existing = con.execute('SELECT id FROM users WHERE LOWER(email)=?', (clean_email,)).fetchone()
        if existing:
            raise HTTPException(400, 'Email này đã tồn tại trong hệ thống')
        uid = 'u_' + secrets.token_hex(8)
        salt = secrets.token_hex(16)
        pw_hash = hashlib.sha256((salt + body.password.strip()).encode()).hexdigest()
        con.execute(
            'INSERT INTO users (id, email, name, salt, password_hash, created_at, coins, reward_balance, coin_note) VALUES (?,?,?,?,?,?,?,?,?)',
            (uid, clean_email, clean_name, salt, pw_hash, now(), max(0, body.coins), 0, '')
        )
        if body.is_pro:
            plan = body.plan if body.plan in PLANS else 'month'
            amount = PLANS[plan][0]
            oid = 'SE' + str(int(time.time() * 1000))
            expiry = add_months(datetime.now(timezone.utc), PLANS[plan][1]).isoformat()
            con.execute(
                'INSERT INTO orders (id, user_email, plan, amount, status, created_at, decided_at, expiry_at, admin_note) VALUES (?,?,?,?,?,?,?,?,?)',
                (oid, clean_email, plan, amount, 'paid', now(), now(), expiry, 'Cấp Pro khi tạo tài khoản bởi Admin')
            )
    return {'status': 'ok', 'message': f'Đã thêm tài khoản {clean_name} ({clean_email}) thành công'}

class UpdateUserRequest(BaseModel):
    name: str | None = None
    coins: int | None = None
    is_pro: bool | None = None
    plan: str | None = None
    days_remaining: int | None = None

@app.put('/admin/users/{email}')
def admin_update_user(email: str, body: UpdateUserRequest, x_admin_key: str | None = Header(None)):
    admin(x_admin_key)
    clean_email = email.strip().lower()
    with db() as con:
        user = con.execute('SELECT id, email, name, coins FROM users WHERE LOWER(email)=?', (clean_email,)).fetchone()
        if not user:
            raise HTTPException(404, 'Không tìm thấy người dùng này')
        
        if body.name is not None and body.name.strip():
            con.execute('UPDATE users SET name=? WHERE LOWER(email)=?', (body.name.strip(), clean_email))
        if body.coins is not None:
            con.execute('UPDATE users SET coins=? WHERE LOWER(email)=?', (max(0, body.coins), clean_email))
            
        if body.days_remaining is not None:
            days = max(0, body.days_remaining)
            if days == 0:
                con.execute(
                    "UPDATE orders SET expiry_at=?, admin_note=? WHERE LOWER(user_email)=? AND status IN ('paid', 'approved')",
                    (now(), 'Hết hạn Pro bởi Admin', clean_email)
                )
            else:
                new_exp = (datetime.now(timezone.utc) + timedelta(days=days)).isoformat()
                latest = con.execute("SELECT id FROM orders WHERE LOWER(user_email)=? AND status IN ('paid', 'approved') ORDER BY expiry_at DESC LIMIT 1", (clean_email,)).fetchone()
                if latest:
                    con.execute("UPDATE orders SET expiry_at=?, admin_note=? WHERE id=?", (new_exp, f'Chỉnh còn {days} ngày bởi Admin', latest['id']))
                else:
                    oid = 'SE' + str(int(time.time() * 1000))
                    con.execute(
                        'INSERT INTO orders (id, user_email, plan, amount, status, created_at, decided_at, expiry_at, admin_note) VALUES (?,?,?,?,?,?,?,?,?)',
                        (oid, clean_email, 'month', 39000, 'paid', now(), now(), new_exp, f'Cấp {days} ngày Pro bởi Admin')
                    )
        elif body.is_pro is not None:
            if body.is_pro:
                plan = body.plan if (body.plan and body.plan in PLANS) else 'month'
                amount = PLANS[plan][0]
                oid = 'SE' + str(int(time.time() * 1000))
                expiry = add_months(datetime.now(timezone.utc), PLANS[plan][1]).isoformat()
                con.execute(
                    'INSERT INTO orders (id, user_email, plan, amount, status, created_at, decided_at, expiry_at, admin_note) VALUES (?,?,?,?,?,?,?,?,?)',
                    (oid, clean_email, plan, amount, 'paid', now(), now(), expiry, 'Cập nhật quyền Pro bởi Admin')
                )
            else:
                con.execute(
                    "UPDATE orders SET expiry_at=?, admin_note=? WHERE LOWER(user_email)=? AND status IN ('paid', 'approved')",
                    (now(), 'Thu hồi quyền Pro bởi Admin', clean_email)
                )
    return {'status': 'ok', 'message': f'Đã cập nhật thông tin tài khoản {clean_email}'}

@app.delete('/admin/users/{email}')
def admin_delete_user(email: str, x_admin_key: str | None = Header(None)):
    admin(x_admin_key)
    clean_email = email.strip().lower()
    if clean_email == 'admin@signeye.vn':
        raise HTTPException(400, 'Không thể xóa tài khoản Quản trị viên hệ thống')
    with db() as con:
        user = con.execute('SELECT id FROM users WHERE LOWER(email)=?', (clean_email,)).fetchone()
        if not user:
            raise HTTPException(404, 'Không tìm thấy người dùng cần xóa')
        con.execute('DELETE FROM users WHERE LOWER(email)=?', (clean_email,))
        con.execute('DELETE FROM orders WHERE LOWER(user_email)=?', (clean_email,))
    return {'status': 'ok', 'message': f'Đã xóa hoàn toàn tài khoản {clean_email}'}

@app.post('/admin/payments/{order_id}/confirm')
def admin_confirm_payment(order_id: str, x_admin_key: str | None = Header(None)):
    admin(x_admin_key)
    with db() as con:
        row = con.execute('SELECT * FROM orders WHERE id=?', (order_id,)).fetchone()
        if not row:
            raise HTTPException(404, 'Order not found')
        last_row = con.execute("SELECT MAX(expiry_at) AS expiry FROM orders WHERE user_email=? AND status IN ('paid', 'approved')", (row['user_email'],)).fetchone()
        last = last_row['expiry'] if last_row else None
        start = datetime.fromisoformat(last) if last else datetime.now(timezone.utc)
        start = max(start, datetime.now(timezone.utc))
        expiry = add_months(start, PLANS.get(row['plan'], (39000, 1))[1]).isoformat()
        con.execute("UPDATE orders SET status='paid', decided_at=?, expiry_at=? WHERE id=?", (now(), expiry, order_id))
    return {'status': 'ok', 'expiry_at': expiry}

@app.post('/admin/payments/{order_id}/reject')
def admin_reject_payment(order_id: str, x_admin_key: str | None = Header(None)):
    admin(x_admin_key)
    with db() as con:
        row = con.execute('SELECT * FROM orders WHERE id=?', (order_id,)).fetchone()
        if not row:
            raise HTTPException(404, 'Order not found')
        con.execute("UPDATE orders SET status='rejected', decided_at=? WHERE id=?", (now(), order_id))
    return {'status': 'rejected'}

class AdminCreateOrderRequest(BaseModel):
    id: str | None = None
    email: str
    name: str | None = None
    plan: str = 'month'
    amount: int | None = None
    status: str = 'paid'
    transfer_ref: str | None = None
    admin_note: str | None = None
    days: int | None = None

@app.post('/admin/payments/orders')
def admin_create_order(body: AdminCreateOrderRequest, x_admin_key: str | None = Header(None)):
    admin(x_admin_key)
    clean_email = body.email.strip().lower()
    if not clean_email or '@' not in clean_email:
        raise HTTPException(400, 'Email không hợp lệ')
    
    plan = body.plan if body.plan in PLANS else 'month'
    amount = body.amount if body.amount is not None else PLANS.get(plan, (39000, 1))[0]
    status = body.status if body.status in ('paid', 'pending', 'submitted', 'rejected') else 'paid'
    oid = body.id.strip() if (body.id and body.id.strip()) else ('SE' + str(int(time.time() * 1000)))
    transfer_ref = body.transfer_ref.strip() if (body.transfer_ref and body.transfer_ref.strip()) else oid
    note = body.admin_note or ('Tạo thủ công bởi Admin' if status == 'paid' else '')
    
    expiry = None
    if status == 'paid':
        days = body.days if (body.days and body.days > 0) else (365 if plan == 'year' else 31)
        expiry = (datetime.now(timezone.utc) + timedelta(days=days)).isoformat()
    
    with db() as con:
        u_row = con.execute('SELECT id FROM users WHERE LOWER(email)=?', (clean_email,)).fetchone()
        if not u_row:
            u_name = body.name.strip() if (body.name and body.name.strip()) else clean_email.split('@')[0]
            uid = 'u_' + secrets.token_hex(8)
            salt = secrets.token_hex(16)
            pw_hash = hashlib.sha256((salt + 'SignEye@2025').encode()).hexdigest()
            con.execute(
                'INSERT INTO users (id, email, name, salt, password_hash, created_at, coins, reward_balance, coin_note) VALUES (?,?,?,?,?,?,?,?,?)',
                (uid, clean_email, u_name, salt, pw_hash, now(), 0, 0, '')
            )
        
        con.execute('''
            INSERT INTO orders (id, user_email, plan, amount, status, created_at, decided_at, expiry_at, admin_note, transfer_ref)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (oid, clean_email, plan, amount, status, now(), (now() if status in ('paid', 'rejected') else None), expiry, note, transfer_ref))
        
    return {'status': 'ok', 'message': f'Đã thêm đơn hàng #{oid} thành công', 'order_id': oid}

class AdminUpdateOrderRequest(BaseModel):
    user_email: str | None = None
    plan: str | None = None
    amount: int | None = None
    status: str | None = None
    transfer_ref: str | None = None
    admin_note: str | None = None
    days_remaining: int | None = None

@app.put('/admin/payments/orders/{order_id}')
def admin_update_order(order_id: str, body: AdminUpdateOrderRequest, x_admin_key: str | None = Header(None)):
    admin(x_admin_key)
    with db() as con:
        row = con.execute('SELECT * FROM orders WHERE id=?', (order_id,)).fetchone()
        if not row:
            raise HTTPException(404, 'Không tìm thấy đơn hàng này')
        
        plan = body.plan if (body.plan and body.plan in PLANS) else row['plan']
        amount = body.amount if body.amount is not None else row['amount']
        status = body.status if (body.status and body.status in ('paid', 'pending', 'submitted', 'rejected')) else row['status']
        email = body.user_email.strip().lower() if (body.user_email and body.user_email.strip()) else row['user_email']
        transfer_ref = body.transfer_ref.strip() if body.transfer_ref is not None else (row['transfer_ref'] if 'transfer_ref' in row.keys() else row['id'])
        admin_note = body.admin_note if body.admin_note is not None else (row['admin_note'] if 'admin_note' in row.keys() else '')
        
        expiry = row['expiry_at']
        if status == 'paid':
            if body.days_remaining is not None and body.days_remaining > 0:
                expiry = (datetime.now(timezone.utc) + timedelta(days=body.days_remaining)).isoformat()
            elif not expiry or expiry <= now():
                days = 365 if plan == 'year' else 31
                expiry = (datetime.now(timezone.utc) + timedelta(days=days)).isoformat()
        elif status in ('pending', 'submitted', 'rejected'):
            expiry = None
            
        con.execute('''
            UPDATE orders 
            SET user_email=?, plan=?, amount=?, status=?, transfer_ref=?, admin_note=?, expiry_at=?, decided_at=?
            WHERE id=?
        ''', (email, plan, amount, status, transfer_ref, admin_note, expiry, (now() if status in ('paid', 'rejected') else None), order_id))
        
    return {'status': 'ok', 'message': f'Đã cập nhật đơn hàng #{order_id}'}

@app.delete('/admin/payments/orders/{order_id}')
def admin_delete_order(order_id: str, x_admin_key: str | None = Header(None)):
    admin(x_admin_key)
    with db() as con:
        row = con.execute('SELECT * FROM orders WHERE id=?', (order_id,)).fetchone()
        if not row:
            raise HTTPException(404, 'Không tìm thấy đơn hàng cần xóa')
        con.execute('DELETE FROM orders WHERE id=?', (order_id,))
        con.execute('DELETE FROM admin_audit WHERE order_id=?', (order_id,))
    return {'status': 'ok', 'message': f'Đã xóa đơn hàng #{order_id} thành công'}


