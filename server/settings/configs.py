"""
@author: ZHGZYANG
"""

import os
import urllib.parse
# Service wrappers may live outside the application directory.
ROOT_DIR = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))

settings = {
    'template_path': os.path.join(ROOT_DIR, "templates"),
    'static_path': os.path.join(ROOT_DIR, "static"),
    'debug': False,
    'gzip': False,
    'xsrf_cookies': False,
    'cookie_secret': os.environ.get('WATEROIL_COOKIE_SECRET', ''),
    'autoescape': 'xhtml_escape',
    'static_hash_cache':'False',
}

SERVER_PORT = 443

COOKIE_SECRET_FILENAME = '.cookie_secret'

UPLOAD_IMAGE_PATH = 'static/images'

enable_HTTPS = True
SSL_CERTFILE = os.environ.get(
    'WATEROIL_SSL_CERTFILE',
    "/etc/letsencrypt/live/wateroil.covlab.tech/fullchain.pem"
)
SSL_KEYFILE = os.environ.get(
    'WATEROIL_SSL_KEYFILE',
    "/etc/letsencrypt/live/wateroil.covlab.tech/privkey.pem"
)

enable_redis = False
PARSE_COMMAND_LINE = True

HOSTNAME = os.environ.get('WATEROIL_DB_HOST', '127.0.0.1')
PORT = os.environ.get('WATEROIL_DB_PORT', '3306')
DATABASE = os.environ.get('WATEROIL_DB_NAME', 'waterOil')
USERNAME = os.environ.get('WATEROIL_DB_USER', 'waterOil')
PASSWORD = os.environ.get('WATEROIL_DB_PASSWORD', '')
SQLALCHEMY_DATABASE_URI = 'mysql+pymysql://{}:{}@{}:{}/{}?charset=utf8'.format(
    urllib.parse.quote_plus(USERNAME),
    urllib.parse.quote_plus(PASSWORD),
    HOSTNAME,
    PORT,
    urllib.parse.quote_plus(DATABASE)
)
SQLALCHEMY_ENGINE_ECHO = False
