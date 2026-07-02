"""
@author: ZHGZYANG
"""

from sqlalchemy.ext.declarative import declarative_base
from .configs import SQLALCHEMY_DATABASE_URI, SQLALCHEMY_ENGINE_ECHO
from sqlalchemy import create_engine
from sqlalchemy.orm import scoped_session, sessionmaker, backref

from sqlalchemy import Column, Table, ForeignKey
from sqlalchemy import Boolean, Integer, String, Text, DateTime, Date, Float
from sqlalchemy.orm import relationship
from datetime import datetime, timezone

Base = declarative_base()
engine = create_engine(SQLALCHEMY_DATABASE_URI, echo=SQLALCHEMY_ENGINE_ECHO, pool_recycle=300, pool_pre_ping=True)

db = scoped_session(sessionmaker(bind=engine))


class Account(Base):
    __tablename__ = 'accounts'
    id = Column(Integer, primary_key=True, autoincrement=True)

    role = Column(Boolean, nullable=False)
    username = Column(String(255), nullable=False)
    password = Column(String(255), nullable=False)
    email = Column(String(255), nullable=False)
    name = Column(String(50), nullable=False)
    photos = relationship('Photo',
                           backref=backref('account', uselist=True),
                           order_by="Photo.date.desc()")


class Photo(Base):
    __tablename__ = 'photos'
    id = Column(Integer, primary_key=True, autoincrement=True)

    path = Column(String(255), nullable=False)
    gps = Column(String(60), nullable=False, default="")
    detailed_gps = Column(String(255), nullable=False, default="")
    date = Column(DateTime, default=datetime.utcnow)
    result = Column(String(255))
    notes = Column(Text)
    tags = Column(Text)

    account_id = Column(Integer, ForeignKey(
        'accounts.id', onupdate='CASCADE', ondelete='SET NULL'))
    username = Column(String(255), nullable=False)


class Log(Base):
    __tablename__ = 'logs'
    id = Column(Integer, primary_key=True, autoincrement=True)
    
    location = Column(Text, nullable=False)
    action = Column(String(255), nullable=False)
    status = Column(String(255), nullable=False)
    
    ip = Column(String(20), nullable=False)
    time = Column(DateTime, default=datetime.utcnow)
    
    account_id = Column(Integer, default=None)
    username = Column(String(255), default=None)
    
    ref_code = Column(String(255), default=None)
