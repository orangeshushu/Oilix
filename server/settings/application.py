"""
@author: ZHGZYANG
"""

from .urls import url
from .configs import *
import tornado.web
from utils.initialize import generateCookieSecret, initDatebase, initRedis

def createAPP():
    settings['cookie_secret'] = generateCookieSecret(COOKIE_SECRET_FILENAME)
    initDatebase(SQLALCHEMY_DATABASE_URI)
    if enable_redis:
        initRedis()

    return tornado.web.Application(
        handlers=url,
        **settings
    )


application = createAPP()
