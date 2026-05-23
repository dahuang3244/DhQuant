# server/shared/redis/locks.py
from __future__ import annotations
import uuid
import time
from contextlib import contextmanager
from .client import get_redis


def acquire_lock(key: str, ttl: int = 30) -> str | None:
    """
    尝试获取锁，成功返回 token（释放锁时需要），失败返回 None。
    ttl: 锁的最大持有时间（秒），防止进程崩溃后锁永远不释放。
    """
    r = get_redis()
    token = str(uuid.uuid4())
    acquired = r.set(key, token, nx=True, ex=ttl)
    return token if acquired else None


def release_lock(key: str, token: str) -> bool:
    """
    释放锁。必须验证 token，防止释放别人的锁（超时后被别人获取的情况）。
    使用 Lua 脚本保证"检查 + 删除"的原子性。
    """
    r = get_redis()
    lua_script = """
    if redis.call("get", KEYS[1]) == ARGV[1] then
        return redis.call("del", KEYS[1])
    else
        return 0
    end
    """
    result = r.eval(lua_script, 1, key, token)
    return bool(result)


@contextmanager
def distributed_lock(key: str, ttl: int = 30, retry: int = 0):
    """
    上下文管理器版本。
    
    用法：
        with distributed_lock(lock_news_crawl("sina"), ttl=60) as acquired:
            if not acquired:
                return  # 其他 worker 正在执行
            # ... 执行业务逻辑
    """
    token = acquire_lock(key, ttl)
    try:
        yield token is not None  # True 表示获取到锁
    finally:
        if token is not None:
            release_lock(key, token)
