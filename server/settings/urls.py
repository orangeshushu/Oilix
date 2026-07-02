"""
@author: ZHGZYANG
"""

from handlers.login import LoginHandler, LogoutHandler
from handlers.register import RegisterHandler, ResetPasswordHandler, DeleteUserHandler
from handlers.photo import PhotoUploadHandler
from handlers.history import HistoryHandler
from handlers.admin import AdminLoginHandler, AdminPhotoListHandler, AdminUpdaePhotInfoHandler, DeletePhotoHandler, DeletePhotoMultiHandler, AdminUpdaePhotoTagsMultiHandler, AdminUpdaePhotoNotesMultiHandler
from handlers.user import UserHandler, UserListHandler
from handlers.searchFilter import TagFilterHandler, GlobalFilterHandler, GeographyFilterHandler
import tornado.web


url = [
    (r'/assets/(.*)', tornado.web.StaticFileHandler, {'path': '/wateroil/static/console/public/assets'}),
    (r'/login', LoginHandler),
    (r'/register', RegisterHandler),
    (r'/photoupload', PhotoUploadHandler),
    (r'/history', HistoryHandler),
    (r'/resetpassword', ResetPasswordHandler),
    (r'/adminlogin', AdminLoginHandler),
    (r'/adminphotolist', AdminPhotoListHandler),
    (r'/adminupdatephotoinfo', AdminUpdaePhotInfoHandler),
    (r'/user', UserHandler),
    (r'/userlist', UserListHandler),
    (r'/logout', LogoutHandler),
    (r'/deleteuser', DeleteUserHandler),
    (r'/searchfiltertag', TagFilterHandler),
    (r'/searchfilterglobal', GlobalFilterHandler),
    (r'/searchfiltergeography', GeographyFilterHandler),
    (r'/deletephoto', DeletePhotoHandler),
    (r'/deletephotomulti', DeletePhotoMultiHandler),
    (r'/adminupdatephototagsmulti', AdminUpdaePhotoTagsMultiHandler),
    (r'/adminupdatephotonotesmulti', AdminUpdaePhotoNotesMultiHandler),
]
