"""
@author: ZHGZYANG
"""

import os
import base64
def generateFileName():
    return str(base64.b16encode(os.urandom(8)))[2:-1]

if __name__ == '__main__':
    for i in range(10):
        print(generateFileName())
