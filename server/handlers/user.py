"""
@author: ZHGZYANG
"""

from .base import BaseHandler
from tornado.web import MissingArgumentError
from tornado.httpclient import HTTPClient, HTTPError
from settings.models import Account
from datetime import datetime, timedelta
from utils.logger import writeAndPrint
import json

info = {'status': 200, 'msg': '', 'meta': {}}

class UserHandler(BaseHandler):
    def get(self):
        info = {'status': 200, 'msg': '', 'meta': {}}
        account = self.getAccount()
        if account is None:
            info['status'] = 8
            info['msg'] = 'Login timeout.'
            info['meta']['attempted_username'] = 'None'
            self.saveLog(location='UserHandler', status='attempt', action='Login timeout')
        else:
            try:
                info['status'] = 0
                info['msg'] = {'username': account.username, 'name': account.name, 'email': account.email}
                self.saveLog(location="UserHandler", status='success', action="Get user meta", account_id=account.id, username=account.username)
            except Exception as e:
                writeAndPrint('Error occurs at {}. Reason: {}'.format('UserHandler', str(e)))
                ref_code = str(datetime.utcnow().timestamp())
                self.saveLog(location='UserHandler', status='error', action=str(e), username=account.username, ref_code=ref_code)
                info['status'] = 9
                info['msg'] = 'Error occurred, please report the following reference codes. REF_CODE_A: ' + ref_code.split('.')[0] + ', REF_CODE_B: ' + ref_code.split('.')[1] + '.'
            info['meta']['attempted_username'] = account.username
        self.write(json.dumps(info))

    def post(self):
        info = {'status': 200, 'msg': '', 'meta': {}}
        account = self.getAccount()
        if account is None:
            info['status'] = 8
            info['msg'] = 'Login timeout.'
            info['meta']['attempted_username'] = 'None'
            self.saveLog(location='UserHandler', status='attempt', action='Login timeout')
        else:
            try:
                self.saveLog(location="UserHandler", status='attempt', action="Update user meta", account_id=account.id, username=account.username)
                name = self.get_body_argument('name')
                email = self.get_body_argument('email')
                self.orm.query(Account).filter(Account.id == account.id).update({Account.name: name, Account.email: email})
                self.orm.commit()
                info['status'] = 0
                info['msg'] = 'User profile updated successfully.'
                info['meta']['username'] = account.username
                info['meta']['name'] = name
                info['meta']['email'] = email
                self.saveLog(location="UserHandler", status='success', action="Update user meta", account_id=account.id, username=account.username)
            except MissingArgumentError as mae:
                info['status'] = 5
                info['msg'] = 'Please fill in all required fields.'
                self.saveLog(location="UserHandler", status='error', action="Missing argument", account_id=account.id, username=account.username)
            except Exception as e:
                writeAndPrint('Error occurs at {}. Reason: {}'.format('UserHandler', str(e)))
                ref_code = str(datetime.utcnow().timestamp())
                self.saveLog(location='UserHandler', status='error', action=str(e), username=account.username, ref_code=ref_code)
                info['status'] = 9
                info['msg'] = 'Error occurred, please report the following reference codes. REF_CODE_A: ' + ref_code.split('.')[0] + ', REF_CODE_B: ' + ref_code.split('.')[1] + '.'
            info['meta']['attempted_username'] = account.username
        self.write(json.dumps(info))


class UserListHandler(BaseHandler):
    def post(self):
        info = {'status': 200, 'msg': '', 'meta': {}}
        account = self.getAccount()
        if account is None:
            info['status'] = 8
            info['msg'] = 'Login timeout.'
            info['meta']['attempted_username'] = 'None'
            self.saveLog(location='UserListHandler', status='attempt', action='Login timeout')
        elif not account.role:
            info['status'] = 7
            info['msg'] = 'You are not allowed to view registered users.'
            info['meta']['attempted_username'] = account.username
            self.saveLog(location='UserListHandler', status='failed', action='Non-admin user list access', account_id=account.id, username=account.username)
        else:
            try:
                self.saveLog(location="UserListHandler", status='attempt', action="View registered users", account_id=account.id, username=account.username)
                users = self.orm.query(Account).order_by(Account.id.asc()).all()
                results = {}
                for index, user in enumerate(users):
                    results[index] = {
                        'id': user.id,
                        'username': user.username,
                        'name': user.name,
                        'email': user.email,
                        'role': 'admin' if user.role else 'user',
                        'photo_count': len(user.photos)
                    }
                info['status'] = 0
                info['msg'] = results
                info['meta']['total_count'] = len(users)
                self.saveLog(location="UserListHandler", status='success', action="View registered users", account_id=account.id, username=account.username)
            except Exception as e:
                writeAndPrint('Error occurs at {}. Reason: {}'.format('UserListHandler', str(e)))
                ref_code = str(datetime.utcnow().timestamp())
                self.saveLog(location='UserListHandler', status='error', action=str(e), username=account.username, ref_code=ref_code)
                info['status'] = 9
                info['msg'] = 'Error occurred, please report the following reference codes. REF_CODE_A: ' + ref_code.split('.')[0] + ', REF_CODE_B: ' + ref_code.split('.')[1] + '.'
            info['meta']['attempted_username'] = account.username
        self.write(json.dumps(info))
