from __future__ import annotations

from typing import Optional

from sqlalchemy import desc, select
from sqlalchemy.orm import Session

from server.shared.db.models import BarCache
from server.shared.db.repositories.base import BaseRepository


class BarCacheRepository(BaseRepository[BarCache]):
    def __init__(self, session: Session):
        super().__init__(BarCache, session)

    def list_for_instrument(
        self,
        instrument_id: str,
        *,
        period: str | None = None,
        source: str | None = None,
    ) -> list[BarCache]:
        stmt = select(BarCache).where(BarCache.instrument_id == instrument_id)
        if period:
            stmt = stmt.where(BarCache.period == period)
        if source:
            stmt = stmt.where(BarCache.source == source)
        stmt = stmt.order_by(BarCache.period, BarCache.start_time)
        return list(self.session.scalars(stmt).all())

    def find_covering(
        self,
        instrument_id: str,
        period: str,
        start_time: str,
        end_time: str,
        *,
        source: str | None = None,
    ) -> Optional[BarCache]:
        stmt = select(BarCache).where(
            BarCache.instrument_id == instrument_id,
            BarCache.period == period,
            BarCache.start_time <= start_time,
            BarCache.end_time >= end_time,
        )
        if source:
            stmt = stmt.where(BarCache.source == source)
        stmt = stmt.order_by(desc(BarCache.updated_at)).limit(1)
        return self.session.scalar(stmt)

    def upsert_file(
        self,
        *,
        instrument_id: str,
        period: str,
        source: str,
        storage_path: str,
        start_time: str,
        end_time: str,
        row_count: int,
        checksum: str = "",
        storage_type: str = "parquet",
    ) -> BarCache:
        stmt = select(BarCache).where(
            BarCache.instrument_id == instrument_id,
            BarCache.period == period,
            BarCache.source == source,
            BarCache.storage_path == storage_path,
        )
        obj = self.session.scalar(stmt)
        values = {
            "start_time": start_time,
            "end_time": end_time,
            "row_count": row_count,
            "checksum": checksum,
            "storage_type": storage_type,
        }
        if obj is None:
            return self.create(
                instrument_id=instrument_id,
                period=period,
                source=source,
                storage_path=storage_path,
                **values,
            )
        for key, value in values.items():
            setattr(obj, key, value)
        self.session.flush()
        return obj
