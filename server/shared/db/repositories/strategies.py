from __future__ import annotations

from typing import Optional

from sqlalchemy import desc, select
from sqlalchemy.orm import Session

from server.shared.db.models import Factor, Strategy, StrategyFactor, StrategyVersion
from server.shared.db.repositories.base import BaseRepository


class StrategyRepository(BaseRepository[Strategy]):
    def __init__(self, session: Session):
        super().__init__(Strategy, session)

    def get_by_name(self, name: str) -> Optional[Strategy]:
        stmt = select(Strategy).where(Strategy.name == name)
        return self.session.scalar(stmt)

    def list_by_status(self, status: str, *, limit: int = 100) -> list[Strategy]:
        stmt = select(Strategy).where(Strategy.status == status).order_by(Strategy.name).limit(limit)
        return list(self.session.scalars(stmt).all())

    def list_names(self) -> list[str]:
        stmt = select(Strategy.name).order_by(Strategy.name)
        return list(self.session.scalars(stmt).all())


class StrategyVersionRepository(BaseRepository[StrategyVersion]):
    def __init__(self, session: Session):
        super().__init__(StrategyVersion, session)

    def latest_for_strategy(self, strategy_id: str) -> Optional[StrategyVersion]:
        stmt = (
            select(StrategyVersion)
            .where(StrategyVersion.strategy_id == strategy_id)
            .order_by(desc(StrategyVersion.version))
            .limit(1)
        )
        return self.session.scalar(stmt)

    def list_for_strategy(self, strategy_id: str) -> list[StrategyVersion]:
        stmt = (
            select(StrategyVersion)
            .where(StrategyVersion.strategy_id == strategy_id)
            .order_by(desc(StrategyVersion.version))
        )
        return list(self.session.scalars(stmt).all())

    def create_next_version(
        self,
        strategy_id: str,
        code: str,
        *,
        config_json: str = "{}",
        notes: str = "",
    ) -> StrategyVersion:
        latest = self.latest_for_strategy(strategy_id)
        next_version = 1 if latest is None else latest.version + 1
        version = self.create(
            strategy_id=strategy_id,
            version=next_version,
            code=code,
            config_json=config_json,
            notes=notes,
        )
        strategy = self.session.get(Strategy, strategy_id)
        if strategy is not None:
            strategy.latest_version_id = version.id
        self.session.flush()
        return version


class FactorRepository(BaseRepository[Factor]):
    def __init__(self, session: Session):
        super().__init__(Factor, session)

    def get_by_name(self, name: str) -> Optional[Factor]:
        stmt = select(Factor).where(Factor.name == name)
        return self.session.scalar(stmt)

    def list_by_category(self, category: str | None = None) -> list[Factor]:
        stmt = select(Factor)
        if category and category != "全部":
            stmt = stmt.where(Factor.category == category)
        stmt = stmt.order_by(Factor.category, Factor.name)
        return list(self.session.scalars(stmt).all())


class StrategyFactorRepository(BaseRepository[StrategyFactor]):
    def __init__(self, session: Session):
        super().__init__(StrategyFactor, session)

    def list_for_strategy(self, strategy_id: str) -> list[StrategyFactor]:
        stmt = select(StrategyFactor).where(StrategyFactor.strategy_id == strategy_id)
        return list(self.session.scalars(stmt).all())

    def attach(self, strategy_id: str, factor_id: str, *, weight: float = 1.0) -> StrategyFactor:
        stmt = select(StrategyFactor).where(
            StrategyFactor.strategy_id == strategy_id,
            StrategyFactor.factor_id == factor_id,
        )
        obj = self.session.scalar(stmt)
        if obj is None:
            return self.create(strategy_id=strategy_id, factor_id=factor_id, weight=weight)
        obj.weight = weight
        self.session.flush()
        return obj

    def detach(self, strategy_id: str, factor_id: str) -> bool:
        stmt = select(StrategyFactor).where(
            StrategyFactor.strategy_id == strategy_id,
            StrategyFactor.factor_id == factor_id,
        )
        obj = self.session.scalar(stmt)
        if obj is None:
            return False
        self.session.delete(obj)
        self.session.flush()
        return True
