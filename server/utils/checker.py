"""
@author: ZHGZYANG
"""

import re
import datetime
import imghdr

class ArgException(Exception):
    def __init__(self, arg, kind='input'):
        self.arg = arg
        if kind == 'input':
            self.message = 'Please input correct %s。' % self.arg
        elif kind == 'file':
            self.message = 'Please upload correct %s' % self.arg
        super(ArgException, self).__init__(arg)

    def __str__(self):
        return self.message


def checkImage(image_data):
    rs = imghdr.what(None, h=image_data)
    if rs is None:
        raise ArgException('Photo', 'file')
    return rs

def checkGPS(loc):
    if ';' in loc:
        return loc
    return ''