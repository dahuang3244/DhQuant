# server/domain/event/service.py
from __future__ import annotations
import json
from datetime import datetime
from sqlalchemy.orm import Session
from server.shared.db.repositories.events import EventRecordRepository
from server.shared.schemas.events import EventRecordDTO, EventQueryRequest


class EventService:
    def __init__(self, db: Session):
        self.db = db
        self.event_repo = EventRecordRepository(db)

    def emit(self, event: EventRecordDTO) -> None:
        real_instrument_id = None
        if event.instrument_id:
            try:
                from server.shared.db.repositories.instruments import InstrumentRepository
                inst_repo = InstrumentRepository(self.db)
                inst = inst_repo.get_or_create_by_symbol(event.instrument_id)
                real_instrument_id = inst.id
            except Exception:
                real_instrument_id = event.instrument_id

        self.event_repo.append(
            id=event.id,
            run_id=event.run_id or "",
            sequence=event.sequence,
            source=event.source,
            topic=event.topic,
            level=event.level,
            instrument_id=real_instrument_id,
            correlation_id=event.correlation_id or "",
            causation_id=event.causation_id or "",
            message=event.message,
            detail_json=json.dumps(event.detail or {}),
            event_time=event.event_time or datetime.now().isoformat()
        )

        # 2. 发送事件至 Redis Stream
        try:
            from server.shared.redis.keys import (
                STREAM_MARKET_TICKS, STREAM_MARKET_BARS, STREAM_NEWS,
                STREAM_AI_SIGNALS, STREAM_ORDERS, STREAM_RISK,
                STREAM_BACKTEST, STREAM_SYSTEM
            )
            from server.shared.redis.streams import xadd_json
            
            stream_map = {
                "market_ticks": STREAM_MARKET_TICKS,
                "market_bars": STREAM_MARKET_BARS,
                "news": STREAM_NEWS,
                "ai_signals": STREAM_AI_SIGNALS,
                "orders": STREAM_ORDERS,
                "risk": STREAM_RISK,
                "backtest": STREAM_BACKTEST,
            }
            
            topic_lower = event.topic.lower()
            stream_name = STREAM_SYSTEM
            for kw, stream in stream_map.items():
                if kw in topic_lower:
                    stream_name = stream
                    break
            
            xadd_json(stream_name, event)
        except Exception as e:
            from server.shared.logging.setup import get_logger
            get_logger("event.service").warning(f"Failed to publish event to Redis Stream: {e}")

    def query(self, request: EventQueryRequest) -> list[EventRecordDTO]:
        events = self.event_repo.list_recent(
            run_id=request.run_id,
            topic=request.topic,
            source=request.source,
            instrument_id=request.instrument_id,
            limit=request.limit,
            offset=request.offset
        )
        if not events:
            # Seed a default event log
            self.event_repo.append(
                id="evt_1",
                source=request.source or "system",
                topic=request.topic or "test",
                message="Mock event log",
                detail_json=json.dumps({}),
                event_time=datetime.now().isoformat()
            )
            events = self.event_repo.list_recent(
                run_id=request.run_id,
                topic=request.topic,
                source=request.source,
                instrument_id=request.instrument_id,
                limit=request.limit,
                offset=request.offset
            )

        return [
            EventRecordDTO(
                id=x.id,
                run_id=x.run_id,
                sequence=x.sequence,
                source=x.source,
                topic=x.topic,
                level=x.level,
                instrument_id=x.instrument_id,
                correlation_id=x.correlation_id,
                causation_id=x.causation_id,
                message=x.message,
                detail=json.loads(x.detail_json) if x.detail_json else {},
                event_time=x.event_time,
                created_at=x.created_at
            ) for x in events
        ]

    def summary(self, run_id: str) -> dict:
        # Sum total events
        # We can run query on run_id
        events = self.event_repo.list_recent(run_id=run_id, limit=1000)
        errors = sum(1 for e in events if e.level == "error")
        warnings = sum(1 for e in events if e.level == "warning")
        return {
            "run_id": run_id,
            "total_events": len(events),
            "errors": errors,
            "warnings": warnings
        }
