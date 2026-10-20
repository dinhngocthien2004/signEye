# SignEye payment integration — deployment checklist

## Implemented in this development archive
- Flutter monthly/yearly QR purchase screen and account-bound purchase history.
- FastAPI authenticated account, order creation, status, approval/rejection, SQLite storage.
- Web admin dashboard for monthly/yearly buyers, purchases, revenue, CSV and order review.
- Admin approval audit records and mandatory verification note; duplicate approval prevented.
- Basic login throttling and HTTP security headers.
- Prices: 39,000 VND monthly and 399,000 VND yearly.

## Important limitations before taking real payments
- Admin key is entered in a web form; replace with proper administrator identities, MFA, short-lived sessions and role-based authorization.
- Add email ownership verification, password reset and account recovery.
- Replace single-node in-memory throttling with shared Redis-based throttling.
- Add HTTPS and real production secrets, backup/restore and monitoring.
- Enforce Pro entitlements on the server for *every* premium API. Do not rely on local Flutter flags.
- Reconcile each manual payment in the actual bank app before approval; QR generation is not bank transaction verification.
- Review privacy/retention policies and accounting reconciliation.
- Run Flutter analyze/test and device integration tests on a Flutter-equipped machine.
- Avoid printing tokens, banking data, or request bodies in production access logs.

## Local development
cd backend
python -m pip install -r requirements.txt
cp .env.example .env  # Windows: copy .env.example .env
# Set ADMIN_API_KEY to a unique random value; protect .env.
python -m uvicorn main:app --env-file .env --host 127.0.0.1 --port 8000
python -m unittest test_payments.py -v

Dashboard: http://127.0.0.1:8000/admin
Flutter Android emulator: flutter run --dart-define=PAYMENT_API_URL=http://10.0.2.2:8000
Use an HTTPS API URL on real devices.
