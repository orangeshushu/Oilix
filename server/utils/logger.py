"""
@author: ZHGZYANG
"""

def writeAndPrint(string, isPrint = False, isWrite = True):
    if isPrint:
        print(string)
    if isWrite:
        with open('log.txt', 'a') as fp:
            fp.write('{}\n'.format(string))
