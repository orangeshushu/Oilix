"""
@author: ZHGZYANG
"""

from .base import BaseHandler
from tornado.web import MissingArgumentError
from tornado.httpclient import HTTPClient, HTTPError
from settings.models import Account
from utils.logger import writeAndPrint
from datetime import datetime, timedelta
import json

from platform import python_version
from packaging import version

info = {'status': 200, 'msg': '', 'meta': {}}

class LoginHandler(BaseHandler):
    def post(self):
        try:
            username = self.get_body_argument('username')
            self.saveLog(location="LoginHandler", status='attempt', action="Login", username=username if username else None)
            password = self.get_body_argument('password')
            account = self.login(username, password)
            if account == -2:
                info['status'] = 2
                info['msg'] = 'Password and username do not match.'
                self.saveLog(location="LoginHandler", status='failed', action="Password wrong", username=username)
            elif account == -3:
                info['status'] = 7
                info['msg'] = 'Administrator accounts must use Admin Login.'
                self.saveLog(location="LoginHandler", status='failed', action="Admin tried normal login", username=username)
            elif account is None:
                info['status'] = 1
                info['msg'] = 'Account does not exist.'
                self.saveLog(location="LoginHandler", status='failed', action="User does not exist", username=username)
            else:
                info['status'] = 0
                info['msg'] = 'Login successful.'
                info['meta']['name'] = account.name
                info['meta']['email'] = account.email
                self.saveLog(location="LoginHandler", status='success', action="Logged in", account_id=account.id, username=account.username)
        except MissingArgumentError as mae:
            info['status'] = 5
            info['msg'] = 'Please fill in all required fields.'
            self.saveLog(location="LoginHandler", status='error', action="Missing argument", account_id=account.id if account else 'Undefined', username=account.username if account else 'Undefined')#250613 "if account else 'Undefined'"added
        except Exception as e:
            writeAndPrint('Error occurs at {}. Reason: {}'.format('LoginHandler', str(e)))
            ref_code = str(datetime.utcnow().timestamp())
            self.saveLog(location='LoginHandler', status='error', action=str(e), username=account.username if account else 'Undefined', ref_code=ref_code)#250613 "if account else 'Undefined'"added
            info['status'] = 9
            info['msg'] = 'Error occurred, please report the following reference codes. REF_CODE_A: ' + ref_code.split('.')[0] + ', REF_CODE_B: ' + ref_code.split('.')[1] + '.'
        try:
            info['meta']['attempted_username'] = username
        except Exception as e:
            info['meta']['attempted_username'] = 'None'
        self.write(json.dumps(info))

    def login(self, username, pswd):
        account = self.orm.query(Account).filter(Account.username == username).first()
        if account is None:
            return None
        elif account.password == pswd:
            if account.role:
                return -3
            if version.parse(python_version()) < version.parse("3.8"):
                try:
                    from http.cookies import Morsel
                except ImportError:
                    from Cookie import Morsel
                Morsel._reserved['samesite'] = 'SameSite'
            self.set_secure_cookie(**self.build_cookie('account', str(account.id))) #only https can use this
            return account
        else:
            return -2
    
    def build_cookie(self, name, value):
        cookie_info = {
            'name': name,
            'value': value,
            'HttpOnly': True,
            'expires_days': 1,
            'Domain': self.request.full_url().split('/')[2].split(':')[0],
            'SameSite': 'None',
            'Secure': True,
        }
        return cookie_info


class LogoutHandler(BaseHandler):
    def get(self):
        self.saveLog(location="LogoutHandler", status='attempt', action="Logout")
        account = self.getAccount()
        if account is not None:
            self.saveLog(location="LogoutHandler", status='success', action="Logout", account_id=account.id, username=account.username)
            self.clear_cookie("account")
        info['status'] = 0
        info['msg'] = 'Logout successful.'
        self.write(json.dumps(info))

        
