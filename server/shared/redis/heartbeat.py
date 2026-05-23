# server/shared/redis/heartbeat.py
from __future__ import annotations
import time
from .client import get_redis
from .keys import heartbeat_key


HEARTBEAT_TTL = 30  # key 自动过期时间（秒）
STALE_THRESHOLD = 15  # 超过 15 秒没有更新视为 stale


def write_heartbeat(service_name: str) -> None:
    """服务定时调用，写入当前时间戳。"""
    r = get_redis()
    r.set(heartbeat_key(service_name), str(time.time()), ex=HEARTBEAT_TTL)


def read_heartbeat(service_name: str) -> float | None:
    """读取服务最后一次心跳时间戳，key 不存在返回 None。"""
    r = get_redis()
    val = r.get(heartbeat_key(service_name))
    return float(val) if val else None


def get_service_status(service_name: str) -> str:
    """返回 'alive' / 'stale' / 'down'。"""
    ts = read_heartbeat(service_name)
    if ts is None:
        return "down"
    age = time.time() - ts
    if age > STALE_THRESHOLD:
        return "stale"
    return "alive"
