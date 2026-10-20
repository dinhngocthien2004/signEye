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
# Development: Flutter Web uses a random localhost port. Restrict production origins explicitly.
if not PRODUCTION:
    app.add_middleware(CORSMiddleware, allow_origin_regex=r"^http://(localhost|127\.0\.0\.1)(:[0-9]+)?$", allow_credentials=False, allow_methods=["GET", "POST", "OPTIONS"], allow_headers=["Authorization", "Content-Type"])
else:
    origins = [o.strip() for o in os.getenv("CORS_ORIGINS", "").split(",") if o.strip()]
    if origins:
        app.add_middleware(CORSMiddleware, allow_origins=origins, allow_credentials=False, allow_methods=["GET", "POST", "OPTIONS"], allow_headers=["Authorization", "Content-Type"])
if PRODUCTION:
    app.add_middleware(TrustedHostMiddleware, allowed_hosts=[h.strip() for h in os.environ['ALLOWED_HOSTS'].split(',') if h.strip()])
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
    return FileResponse(Path(__file__).parent / "static" / "admin.html", headers={"Cache-Control":"no-store", "X-Content-Type-Options":"nosniff", "Content-Security-Policy":"default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'"})
DB = os.getenv("DB_PATH", "./signeye.sqlite3")
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

def now(): return datetime.now(timezone.utc).isoformat()

class Credentials(BaseModel):
    email: str = Field(min_length=5,max_length=254)
    password: str = Field(min_length=1,max_length=128)
class Registration(Credentials):
    name: str = Field(min_length=1,max_length=100)

@app.post('/auth/register')
def register(body: Registration, request: Request):
    throttle("register:" + (request.client.host if request.client else "unknown"), 10, 3600)
    with db() as con:
        uid=auth_support.register(con,body.email,body.name,body.password)
        token=auth_support.session(con,uid)
    return {'token':token,'email':body.email.strip().lower(),'name':body.name.strip()}

@app.post('/auth/login')
def login(body: Credentials, request: Request):
    throttle("login:" + (request.client.host if request.client else "unknown") + ":" + body.email.lower(), 8, 300)
    with db() as con:
        uid=auth_support.authenticate(con,body.email,body.password)
        row=con.execute('SELECT name,email FROM users WHERE id=?',(uid,)).fetchone()
        token=auth_support.session(con,uid)
    return {'token':token,'email':row['email'],'name':row['name']}

@app.post('/auth/logout')
def logout(authorization: str | None=Header(None)):
    with db() as con:
        auth_support.user(con,authorization)
        con.execute('DELETE FROM sessions WHERE token_hash=?',(hashlib.sha256(authorization[7:].encode()).hexdigest(),))
    return {'ok':True}

@app.get('/me')
def me(authorization: str | None=Header(None)):
    with db() as con:
        u=auth_support.user(con,authorization)
        expiry=con.execute('SELECT MAX(expiry_at) AS expiry FROM orders WHERE user_email=? AND status=?',(u['email'],'approved')).fetchone()['expiry']
    return {'email':u['email'],'name':u['name'],'pro_expiry':expiry,'is_pro':bool(expiry and expiry>now())}

def admin(key):
    # Production admin access uses a short-lived, revocable bearer token.
    # Legacy shared-key auth is explicitly disabled unless enabled for local migration.
    if os.getenv('ALLOW_LEGACY_ADMIN_KEY') == '1' and ADMIN_KEY and len(ADMIN_KEY) >= 32 and hmac.compare_digest(key or '', ADMIN_KEY):
        return
    if not key or len(key) > 256:
        raise HTTPException(401, 'Admin authentication required')
    token_hash = hashlib.sha256(key.encode()).hexdigest()
    with db() as con:
        row = con.execute('SELECT 1 FROM admin_sessions WHERE token_hash=? AND expires_at>?', (token_hash, now())).fetchone()
    if not row:
        raise HTTPException(401, 'Admin session invalid or expired')

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
def pro_entitlement(authorization: str | None = Header(None)):
    with db() as con:
        u = auth_support.user(con, authorization)
        expiry = con.execute('SELECT MAX(expiry_at) AS expiry FROM orders WHERE user_email=? AND status=?', (u['email'], 'approved')).fetchone()['expiry']
    return {'is_pro': bool(expiry and expiry > now()), 'pro_expiry': expiry}


# Atomic, authenticated scan allowance. This prevents modified Flutter clients
# from obtaining extra allowances, but the actual AI operation must also move
# server-side before this can be considered tamper-proof billing enforcement.
with db() as con:
    con.execute("""CREATE TABLE IF NOT EXISTS scan_usage (
      user_email TEXT NOT NULL, utc_day TEXT NOT NULL, used INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY(user_email, utc_day))""")

@app.get('/features/scan/allowance')
def scan_allowance(authorization: str | None = Header(None)):
    with db() as con:
        u=auth_support.user(con, authorization)
        expiry=con.execute('SELECT MAX(expiry_at) AS expiry FROM orders WHERE user_email=? AND status=?', (u['email'],'approved')).fetchone()['expiry']
        pro=bool(expiry and expiry>now())
        day=datetime.now(timezone.utc).date().isoformat()
        row=con.execute('SELECT used FROM scan_usage WHERE user_email=? AND utc_day=?',(u['email'],day)).fetchone()
    used=row['used'] if row else 0
    return {'is_pro':pro,'remaining':None if pro else max(0,5-used),'utc_day':day}

@app.post('/features/scan/consume')
def consume_scan(authorization: str | None = Header(None)):
    with db() as con:
        con.execute('BEGIN IMMEDIATE')
        u=auth_support.user(con, authorization)
        expiry=con.execute('SELECT MAX(expiry_at) AS expiry FROM orders WHERE user_email=? AND status=?',(u['email'],'approved')).fetchone()['expiry']
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
        if row['status']!='pending': raise HTTPException(409,'Already processed')
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
