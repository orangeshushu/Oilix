"""
@author: ZHGZYANG
"""

import tornado.web
from tornado.web import RequestHandler
from settings.models import db, Account, Log
from settings.configs import enable_redis
import functools, urllib.parse as urlparse
from urllib.parse import urlencode
from datetime import timedelta


class BaseHandler(RequestHandler):
    level = 0
    @property
    def orm(self):
        return db()
        
    def redis_geoadd(self, photo):
        if enable_redis:
            from settings.redises import redis_cache
            redis_cache.geoadd('wateroil', (float(photo.gps.split(',')[1]), float(photo.gps.split(',')[0]), 'id: ' + str(photo.id)))
            
    def redis_geosearch(self, gps, radius, request_id):
        from settings.redises import redis_cache
        photo_list = redis_cache.geosearch('wateroil', longitude=float(gps.split(',')[1]), latitude=float(gps.split(',')[0]), unit='km', radius=radius, sort='ASC')
        redis_cache.rpush(request_id, *photo_list)
        redis_cache.expire(request_id, timedelta(days=1))
        
    def redis_get_ids_by_request_id(self, request_id, start, stop):
        from settings.redises import redis_cache
        return redis_cache.lrange(request_id, start, stop)        

    def getIntCookie(self, key):
        value = self.get_secure_cookie(key, None)
        return None if value is None else int(value)

    def get_current_user(self):
        return self.getIntCookie('account')

    def getAccount(self):
        account = None
        account_id = self.get_current_user()
        if account_id is not None:
            account = self.orm.query(Account).filter(Account.id == account_id).first()
        return account

    def saveLog(self, location, action, status, account_id=None, username=None, ref_code=None):
        log = Log()
        log.location = location
        log.action = action
        log.status = status
        log.ip = self.request.headers.get("X-Real-IP") or self.request.headers.get("X-Forwarded-For") or self.request.remote_ip
        log.account_id = account_id
        log.username = username
        log.ref_code = ref_code
        self.orm.add(log)
        try:
            self.orm.commit()
        except:
            self.orm.rollback()
            print("rollback")
            raise#try except added on 250613

    def set_default_headers(self):
        if self.request.headers.get('Origin') != None:
            self.set_header("Access-Control-Allow-Origin", self.request.headers.get('Origin'))
        else:
            self.set_header("Access-Control-Allow-Origin", "*")
        self.set_header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept")
        self.set_header('Access-Control-Allow-Methods', 'POST, GET, OPTIONS, PUT, DELETE')
        self.set_header('Access-Control-Allow-Credentials', 'true')

    def options(self):
        self.set_status(204)
        self.finish()
        