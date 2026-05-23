# server/shared/redis/streams.py
from __future__ import annotations
from typing import Any
from .client import get_redis
from .serialization import to_json, from_json


def xadd_json(stream: str, data: dict | Any) -> str:
    """写一条消息到 Stream，返回消息 ID。"""
    r = get_redis()
    if hasattr(data, "model_dump"):
        payload = {"_json": to_json(data.model_dump())}
    else:
        payload = {"_json": to_json(data)}
    return r.xadd(stream, payload)


def ensure_consumer_group(stream: str, group: str) -> None:
    """创建消费者组，如果已存在则忽略。"""
    r = get_redis()
    try:
        r.xgroup_create(stream, group, id="0", mkstream=True)
    except Exception as e:
        if "BUSYGROUP" not in str(e):  # 组已存在，忽略
            raise


def read_group_json(
    stream: str,
    group: str,
    consumer: str,
    count: int = 10,
    block_ms: int = 1000,
) -> list[tuple[str, Any]]:
    """读取 Stream 消息，返回 [(msg_id, data), ...] 列表。"""
    r = get_redis()
    result = r.xreadgroup(group, consumer, {stream: ">"}, count=count, block=block_ms)
    if not result:
        return []
    messages = []
    for _stream, entries in result:
        for msg_id, fields in entries:
            data = from_json(fields["_json"])
            messages.append((msg_id, data))
    return messages


def ack(stream: str, group: str, msg_id: str) -> None:
    get_redis().xack(stream, group, msg_id)
