"""
@author: ZHGZYANG
"""

from sqlalchemy import desc

from .base import BaseHandler
from tornado.web import MissingArgumentError
from tornado.httpclient import HTTPClient, HTTPError
from settings.models import Account, Photo
from utils.logger import writeAndPrint
import json
from datetime import datetime, timedelta
from dateutil import parser as dateparser
import os

info = {'status': 200, 'msg': '', 'meta': {}}

ENTRIES_PER_PAGE = 50


class AdminLoginHandler(BaseHandler):
    def post(self):
        try:
            username = self.get_body_argument('username')
            password = self.get_body_argument('password')
            self.saveLog(location='AdminLoginHandler', status='attempt', action='Admin login', username= username)
            account = self.login(username, password)
            if account == -2:
                info['status'] = 2
                info['msg'] = 'Password and username do not match.'
                self.saveLog(location='AdminLoginHandler', status='failed', action='Password wrong', username= username)
            elif account == -1:
                info['status'] = 7
                info['msg'] = 'You are not allowed to login as administrator.'
                self.saveLog(location='AdminLoginHandler', status='failed', action='Login as asmin is prohibited', username= username)
            elif account is None:
                info['status'] = 1
                info['msg'] = 'Account does not exist.'
                self.saveLog(location='AdminLoginHandler', status='failed', action='User does not exist', username= username)
            else:
                self.saveLog(location='AdminLoginHandler', status='success', action='Admin logged in', account_id=account.id, username= username)
                info['status'] = 0
                info['msg'] = 'Login successful.'
                info['meta']['name'] = account.name
                info['meta']['email'] = account.email
        except MissingArgumentError as mae:
            info['status'] = 5
            info['msg'] = 'Please fill in all required fields.'
            self.saveLog(location='AdminLoginHandler', status='error', action='Missing argument')
        except Exception as e:
            writeAndPrint('Error occurs at {}. Reason: {}'.format('AdminLoginHandler', str(e)))
            ref_code = str(datetime.utcnow().timestamp())
            self.saveLog(location='AdminLoginHandler', status='error', action=str(e), username=username if username else '', ref_code=ref_code)
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
                self.set_secure_cookie(**self.build_cookie('account', str(account.id)))
                return account
            else:
                return -1
        else:
            return -2

    def build_cookie(self, name, value):
        domain = self.request.full_url().split('/')[2].split(':')[0]
        cookie_info = {
            'name': name,
            'value': value,
            'HttpOnly': False,
            'expires_days': 1,
            'Domain': domain,
            'SameSite': 'None',
            'Secure': True,
        }
        return cookie_info


class AdminPhotoListHandler(BaseHandler):
    def post(self):
        account = self.getAccount()
        if account is not None and not account.role:
            self.set_status(403)
            self.write(json.dumps({'status': 7, 'msg': 'Administrator access required.', 'meta': {}}))
            return
        if account is None:
            info['status'] = 8
            info['msg'] = 'Login timeout.'
            info['meta']['attempted_username'] = 'None'
            self.saveLog(location='AdminPhotoListHandler', status='attempt', action='Login timeout')
        else:
            try:
                self.saveLog(location="AdminPhotoListHandler", status='attempt', action="Admin photo list", account_id=account.id, username=account.username)
                
                mindate = self.get_body_argument('mindate')
                maxdate = self.get_body_argument('maxdate')
                try:
                    page = self.get_body_argument('page')
                    page = 0 if int(page) < 1 else int(page) - 1
                except:
                    page = 0
                
                if mindate == '-':
                    mindate = '1970-01-01'
                if maxdate == '-':
                    maxdate = datetime.utcnow().strftime("%m/%d/%Y, %H:%M:%S")
                else:
                    maxdate += ', 23:59:59'
                starttime = dateparser.parse(mindate)
                endtime = dateparser.parse(maxdate)
                
                total_count = self.orm.query(Photo).filter(Photo.date >= starttime).filter(Photo.date <= endtime).count()
                photo_list = self.orm.query(Photo).filter(Photo.date >= starttime).filter(Photo.date <= endtime).order_by(
                    desc(Photo.date)).offset(page * ENTRIES_PER_PAGE).limit(ENTRIES_PER_PAGE).all()
                results = {}
                for index, photo in enumerate(photo_list):
                    results[index] = {'id': photo.id, 'path': photo.path, 'gps': photo.gps, 'detailed_gps': photo.detailed_gps, 
                                      'date': str(photo.date.date()),
                                      'result': photo.result, 'notes': photo.notes, 'tags': photo.tags, 'username': photo.username}
                info['status'] = 0
                info['msg'] = results
                info['meta']['total_page'] = total_count // ENTRIES_PER_PAGE + 1
                info['meta']['current_page'] = page + 1
                self.saveLog(location="AdminPhotoListHandler", status='success', action="Admin photo list", account_id=account.id, username=account.username)
            except MissingArgumentError as mae:
                info['status'] = 5
                info['msg'] = 'Please fill in all required fields.'
                self.saveLog(location="AdminPhotoListHandler", status='error', action="Missing argument", account_id=account.id, username=account.username)
            except Exception as e:
                writeAndPrint('Error occurs at {}. Reason: {}'.format('AdminPhotoListHandler', str(e)))
                ref_code = str(datetime.utcnow().timestamp())
                self.saveLog(location='AdminPhotoListHandler', status='error', action=str(e), username=account.username, ref_code=ref_code)
                info['status'] = 9
                info['msg'] = 'Error occurred, please report the following reference codes. REF_CODE_A: ' + ref_code.split('.')[0] + ', REF_CODE_B: ' + ref_code.split('.')[1] + '.'
            info['meta']['attempted_username'] = account.username
        self.write(json.dumps(info))


class AdminUpdaePhotInfoHandler(BaseHandler):
    def post(self):
        account = self.getAccount()
        if account is None:
            info['status'] = 8
            info['msg'] = 'Login timeout.'
            info['meta']['attempted_username'] = 'None'
            self.saveLog(location='AdminUpdaePhotInfoHandler', status='attempt', action='Login timeout')
        else:
            try:
                self.saveLog(location="AdminUpdaePhotInfoHandler", status='attempt', action="Update photo info", account_id=account.id, username=account.username)
                notes = self.get_body_argument('notes')
                tags = self.get_body_argument('tags')
                photo_id = self.get_body_argument('photo_id')
                self.orm.query(Photo).filter(Photo.id == photo_id).update({Photo.notes: notes, Photo.tags: tags})
                self.orm.commit()
                info['status'] = 0
                info['msg'] = 'Update successful.'
                self.saveLog(location="AdminUpdaePhotInfoHandler", status='success', action="Update photo info", account_id=account.id, username=account.username)
            except MissingArgumentError as mae:
                info['status'] = 5
                info['msg'] = 'Please fill in all required fields.'
                self.saveLog(location="AdminUpdaePhotInfoHandler", status='error', action="Missing argument", account_id=account.id, username=account.username)
            except Exception as e:
                writeAndPrint('Error occurs at {}. Reason: {}'.format('AdminUpdaePhotInfoHandler', str(e)))
                ref_code = str(datetime.utcnow().timestamp())
                self.saveLog(location='AdminUpdaePhotInfoHandler', status='error', action=str(e), username=account.username, ref_code=ref_code)
                info['status'] = 9
                info['msg'] = 'Error occurred, please report the following reference codes. REF_CODE_A: ' + ref_code.split('.')[0] + ', REF_CODE_B: ' + ref_code.split('.')[1] + '.'
            info['meta']['attempted_username'] = account.username
        self.write(json.dumps(info))


class AdminUpdaePhotoNotesMultiHandler(BaseHandler):
    def post(self):
        account = self.getAccount()
        if account is None:
            info['status'] = 8
            info['msg'] = 'Login timeout.'
            info['meta']['attempted_username'] = 'None'
            self.saveLog(location='AdminUpdaePhotoNotesMultiHandler', status='attempt', action='Login timeout')
        else:
            try:
                self.saveLog(location="AdminUpdaePhotoNotesMultiHandler", status='attempt', action="Update photos notes multi", account_id=account.id, username=account.username)
                notes = self.get_body_argument('notes')
                photo_id_list = self.get_body_argument('photo_id_list').replace(' ','').split(',')
                for photo_id in photo_id_list:
                    self.orm.query(Photo).filter(Photo.id == photo_id).update({Photo.notes: notes})
                self.orm.commit()
                info['status'] = 0
                info['msg'] = 'Update successful.'
                self.saveLog(location="AdminUpdaePhotoNotesMultiHandler", status='success', action="Update photos notes multi", account_id=account.id, username=account.username)
            except MissingArgumentError as mae:
                info['status'] = 5
                info['msg'] = 'Please fill in all required fields.'
                self.saveLog(location="AdminUpdaePhotoNotesMultiHandler", status='error', action="Missing argument", account_id=account.id, username=account.username)
            except Exception as e:
                writeAndPrint('Error occurs at {}. Reason: {}'.format('AdminUpdaePhotoNotesMultiHandler', str(e)))
                ref_code = str(datetime.utcnow().timestamp())
                self.saveLog(location='AdminUpdaePhotoNotesMultiHandler', status='error', action=str(e), username=account.username, ref_code=ref_code)
                info['status'] = 9
                info['msg'] = 'Error occurred, please report the following reference codes. REF_CODE_A: ' + ref_code.split('.')[0] + ', REF_CODE_B: ' + ref_code.split('.')[1] + '.'
            info['meta']['attempted_username'] = account.username
        self.write(json.dumps(info))


class AdminUpdaePhotoTagsMultiHandler(BaseHandler):
    def post(self):
        account = self.getAccount()
        if account is None:
            info['status'] = 8
            info['msg'] = 'Login timeout.'
            info['meta']['attempted_username'] = 'None'
            self.saveLog(location='AdminUpdaePhotoTagsMultiHandler', status='attempt', action='Login timeout')
        else:
            try:
                self.saveLog(location="AdminUpdaePhotoTagsMultiHandler", status='attempt', action="Update photo tags multi", account_id=account.id, username=account.username)
                tags = self.get_body_argument('tags')
                photo_id_list = self.get_body_argument('photo_id_list').replace(' ','').split(',')
                for photo_id in photo_id_list:
                    self.orm.query(Photo).filter(Photo.id == photo_id).update({Photo.tags: tags})
                self.orm.commit()
                info['status'] = 0
                info['msg'] = 'Update successful.'
                self.saveLog(location="AdminUpdaePhotoTagsMultiHandler", status='success', action="Update photo tags multi", account_id=account.id, username=account.username)
            except MissingArgumentError as mae:
                info['status'] = 5
                info['msg'] = 'Please fill in all required fields.'
                self.saveLog(location="AdminUpdaePhotoTagsMultiHandler", status='error', action="Missing argument", account_id=account.id, username=account.username)
            except Exception as e:
                writeAndPrint('Error occurs at {}. Reason: {}'.format('AdminUpdaePhotoTagsMultiHandler', str(e)))
                ref_code = str(datetime.utcnow().timestamp())
                self.saveLog(location='AdminUpdaePhotoTagsMultiHandler', status='error', action=str(e), username=account.username, ref_code=ref_code)
                info['status'] = 9
                info['msg'] = 'Error occurred, please report the following reference codes. REF_CODE_A: ' + ref_code.split('.')[0] + ', REF_CODE_B: ' + ref_code.split('.')[1] + '.'
            info['meta']['attempted_username'] = account.username
        self.write(json.dumps(info))
        

class DeletePhotoHandler(BaseHandler):
    def post(self):
        account = self.getAccount()
        if account is None:
            info['status'] = 8
            info['msg'] = 'Login timeout.'
            info['meta']['attempted_username'] = 'None'
            self.saveLog(location='DeletePhotoHandler', status='attempt', action='Login timeout')
        else:
            try:
                self.saveLog(location="DeletePhotoHandler", status='attempt', action="Delete photo", account_id=account.id, username=account.username)
                photo_id = self.get_body_argument('photo_id')
                pending_photo = self.orm.get(Photo, photo_id)
                path = pending_photo.path
                os.remove(path)
                self.orm.delete(pending_photo)
                self.orm.commit()
                info['status'] = 0
                info['msg'] = 'Delete successful.'
                self.saveLog(location="DeletePhotoHandler", status='success', action="Delete photo " + str(photo_id), account_id=account.id, username=account.username)
            except MissingArgumentError as mae:
                info['status'] = 5
                info['msg'] = 'Please fill in all required fields.'
                self.saveLog(location="DeletePhotoHandler", status='error', action="Missing argument", account_id=account.id, username=account.username)
            except Exception as e:
                writeAndPrint('Error occurs at {}. Reason: {}'.format('DeletePhotoHandler', str(e)))
                ref_code = str(datetime.utcnow().timestamp())
                self.saveLog(location='DeletePhotoHandler', status='error', action=str(e), username=account.username, ref_code=ref_code)
                info['status'] = 9
                info['msg'] = 'Error occurred, please report the following reference codes. REF_CODE_A: ' + ref_code.split('.')[0] + ', REF_CODE_B: ' + ref_code.split('.')[1] + '.'
            info['meta']['attempted_username'] = account.username
        self.write(json.dumps(info))
        

class DeletePhotoMultiHandler(BaseHandler):
    def post(self):
        account = self.getAccount()
        if account is None:
            info['status'] = 8
            info['msg'] = 'Login timeout.'
            info['meta']['attempted_username'] = 'None'
            self.saveLog(location='DeletePhotoMultiHandler', status='attempt', action='Login timeout')
        else:
            try:
                self.saveLog(location="DeletePhotoMultiHandler", status='attempt', action="Delete multi photos", account_id=account.id, username=account.username)
                photo_id_list = self.get_body_argument('photo_id_list').replace(' ','').split(',')
                for photo_id in photo_id_list:
                    pending_photo = self.orm.get(Photo, photo_id)
                    path = pending_photo.path
                    os.remove(path)
                    self.orm.delete(pending_photo)
                self.orm.commit()
                info['status'] = 0
                info['msg'] = 'Delete successful.'
                self.saveLog(location="DeletePhotoMultiHandler", status='success', action="Delete photos " + str(photo_id_list), account_id=account.id, username=account.username)
            except MissingArgumentError as mae:
                info['status'] = 5
                info['msg'] = 'Please fill in all required fields.'
                self.saveLog(location="DeletePhotoMultiHandler", status='error', action="Missing argument", account_id=account.id, username=account.username)
            except Exception as e:
                writeAndPrint('Error occurs at {}. Reason: {}'.format('DeletePhotoMultiHandler', str(e)))
                ref_code = str(datetime.utcnow().timestamp())
                self.saveLog(location='DeletePhotoMultiHandler', status='error', action=str(e), username=account.username, ref_code=ref_code)
                info['status'] = 9
                info['msg'] = 'Error occurred, please report the following reference codes. REF_CODE_A: ' + ref_code.split('.')[0] + ', REF_CODE_B: ' + ref_code.split('.')[1] + '.'
            info['meta']['attempted_username'] = account.username
        self.write(json.dumps(info))
