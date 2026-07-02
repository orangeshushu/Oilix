"""
@author: ZHGZYANG
"""

from .base import BaseHandler
from tornado.web import MissingArgumentError
from settings.models import Photo
from settings.configs import UPLOAD_IMAGE_PATH
from utils.stringop import generateFileName
from settings.configs import enable_redis
from utils.checker import *
from utils.logger import writeAndPrint
from datetime import datetime, timedelta
from utils.model import model_predict
import os
import json
import re
from geopy.geocoders import Nominatim
import random

info = {'status': 200, 'msg': '', 'meta': {}}

def gps_check(string):
    #pattern = "^-?[1-9]\d*\.?\d*|0\.\d*[1-9]\d*$"
    pattern = "^-?[0-9]\d*\.?\d*|0\.\d*[0-9]\d*$"
    return re.match(pattern, string)

class PhotoUploadHandler(BaseHandler):
    def post(self):
        account = self.getAccount()
        if account is None:
            info['status'] = 8
            info['msg'] = 'Login timeout.'
            info['meta']['attempted_username'] = 'None'
            self.saveLog(location='PhotoUploadHandler', status='attempt', action='Login timeout')
        else:
            try:
                self.saveLog(location="PhotoUploadHandler", status='attempt', action="Upload photo", account_id=account.id, username=account.username)
                photo = self.request.files['photo']
                gps = self.get_body_argument('gps').replace(' ','')
                notes = self.get_body_argument('notes')
                
                if (',' in gps) and (gps_check(gps.split(',')[0]) != None) and (gps_check(gps.split(',')[1]) != None):
                    if len(photo) == 1:
                        photo = photo[0]
                        photo_postfix = checkImage(photo['body'])
                        photo_name = generateFileName() + '.' + photo_postfix
                        photo_path = os.path.join(UPLOAD_IMAGE_PATH, photo_name)
                        with open(photo_path, 'wb') as fp:
                            fp.write(photo['body'])
                           
                        if gps == '0,0' or gps == '1,1':
                            city = 'Test city'
                            state = 'Test state'
                            country = 'USA'
                        else:
                            geolocator = Nominatim(user_agent=str(random.random())[2:])
                            location = geolocator.reverse(gps)
                            address = location.raw['address']
                            city = address.get('city', '')
                            state = address.get('state', '')
                            country = address.get('country', '')
                        
                        image = Photo()
                        image.gps = gps
                        image.path = photo_path
                        image.notes = notes
                        image.detailed_gps = city + ', ' + state + ', ' + country
                        image.account_id = account.id
                        image.username = account.username
                        image.result = model_predict(image.path)
                        self.orm.add(image)
                        self.orm.commit()
                        
                        if enable_redis:
                            self.redis_geoadd(image)                            
                        
                        info['status'] = 0
                        info['msg'] = 'Upload successful.'
                        info['meta']['result'] = image.result
                        self.saveLog(location="PhotoUploadHandler", status='success', action="Upload photo", account_id=account.id, username=account.username)
                    else:
                        info['status'] = 4
                        info['msg'] = 'Image is not uploaded.'
                        self.saveLog(location="PhotoUploadHandler", status='failed', action="len(photo)!=1", account_id=account.id, username=account.username)
                else:
                    info['status'] = 6
                    info['msg'] = 'GPS error.'
                    self.saveLog(location="PhotoUploadHandler", status='failed', action="GPS error", account_id=account.id, username=account.username)
            except AttributeError as ae:
                writeAndPrint(str(ae))
                info['status'] = 6
                info['msg'] = 'GPSError. The GPS coordinate is not valid.'
                self.saveLog(location="PhotoUploadHandler", status='error', action="Attribute error " + str(ae), account_id=account.id, username=account.username)
            except KeyError as ke:
                writeAndPrint(str(ke))
                info['status'] = 2
                info['msg'] = 'KeyError. Please upload correct image.'
                self.saveLog(location="PhotoUploadHandler", status='error', action="Key error " + str(ke), account_id=account.id, username=account.username)
            except ValueError as ve:
                writeAndPrint(str(ve))
                info['status'] = 2
                info['msg'] = 'The image has been flagged for not meeting quality control criteria.'
                self.saveLog(location="PhotoUploadHandler", status='error', action="Value error(image not related to project) " + str(ve), account_id=account.id, username=account.username)
            except MissingArgumentError as mae:
                info['status'] = 5
                info['msg'] = 'Please fill in all required fields.'
                self.saveLog(location="PhotoUploadHandler", status='error', action="Missing argument", account_id=account.id, username=account.username)
            except ArgException as ae:
                info['status'] = 6
                info['msg'] = 'Please upload only image file.'
                self.saveLog(location="PhotoUploadHandler", status='error', action="Not only images uploaded. " + str(ae), account_id=account.id, username=account.username)
            except Exception as e:
                writeAndPrint('Error occurs at {}. Reason: {}'.format('PhotoUploadHandler', str(e)))
                ref_code = str(datetime.utcnow().timestamp())
                self.saveLog(location='PhotoUploadHandler', status='error', action=str(e), username=account.username, ref_code=ref_code)
                info['status'] = 9
                info['msg'] = 'Error occurred, please report the following reference codes. REF_CODE_A: ' + ref_code.split('.')[0] + ', REF_CODE_B: ' + ref_code.split('.')[1] + '.'
            info['meta']['attempted_username'] = account.username
        self.set_header('Access-Control-Allow-Headers', ','.join(
            self.request.headers.get('Access-Control-Request-Headers', '').split(',') +
            ['Content-Type']
        ))
        self.set_header('Content-Type', 'multipart/form-data; boundary=???')
        self.write(json.dumps(info))
