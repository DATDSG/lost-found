import redis
from rq import Queue
from app.core.config import settings

_redis = redis.from_url(settings.REDIS_URL)
queue = Queue(settings.RQ_DEFAULT_QUEUE, connection=_redis)