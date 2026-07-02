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

info = {'status': 200, 'msg': '', 'meta': {}}

class RegisterHandler(BaseHandler):
    def post(self):
        try:
            self.saveLog(location='RegisterHandler', status='attempt', action='Register')
            username = self.get_body_argument('username')
            password = self.get_body_argument('password')
            email = self.get_body_argument('email')
            name = self.get_body_argument('name')
            account = self.orm.query(Account).filter(Account.username == username).first()
            if account is None:
                account = Account()
                account.username = username
                account.password = password
                account.role = False
                account.name = name
                account.email = email
                self.orm.add(account)
                self.orm.commit()
                self.set_secure_cookie(**self.build_cookie('account', str(account.id)))
                info['status'] = 0
                info['msg'] = 'Register successful.'
                self.saveLog(location="RegisterHandler", status='success', action="Register", account_id=account.id, username=account.username)
            else:
                info['status'] = 3
                info['msg'] = 'Username has been used.'
                self.saveLog(location="RegisterHandler", status='failed', action="Username used", username=account.username)
        except MissingArgumentError as mae:
            info['status'] = 5
            info['msg'] = 'Please fill in all required fields.'
            self.saveLog(location="RegisterHandler", status='error', action="Missing argument")
        except Exception as e:
            writeAndPrint('Error occurs at {}. Reason: {}'.format('RegisterHandler', str(e)))
            ref_code = str(datetime.utcnow().timestamp())
            self.saveLog(location='RegisterHandler', status='error', action=str(e), username=username if username else '', ref_code=ref_code)
            info['status'] = 9
            info['msg'] = 'Error occurred, please report the following reference codes. REF_CODE_A: ' + ref_code.split('.')[0] + ', REF_CODE_B: ' + ref_code.split('.')[1] + '.'
        info['meta']['attempted_username'] = username if username else 'None'
        self.write(json.dumps(info))
        
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


class ResetPasswordHandler(BaseHandler):
    def post(self):
        try:
            username = self.get_body_argument('username')
            self.saveLog(location="ResetPasswordHandler", status='attempt', action="Reset password",username=username if username else 'None')
            email = self.get_body_argument('email')
            pswd = self.get_body_argument('password')
            account = self.orm.query(Account).filter(Account.username == username).first()
            if account is not None:
                if account.email == email:
                    self.orm.query(Account).filter(Account.username == username).update({Account.password: pswd})
                    self.orm.commit()
                    info['status'] = 0
                    info['msg'] = 'New password has been set successfully.'
                    self.saveLog(location="ResetPasswordHandler", status='success', action="Reset password", account_id=account.id, username=account.username)
                else:
                    info['status'] = 2
                    info['msg'] = 'Email address does not match.'
                    self.saveLog(location="ResetPasswordHandler", status='failed', action="Email does not match", account_id=account.id, username=account.username)
            else:
                info['status'] = 1
                info['msg'] = 'Username does not exist.'
                self.saveLog(location="ResetPasswordHandler", status='failed', action="No such username", username=username)
        except MissingArgumentError as mae:
            info['status'] = 5
            info['msg'] = 'Please fill in all required fields.'
            self.saveLog(location="ResetPasswordHandler", status='error', action="Missing argument", account_id=account.id, username=account.username)
        except Exception as e:
            writeAndPrint('Error occurs at {}. Reason: {}'.format('ResetPasswordHandler', str(e)))
            ref_code = str(datetime.utcnow().timestamp())
            self.saveLog(location='ResetPasswordHandler', status='error', action=str(e), username=account.username, ref_code=ref_code)
            info['status'] = 9
            info['msg'] = 'Error occurred, please report the following reference codes. REF_CODE_A: ' + ref_code.split('.')[0] + ', REF_CODE_B: ' + ref_code.split('.')[1] + '.'
        info['meta']['attempted_username'] = username if username else 'None'
        self.write(json.dumps(info))

class DeleteUserHandler(BaseHandler):
    def post(self):
        account = self.getAccount()
        if account is None:
            info['status'] = 8
            info['msg'] = 'Login timeout.'
            info['meta']['attempted_username'] = 'None'
            self.saveLog(location='DeleteUserHandler', status='attempt', action='Login timeout')
        else:
            try:
                self.saveLog(location="DeleteUserHandler", status='attempt', action="Delete user", account_id=account.id, username=account.username)
                account_id=account.id
                pending_user = self.orm.get(Account, account_id)
                self.orm.delete(pending_user)
                self.orm.commit()
                info['status'] = 0
                info['msg'] = 'Delete user successful.'
                self.saveLog(location="DeleteUserHandler", status='success', action="Delete user " + str(pending_user), account_id=account.id, username=account.username)
            except MissingArgumentError as mae:
                info['status'] = 5
                info['msg'] = 'Please fill in all required fields.'
                self.saveLog(location="DeleteUserHandler", status='error', action="Missing argument", account_id=account.id, username=account.username)
            except Exception as e:
                writeAndPrint('Error occurs at {}. Reason: {}'.format('DeleteUserHandler', str(e)))
                ref_code = str(datetime.utcnow().timestamp())
                self.saveLog(location='DeleteUserHandler', status='error', action=str(e), username=account.username, ref_code=ref_code)
                info['status'] = 9
                info['msg'] = 'Error occurred, please report the following reference codes. REF_CODE_A: ' + ref_code.split('.')[0] + ', REF_CODE_B: ' + ref_code.split('.')[1] + '.'
            info['meta']['attempted_username'] = account.username
        self.write(json.dumps(info))