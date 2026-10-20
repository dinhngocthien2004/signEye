"""Smoke/integration test: python -m unittest test_payments.py"""
import os, tempfile, unittest, hashlib
from pathlib import Path
from fastapi.testclient import TestClient

class PaymentsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        os.environ.update(DB_PATH=str(Path(cls.tmp.name)/'test.sqlite3'), ADMIN_API_KEY='local-test-admin-key-very-long',BANK_ID='970422',BANK_ACCOUNT='0000708578761',BANK_NAME='Le Thi Hong Duyen',MONTHLY_PRICE='39000',YEARLY_PRICE='399000')
        salt=bytes.fromhex('a1'*32); pw='test-admin-password-long'; digest=hashlib.pbkdf2_hmac('sha256',pw.encode(),salt,390000).hex()
        os.environ['ADMIN_PASSWORD_HASH']=f'pbkdf2_sha256$390000${salt.hex()}${digest}'
        import main
        cls.client=TestClient(main.app)
        login=cls.client.post('/admin/login',json={'password':'test-admin-password-long'})
        assert login.status_code==200
        cls.key={'X-Admin-Key':login.json()['token']}
    @classmethod
    def tearDownClass(cls): cls.tmp.cleanup()
    def test_end_to_end(self):
        c=self.client
        self.assertEqual(c.get('/config').json()['prices'],{'month':39000,'year':399000})
        self.assertEqual(c.get('/admin').status_code,200)
        self.assertEqual(c.get('/admin/orders').status_code,401)
        reg=c.post('/auth/register',json={'email':'student@example.com','name':'Student','password':'a-very-long-test-password'})
        self.assertEqual(reg.status_code,200)
        auth={'Authorization':'Bearer '+reg.json()['token']}
        self.assertEqual(c.post('/orders',json={'plan':'month'}).status_code,401)
        self.assertEqual(c.get('/me',headers=auth).json()['is_pro'],False)
        other=c.post('/auth/register',json={'email':'other@example.com','name':'Other','password':'other-long-password-123'}).json()
        other_auth={'Authorization':'Bearer '+other['token']}
        first=c.post('/orders',headers=auth,json={'plan':'month'});self.assertEqual(first.status_code,200)
        o=first.json();self.assertEqual(o['amount'],39000);self.assertIn(o['id'],o['qr_url'])
        self.assertEqual(c.get('/orders/'+o['id'],headers=auth).json()['status'],'pending')
        self.assertEqual(c.get('/orders/'+o['id'],headers=other_auth).status_code,404)
        self.assertEqual(c.post('/admin/orders/'+o['id']+'/approve',headers=self.key,json={'note':'MB-verified-123','confirmed_amount':38000,'confirmed_transfer_content':o['id']}).status_code,422)
        self.assertEqual(c.post('/admin/orders/'+o['id']+'/approve',headers=self.key,json={'note':'MB-verified-123','confirmed_amount':39000,'confirmed_transfer_content':o['id']}).status_code,200)
        self.assertEqual(c.post('/admin/orders/'+o['id']+'/approve',headers=self.key,json={'note':'MB-verified-123','confirmed_amount':39000,'confirmed_transfer_content':o['id']}).status_code,409)
        year=int(c.get('/admin/orders',headers=self.key).json()[0]['decided_at'][:4]);stats=c.get('/admin/stats',params={'year':year},headers=self.key).json()
        self.assertEqual((stats['unique_buyers'],stats['purchases'],stats['revenue']),(1,1,39000))
        self.assertEqual(c.get('/me',headers=auth).json()['is_pro'],True)
        self.assertEqual(c.get('/entitlements/pro',headers=auth).json()['is_pro'],True)
        self.assertEqual(c.get('/entitlements/pro',headers=other_auth).json()['is_pro'],False)
        second=c.post('/orders',headers=auth,json={'plan':'year'}).json()
        self.assertEqual(second['amount'],399000)
        self.assertEqual(c.post('/admin/orders/'+second['id']+'/approve',headers=self.key,json={'note':'MB-verified-123','confirmed_amount':399000,'confirmed_transfer_content':second['id']}).status_code,409)
        self.assertEqual(c.get('/orders/'+second['id'],headers=auth).json()['status'],'pending')
        self.assertEqual(c.post('/admin/orders/'+second['id']+'/reject',headers=self.key,json={}).status_code,200)
        self.assertEqual(c.get('/admin/stats',params={'year':year},headers=self.key).json()['revenue'],39000)
    def test_admin_login_security(self):
        c=self.client
        self.assertEqual(c.post('/admin/login',json={'password':'incorrect-password'}).status_code,401)
        self.assertEqual(c.get('/admin/orders',headers={'X-Admin-Key':os.environ['ADMIN_API_KEY']}).status_code,401)
        self.assertEqual(c.get('/entitlements/pro').status_code,401)
if __name__=='__main__': unittest.main()
