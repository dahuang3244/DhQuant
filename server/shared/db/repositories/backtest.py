from __future__ import annotations

from typing import Optional

from sqlalchemy import desc, select
from sqlalchemy.orm import Session

from server.shared.db.models import BacktestArtifact, BacktestRun, BacktestTrade
from server.shared.db.repositories.base import BaseRepository


class BacktestRunRepository(BaseRepository[BacktestRun]):
    def __init__(self, session: Session):
        super().__init__(BacktestRun, session)

    def list_recent(
        self,
        *,
        status: str | None = None,
        strategy_id: str | None = None,
        limit: int = 50,
        offset: int = 0,
    ) -> list[BacktestRun]:
        stmt = select(BacktestRun)
        if status:
            stmt = stmt.where(BacktestRun.status == status)
        if strategy_id:
            stmt = stmt.where(BacktestRun.strategy_id == strategy_id)
        stmt = stmt.order_by(desc(BacktestRun.created_at)).limit(limit).offset(offset)
        return list(self.session.scalars(stmt).all())

    def mark_running(self, run_id: str, *, started_at: str) -> Optional[BacktestRun]:
        return self.update(run_id, status="running", started_at=started_at, error="")

    def mark_success(
        self,
        run_id: str,
        *,
        metrics_json: str,
        finished_at: str,
    ) -> Optional[BacktestRun]:
        return self.update(
            run_id,
            status="success",
            metrics_json=metrics_json,
            finished_at=finished_at,
            error="",
        )

    def mark_failed(self, run_id: str, *, error: str, finished_at: str) -> Optional[BacktestRun]:
        return self.update(run_id, status="failed", error=error, finished_at=finished_at)


class BacktestTradeRepository(BaseRepository[BacktestTrade]):
    def __init__(self, session: Session):
        super().__init__(BacktestTrade, session)

    def list_for_run(self, run_id: str, *, limit: int = 200, offset: int = 0) -> list[BacktestTrade]:
        stmt = (
            select(BacktestTrade)
            .where(BacktestTrade.run_id == run_id)
            .order_by(BacktestTrade.entry_time, BacktestTrade.exit_time)
            .limit(limit)
            .offset(offset)
        )
        return list(self.session.scalars(stmt).all())


class BacktestArtifactRepository(BaseRepository[BacktestArtifact]):
    def __init__(self, session: Session):
        super().__init__(BacktestArtifact, session)

    def list_for_run(self, run_id: str) -> list[BacktestArtifact]:
        stmt = select(BacktestArtifact).where(BacktestArtifact.run_id == run_id)
        return list(self.session.scalars(stmt).all())

    def get_for_run(self, run_id: str, artifact_type: str) -> Optional[BacktestArtifact]:
        stmt = (
            select(BacktestArtifact)
            .where(
                BacktestArtifact.run_id == run_id,
                BacktestArtifact.artifact_type == artifact_type,
            )
            .order_by(desc(BacktestArtifact.created_at))
            .limit(1)
        )
        return self.session.scalar(stmt)
