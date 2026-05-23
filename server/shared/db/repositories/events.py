from __future__ import annotations

from sqlalchemy import desc, select
from sqlalchemy.orm import Session

from server.shared.db.models import EventRecord
from server.shared.db.repositories.base import BaseRepository


class EventRecordRepository(BaseRepository[EventRecord]):
    def __init__(self, session: Session):
        super().__init__(EventRecord, session)

    def append(self, **values) -> EventRecord:
        return self.create(**values)

    def list_recent(
        self,
        *,
        run_id: str | None = None,
        topic: str | None = None,
        source: str | None = None,
        instrument_id: str | None = None,
        limit: int = 200,
        offset: int = 0,
    ) -> list[EventRecord]:
        stmt = select(EventRecord)
        if run_id:
            stmt = stmt.where(EventRecord.run_id == run_id)
        if topic:
            stmt = stmt.where(EventRecord.topic == topic)
        if source:
            stmt = stmt.where(EventRecord.source == source)
        if instrument_id:
            stmt = stmt.where(EventRecord.instrument_id == instrument_id)
        stmt = stmt.order_by(desc(EventRecord.created_at), desc(EventRecord.sequence)).limit(limit).offset(offset)
        return list(self.session.scalars(stmt).all())

    def list_correlation(self, correlation_id: str) -> list[EventRecord]:
        stmt = (
            select(EventRecord)
            .where(EventRecord.correlation_id == correlation_id)
            .order_by(EventRecord.event_time, EventRecord.sequence, EventRecord.created_at)
        )
        return list(self.session.scalars(stmt).all())
