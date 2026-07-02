"""
@author: ZHGZYANG
"""

from sqlalchemy import desc
from math import radians, cos, sin, asin, sqrt
from settings.configs import enable_redis
from .base import BaseHandler
from tornado.web import MissingArgumentError
from tornado.httpclient import HTTPClient, HTTPError
from settings.models import Account, Photo
from utils.logger import writeAndPrint
import json
from datetime import datetime, timedelta
from dateutil import parser as dateparser
import geopy.distance

info = {'status': 200, 'msg': '', 'meta': {}}
ENTRIES_PER_PAGE = 50

class TagFilterHandler(BaseHandler):
    def post(self):
        account = self.getAccount()
        if account is None:
            info['status'] = 8
            info['msg'] = 'Login timeout.'
            info['meta']['attempted_username'] = 'None'
            self.saveLog(location='TagFilterHandler', status='attempt', action='Login timeout')
        else:
            try:
                self.saveLog(location="TagFilterHandler", status='attempt', action="Search Filter - Tag", account_id=account.id, username=account.username)
                
                tags = self.get_body_argument('taglist')
                taglist = ['#' + item for item in tags.split('#')]
                
                photo_list = self.orm.query(Photo).filter(Photo.tags.ilike("%{}%".format(taglist.pop()))).order_by(
                    desc(Photo.date)).all()
                results = {}
                for index, photo in enumerate(photo_list):
                    if len(taglist) != 0:
                        count = 0
                        for item in taglist:
                            if item in photo.tags:
                                count += 1
                            else:
                                break
                        if count == len(taglist):
                            results[index] = {'id': photo.id, 'path': photo.path, 'gps': photo.gps, 'detailed_gps': photo.detailed_gps, 
                                              'date': str(photo.date.date()),
                                              'result': photo.result, 'notes': photo.notes, 'tags': photo.tags}
                    else:
                        results[index] = {'id': photo.id, 'path': photo.path, 'gps': photo.gps, 'detailed_gps': photo.detailed_gps, 
                                          'date': str(photo.date.date()),
                                          'result': photo.result, 'notes': photo.notes, 'tags': photo.tags, 'username': photo.username}
                info['status'] = 0
                info['msg'] = results
                self.saveLog(location="TagFilterHandler", status='success', action="Search Filter - Tag", account_id=account.id, username=account.username)
            except MissingArgumentError as mae:
                info['status'] = 5
                info['msg'] = 'Please fill in all required fields.'
                self.saveLog(location="TagFilterHandler", status='error', action="Missing argument", account_id=account.id, username=account.username)
            except Exception as e:
                writeAndPrint('Error occurs at {}. Reason: {}'.format('TagFilterHandler', str(e)))
                ref_code = str(datetime.utcnow().timestamp())
                self.saveLog(location='TagFilterHandler', status='error', action=str(e), username=account.username, ref_code=ref_code)
                info['status'] = 9
                info['msg'] = 'Error occurred, please report the following reference codes. REF_CODE_A: ' + ref_code.split('.')[0] + ', REF_CODE_B: ' + ref_code.split('.')[1] + '.'
            info['meta']['attempted_username'] = account.username
        self.write(json.dumps(info))


class GlobalFilterHandler(BaseHandler):
    def post(self):
        account = self.getAccount()
        if account is None:
            info['status'] = 8
            info['msg'] = 'Login timeout.'
            info['meta']['attempted_username'] = 'None'
            self.saveLog(location='GlobalFilterHandler', status='attempt', action='Login timeout')
        else:
            try:
                self.saveLog(location="GlobalFilterHandler", status='attempt', action="Search Filter - Notes Global", account_id=account.id, username=account.username)
                
                try:
                    page = self.get_body_argument('page')
                    page = 0 if int(page) < 1 else int(page) - 1
                except:
                    page = 0
                
                querystring = self.get_body_argument('querystring')
                
                total_count = self.orm.query(Photo).filter(Photo.notes.ilike("%{}%".format(querystring))).count()
                photo_list = self.orm.query(Photo).filter(Photo.notes.ilike("%{}%".format(querystring))).order_by(
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
                self.saveLog(location="GlobalFilterHandler", status='success', action="Search Filter - Notes Global", account_id=account.id, username=account.username)
            except MissingArgumentError as mae:
                info['status'] = 5
                info['msg'] = 'Please fill in all required fields.'
                self.saveLog(location="GlobalFilterHandler", status='error', action="Missing argument", account_id=account.id, username=account.username)
            except Exception as e:
                writeAndPrint('Error occurs at {}. Reason: {}'.format('GlobalFilterHandler', str(e)))
                ref_code = str(datetime.utcnow().timestamp())
                self.saveLog(location='GlobalFilterHandler', status='error', action=str(e), username=account.username, ref_code=ref_code)
                info['status'] = 9
                info['msg'] = 'Error occurred, please report the following reference codes. REF_CODE_A: ' + ref_code.split('.')[0] + ', REF_CODE_B: ' + ref_code.split('.')[1] + '.'
            info['meta']['attempted_username'] = account.username
        self.write(json.dumps(info))


class GeographyFilterHandler(BaseHandler):
    def post(self):
        account = self.getAccount()
        if account is None:
            info['status'] = 8
            info['msg'] = 'Login timeout.'
            info['meta']['attempted_username'] = 'None'
            self.saveLog(location='GeographyFilterHandler', status='attempt', action='Login timeout')
        else:
            try:
                self.saveLog(location="GeographyFilterHandler", status='attempt', action="Search Filter - Geography", account_id=account.id, username=account.username)
                                
                gps = self.get_body_argument('gps')
                radius = float(self.get_body_argument('radius'))
                radiusunit = self.get_body_argument('radiusunit')
                last_token = self.get_body_argument('last_token')
                next_token = self.get_body_argument('next_token')
                request_id = self.get_body_argument('request_id')
                
                if radiusunit == 'm':
                    radius /= 1000
                elif radiusunit == 'mile':
                    radius *= 1.60934

                if self.validate_token(last_token, next_token):
                    token = self.get_token(last_token, next_token) # a number for offset
                    info['meta']['last_token'] = self.set_token(token - ENTRIES_PER_PAGE) if token - ENTRIES_PER_PAGE >= 0 else self.set_token(-1)
                    results = {}
                    if enable_redis:
                        if request_id == '-':
                            request_id = account.username + str(datetime.now().timestamp())
                            self.redis_geosearch(gps, radius, request_id)
                        photo_ids = self.redis_get_ids_by_request_id(request_id, token, ENTRIES_PER_PAGE - 1)
                        photo_ids = list(map(lambda x: int(x.decode('utf8').split(':')[1]), photo_ids))
                        token = token + len(photo_ids) if len(photo_ids) == ENTRIES_PER_PAGE else -1
                        for index, item in enumerate(photo_ids):
                            photo = self.orm.query(Photo).filter(Photo.id==item).all()[0]
                            results[index] = {'id': photo.id, 'path': photo.path, 'gps': photo.gps, 'detailed_gps': photo.detailed_gps, 
                              'date': str(photo.date.date()),
                              'result': photo.result, 'notes': photo.notes, 'tags': photo.tags, 'username': photo.username}
                    else:
                        request_id = account.username + str(datetime.now().timestamp())
                        for index in range(ENTRIES_PER_PAGE):
                            photo = self.orm.query(Photo).offset(token).limit(1).all()
                            if len(photo) == 0:
                                token = -1
                                break
                            photo = photo[0]
                            token += 1
                            if self.gpscompare(photo.gps, gps) <= radius:
                                results[index] = {'id': photo.id, 'path': photo.path, 'gps': photo.gps,
                                                  'date': str(photo.date.date()),
                                                  'result': photo.result, 'notes': photo.notes, 'tags': photo.tags, 'username': photo.username}
                    info['status'] = 0
                    info['msg'] = results
                    info['meta']['next_token'] = self.set_token(token)
                    info['meta']['request_id'] = request_id
                    self.saveLog(location="GeographyFilterHandler", status='success', action="Search Filter - Geography", account_id=account.id, username=account.username)
                else:
                    info['status'] = 6
                    info['msg'] = 'TOKENs are invalid.'
                    self.saveLog(location="GeographyFilterHandler", status='failed', action="Tokens invalid", account_id=account.id, username=account.username)
            except MissingArgumentError as mae:
                info['status'] = 5
                info['msg'] = 'Please fill in all required fields.'
                self.saveLog(location="GeographyFilterHandler", status='error', action="Missing argument", account_id=account.id, username=account.username)
            except Exception as e:
                writeAndPrint('Error occurs at {}. Reason: {}'.format('GeographyFilterHandler', str(e)))
                ref_code = str(datetime.utcnow().timestamp())
                self.saveLog(location='GeographyFilterHandler', status='error', action=str(e), username=account.username, ref_code=ref_code)
                info['status'] = 9
                info['msg'] = 'Error occurred, please report the following reference codes. REF_CODE_A: ' + ref_code.split('.')[0] + ', REF_CODE_B: ' + ref_code.split('.')[1] + '.'
            info['meta']['attempted_username'] = account.username
        self.write(json.dumps(info))


    def get_token(self, last_token, next_token):
        if last_token == '-':
            if next_token == '-':
                return 0
            else:
                return self._get_token_(next_token)
        else:
            return self._get_token_(last_token)

    def _get_token_(self, token):
        return int(''.join([chr(ord(item) - 20) for item in token]))
        
    def validate_token(self, last_token, next_token): 
        if last_token != '-':
            for item in last_token:
                if item < 'D' or item > 'M':
                    return False
        if next_token != '-':
            for item in next_token:
                if item < 'D' or item > 'M':
                    return False
        return True
    
    def set_token(self, token):
        if token == -1:
            return '-'
        return ''.join([chr(ord(item) + 20) for item in str(token)])
         
    def gpscompare(self, gps1, gps2):
        g1 = gps1.replace(' ', '').replace('(', '').replace(')', '').split(',')
        g2 = gps2.replace(' ', '').replace('(', '').replace(')', '').split(',')
        return geopy.distance.geodesic((float(g1[0]),float(g1[1])), (float(g2[0]),float(g2[1]))).km
