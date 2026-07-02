"""
@author: ZHGZYANG
"""

import os
import base64
import itertools

def initDatebase(database_uri):
    from sqlalchemy_utils import database_exists, create_database
    from settings.models import Base, engine

    if not database_exists(database_uri) and not database_uri.startswith('mysql'):
        create_database(database_uri)
    Base.metadata.create_all(engine)

def generateCookieSecret(cs_filename):
    with open(cs_filename, 'ab+') as secret:
        secret.seek(0)
        key = base64.b64encode(secret.read())
        if not key:
            raw_key = os.urandom(32)
            secret.write(raw_key)
            key = base64.b64encode(raw_key)
            secret.flush()
    return key

def initRedis():
    from settings.redises import redis_cache
    from settings.models import db, Photo
    
    for i in itertools.count():
        photo_list = db().query(Photo).offset(i * 1000).limit(1000).all()
        if not photo_list:
            break
        for photo in photo_list:
            redis_cache.geoadd('wateroil', (float(photo.gps.split(',')[1]), float(photo.gps.split(',')[0]), 'id: ' + str(photo.id)))

        
