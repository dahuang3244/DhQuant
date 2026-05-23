from __future__ import annotations

from typing import Optional

from sqlalchemy import desc, select
from sqlalchemy.orm import Session

from server.shared.db.models import RiskLog, RiskRule, RiskSnapshot
from server.shared.db.repositories.base import BaseRepository


class RiskRuleRepository(BaseRepository[RiskRule]):
    def __init__(self, session: Session):
        super().__init__(RiskRule, session)

    def list_enabled(self) -> list[RiskRule]:
        stmt = select(RiskRule).where(RiskRule.enabled.is_(True)).order_by(RiskRule.name)
        return list(self.session.scalars(stmt).all())

    def list_by_type(self, rule_type: str) -> list[RiskRule]:
        stmt = select(RiskRule).where(RiskRule.rule_type == rule_type).order_by(RiskRule.name)
        return list(self.session.scalars(stmt).all())

    def set_enabled(self, rule_id: str, enabled: bool) -> Optional[RiskRule]:
        return self.update(rule_id, enabled=enabled)

    def adjust_threshold(self, rule_id: str, delta: float) -> Optional[RiskRule]:
        obj = self.get_by_id(rule_id)
        if obj is None:
            return None
        obj.threshold += delta
        self.session.flush()
        return obj


class RiskLogRepository(BaseRepository[RiskLog]):
    def __init__(self, session: Session):
        super().__init__(RiskLog, session)

    def list_recent(
        self,
        *,
        result: str | None = None,
        instrument_id: str | None = None,
        limit: int = 100,
    ) -> list[RiskLog]:
        stmt = select(RiskLog)
        if result:
            stmt = stmt.where(RiskLog.result == result)
        if instrument_id:
            stmt = stmt.where(RiskLog.instrument_id == instrument_id)
        stmt = stmt.order_by(desc(RiskLog.created_at)).limit(limit)
        return list(self.session.scalars(stmt).all())

    def list_rejections(self, *, limit: int = 100) -> list[RiskLog]:
        return self.list_recent(result="rejected", limit=limit)


class RiskSnapshotRepository(BaseRepository[RiskSnapshot]):
    def __init__(self, session: Session):
        super().__init__(RiskSnapshot, session)

    def latest(self, *, account_id: str | None = None) -> Optional[RiskSnapshot]:
        stmt = select(RiskSnapshot)
        if account_id:
            stmt = stmt.where(RiskSnapshot.account_id == account_id)
        stmt = stmt.order_by(desc(RiskSnapshot.created_at)).limit(1)
        return self.session.scalar(stmt)
