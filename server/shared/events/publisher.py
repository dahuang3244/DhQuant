# server/shared/events/publisher.py
from __future__ import annotations
from .envelope import EventEnvelope
from server.shared.db.session import get_session
from server.shared.db.models import EventRecord
from server.shared.redis.serialization import to_json
from server.shared.redis.streams import xadd_json
from server.shared.redis.keys import STREAM_SYSTEM


def emit(event: EventEnvelope, stream: str | None = None) -> None:
    """
    发布一条事件：
    1. 写入 SQLite events 表（持久化审计）
    2. 写入 Redis Stream（实时推送给 GUI）
    """
    # 1. 写 SQLite
    with get_session() as session:
        record = EventRecord(
            id=event.event_id,
            run_id=event.run_id,
            sequence=event.sequence,
            source=event.source,
            topic=event.topic,
            level=event.level,
            instrument_id=event.instrument_id,
            correlation_id=event.correlation_id,
            causation_id=event.causation_id,
            message=event.message,
            detail_json=to_json(event.detail) if event.detail is not None else "{}",
            event_time=event.event_time or event.created_at.isoformat(),
            created_at=event.created_at.isoformat(),
        )
        session.add(record)
    
    # 2. 写 Redis Stream
    target_stream = stream or STREAM_SYSTEM
    try:
        xadd_json(target_stream, event.model_dump())
    except Exception:
        pass  # Redis 失败不影响数据库写入
