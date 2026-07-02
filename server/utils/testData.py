"""
@author: ZHGZYANG
"""

from settings.models import *


def addAccount():
    account = Account()
    account.id = 3
    account.name = "test"
    account.role = True
    account.username = 'test'
    account.email = '123@abc.com'
    account.password = 'test'
    db.add(account)
    db.commit()


if __name__ == '__main__':
    addAccount()
