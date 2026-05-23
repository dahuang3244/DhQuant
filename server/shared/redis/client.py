# server/shared/redis/client.py
from __future__ import annotations
import redis
from functools import lru_cache
from server.shared.config.settings import get_settings


@lru_cache(maxsize=1)
def get_redis() -> redis.Redis:
    """返回全局共享的 Redis 客户端（带连接池）。"""
    s = get_settings()
    return redis.from_url(
        s.redis_url,
        decode_responses=True,  # 自动把 bytes 解码成 str
        max_connections=20,
    )


def ping_redis() -> bool:
    """健康检查：能 ping 通返回 True。"""
    try:
        return get_redis().ping()
    except Exception:
        return False
