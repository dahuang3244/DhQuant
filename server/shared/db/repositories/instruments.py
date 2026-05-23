from __future__ import annotations

from typing import Optional

from sqlalchemy import select
from sqlalchemy.orm import Session

from server.shared.db.models import Instrument
from server.shared.db.repositories.base import BaseRepository


class InstrumentRepository(BaseRepository[Instrument]):
    def __init__(self, session: Session):
        super().__init__(Instrument, session)

    def get_by_symbol(self, symbol: str) -> Optional[Instrument]:
        stmt = select(Instrument).where(Instrument.symbol == symbol)
        return self.session.scalar(stmt)

    def get_or_create_by_symbol(self, symbol: str) -> Instrument:
        inst = self.get_by_symbol(symbol)
        if inst:
            return inst
        # Try normalized lookup (e.g. SZ.000001 -> 000001.SZ)
        normalized = symbol
        if "." in symbol:
            parts = symbol.split(".")
            if len(parts) == 2:
                if parts[0] in ("SZ", "SH", "SSE", "SZSE"):
                    exch = "SZ" if parts[0] in ("SZ", "SZSE") else "SH"
                    normalized = f"{parts[1]}.{exch}"
                elif parts[1] in ("SZ", "SH", "SSE", "SZSE"):
                    exch = "SZ" if parts[1] in ("SZ", "SZSE") else "SH"
                    normalized = f"{parts[0]}.{exch}"
        inst = self.get_by_symbol(normalized)
        if inst:
            return inst
        
        # Create fallback instrument
        parts = normalized.split(".")
        exch_code = parts[1] if len(parts) == 2 else "SZ"
        exchange = "SZSE" if exch_code == "SZ" else "SSE"
        return self.create(
            symbol=normalized,
            name=f"Auto-created {normalized}",
            exchange=exchange,
            asset_type="stock",
            is_active=True
        )

    def list_active(
        self,
        *,
        exchange: str | None = None,
        asset_type: str | None = None,
        limit: int = 200,
        offset: int = 0,
    ) -> list[Instrument]:
        stmt = select(Instrument).where(Instrument.is_active.is_(True))
        if exchange:
            stmt = stmt.where(Instrument.exchange == exchange)
        if asset_type:
            stmt = stmt.where(Instrument.asset_type == asset_type)
        stmt = stmt.order_by(Instrument.exchange, Instrument.symbol).limit(limit).offset(offset)
        return list(self.session.scalars(stmt).all())

    def search(
        self,
        query: str,
        *,
        exchange: str | None = None,
        limit: int = 50,
    ) -> list[Instrument]:
        pattern = f"%{query.strip()}%"
        stmt = select(Instrument).where(
            Instrument.is_active.is_(True),
            (Instrument.symbol.like(pattern)) | (Instrument.name.like(pattern)),
        )
        if exchange:
            stmt = stmt.where(Instrument.exchange == exchange)
        stmt = stmt.order_by(Instrument.symbol).limit(limit)
        return list(self.session.scalars(stmt).all())

    def deactivate(self, id: str) -> Optional[Instrument]:
        return self.update(id, is_active=False)
