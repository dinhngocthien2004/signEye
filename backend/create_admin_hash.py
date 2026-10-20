"""Generate a password verifier. Never commit the output or password."""
import getpass, hashlib, secrets
p = getpass.getpass('New admin password (16+ chars): ')
if len(p) < 16: raise SystemExit('Password must be at least 16 characters')
salt=secrets.token_bytes(32); iterations=390000
print('ADMIN_PASSWORD_HASH=pbkdf2_sha256$%d$%s$%s' % (iterations,salt.hex(),hashlib.pbkdf2_hmac('sha256',p.encode(),salt,iterations).hex()))
