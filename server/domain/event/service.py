# server/domain/event/service.py
from __future__ import annotations
from datetime import datetime
from server.shared.schemas.events import EventRecordDTO, EventQueryRequest

class EventService:
    def emit(self, event: EventRecordDTO) -> None:
        pass

    def query(self, request: EventQueryRequest) -> list[EventRecordDTO]:
        return [
            EventRecordDTO(
                id="evt_1",
                source=request.source or "system",
                topic=request.topic or "test",
                message="Mock event",
                event_time=datetime.now().isoformat()
            )
        ]

    def summary(self, run_id: str) -> dict:
        return {
            "run_id": run_id,
            "total_events": 10,
            "errors": 0,
            "warnings": 1
        }
