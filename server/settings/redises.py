"""
@author: ZHGZYANG
"""

import redis

pool = redis.ConnectionPool(host='localhost', port=6379, db=14)
redis_cache = redis.Redis(connection_pool=pool)
redis_cache.flushdb()