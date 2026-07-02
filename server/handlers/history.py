"""
@author: ZHGZYANG
"""

from sqlalchemy import desc

from .base import BaseHandler
from tornado.web import MissingArgumentError
from settings.models import Photo
from settings.configs import UPLOAD_IMAGE_PATH
from utils.stringop import generateFileName
from utils.checker import *
from utils.logger import writeAndPrint
from datetime import datetime, timedelta
import os
import json

info = {'status': 200, 'msg': '', 'meta': {}}
ENTRIES_PER_PAGE = 500 #250617: was 50, changed to 500 by Sam

class HistoryHandler(BaseHandler):
    def post(self):
        account = self.getAccount()
        if account is None:
            info['status'] = 8
            info['msg'] = 'Login timeout.'
            info['meta']['attempted_username'] = 'None'
            self.saveLog(location='HistoryHandler', status='attempt', action='Login timeout')
        else:
            try:
                self.saveLog(location="HistoryHandler", status='attempt', action="View history", account_id=account.id, username=account.username)
                try:
                    page = self.get_body_argument('page')
                    page = 0 if int(page) < 1 else int(page) - 1
                except:
                    page = 0
            
                photo_list = account.photos
                results = {}
                count = 0
                for index, photo in enumerate(photo_list[page * ENTRIES_PER_PAGE:]):
                    if count == ENTRIES_PER_PAGE:
                        break
                    count += 1
                    results[count] = {'id': photo.id, 'path': photo.path, 'gps': photo.gps, 'detailed_gps': photo.detailed_gps, 
                                      'date': str(photo.date.date()), 'result': photo.result, 'notes': photo.notes, 'tags': photo.tags}
                info['status'] = 0
                info['msg'] = results
                info['meta']['total_page'] = len(photo_list) // ENTRIES_PER_PAGE + 1
                info['meta']['current_page'] = page + 1
                self.saveLog(location="HistoryHandler", status='success', action="View history", account_id=account.id, username=account.username)
            except Exception as e:
                writeAndPrint('Error occurs at {}. Reason: {}'.format('HistoryHandler', str(e)))
                ref_code = str(datetime.utcnow().timestamp())
                self.saveLog(location='HistoryHandler', status='error', action=str(e), username=account.username, ref_code=ref_code)
                info['status'] = 9
                info['msg'] = 'Error occurred, please report the following reference codes. REF_CODE_A: ' + ref_code.split('.')[0] + ', REF_CODE_B: ' + ref_code.split('.')[1] + '.'
            info['meta']['attempted_username'] = account.username
        self.write(json.dumps(info))
