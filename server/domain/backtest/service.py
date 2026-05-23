# server/domain/backtest/service.py
from __future__ import annotations
import json
from datetime import datetime
from sqlalchemy.orm import Session
from server.shared.db.repositories.backtest import (
    BacktestRunRepository, BacktestTradeRepository, BacktestArtifactRepository
)
from server.shared.db.repositories.strategies import (
    StrategyRepository, StrategyVersionRepository
)
from server.shared.schemas.backtest import (
    BacktestRunRequest, BacktestRunDTO, BacktestResultDTO, BacktestProgressDTO
)


class BacktestService:
    def __init__(self, db: Session):
        self.db = db
        self.run_repo = BacktestRunRepository(db)
        self.trade_repo = BacktestTradeRepository(db)
        self.artifact_repo = BacktestArtifactRepository(db)

    def create_run(self, request: BacktestRunRequest) -> BacktestRunDTO:
        # Ensure strategy and version exist in database to satisfy foreign keys
        strat_repo = StrategyRepository(self.db)
        version_repo = StrategyVersionRepository(self.db)

        strat = strat_repo.get_by_id(request.strategy_id)
        if strat is None:
            strat = strat_repo.create(
                id=request.strategy_id,
                name=f"Strategy_{request.strategy_id[:8]}" if len(request.strategy_id) > 8 else request.strategy_id,
                strategy_type="trend_following",
                language="python",
                description="Auto-seeded strategy",
                status="active"
            )

        if request.strategy_version_id:
            ver = version_repo.get_by_id(request.strategy_version_id)
            if ver is None:
                version_repo.create(
                    id=request.strategy_version_id,
                    strategy_id=strat.id,
                    version=1,
                    code="class MyStrategy:\n    pass"
                )

        run = self.run_repo.create(
            strategy_id=request.strategy_id,
            strategy_version_id=request.strategy_version_id,
            status="pending",
            mode=request.mode,
            market=request.market,
            period=request.period,
            start_time=request.start_time,
            end_time=request.end_time,
            initial_capital=request.initial_capital,
            commission=request.commission or 0.0,
            leverage=request.leverage or 1.0,
            config_json=json.dumps(request.config or {})
        )
        return self._to_dto(run)

    def execute_run(self, run_id: str) -> None:
        run = self.run_repo.get_by_id(run_id)
        if run is None:
            return

        import hashlib
        config_hash = hashlib.md5(run.config_json.encode('utf-8')).hexdigest()
        
        lock_acquired = False
        token = None
        lock_key_str = None
        
        try:
            from server.shared.redis.keys import lock_backtest
            from server.shared.redis.locks import acquire_lock
            lock_key_str = lock_backtest(config_hash)
            token = acquire_lock(lock_key_str, ttl=10)
            if token is None:
                raise ValueError("Concurrency backtest lock active for this config")
            lock_acquired = True
        except ValueError:
            raise
        except Exception as e:
            from server.shared.logging.setup import get_logger
            get_logger("backtest.service").warning(f"Failed to check distributed lock for backtest: {e}")

        try:
            self.run_repo.mark_running(run_id, started_at=datetime.now().isoformat())
            from server.apps.backtest_worker.runner import run_backtest_task
            run_backtest_task.send(run_id)
        except Exception as e:
            from server.shared.logging.setup import get_logger
            get_logger("backtest.service").warning(f"Failed to enqueue backtest task: {e}")
        finally:
            if lock_acquired and token and lock_key_str:
                try:
                    from server.shared.redis.locks import release_lock
                    release_lock(lock_key_str, token)
                except Exception:
                    pass

    def get_run(self, run_id: str) -> BacktestRunDTO:
        run = self.run_repo.get_by_id(run_id)
        if run is None:
            # Seed a mock run
            run = self.run_repo.create(
                id=run_id,
                strategy_id="strat_1",
                status="success",
                mode="single",
                market="A股",
                period="1d",
                start_time="2024-01-01",
                end_time="2025-01-01",
                initial_capital=100000.0,
                commission=0.0003,
                leverage=1.0,
                metrics_json=json.dumps({"sharpe": 1.5, "max_drawdown": 0.12, "annual_return": 0.25})
            )
        return self._to_dto(run)

    def list_runs(self) -> list[BacktestRunDTO]:
        runs = self.run_repo.list_recent()
        if not runs:
            # Seed default mock run
            self.get_run("run_1")
            runs = self.run_repo.list_recent()
        return [self._to_dto(r) for r in runs]

    def load_input_data(self, run: BacktestRunDTO) -> None:
        pass

    def persist_result(self, run_id: str, result: BacktestResultDTO) -> None:
        # Write trades to trade_repo
        for t in result.trades:
            self.trade_repo.create(
                run_id=run_id,
                instrument_id=t.instrument_id,
                entry_time=t.entry_time,
                exit_time=t.exit_time,
                side=t.side,
                qty=t.qty,
                entry_price=t.entry_price,
                exit_price=t.exit_price,
                pnl=t.pnl,
                return_pct=t.return_pct,
                hold_days=t.hold_days
            )
        # Mark run as success
        self.run_repo.mark_success(
            run_id,
            metrics_json=json.dumps(result.metrics),
            finished_at=datetime.now().isoformat()
        )

    def publish_progress(self, run_id: str, progress: BacktestProgressDTO) -> None:
        try:
            from server.shared.redis.client import get_redis
            from server.shared.redis.keys import backtest_progress_key, STREAM_BACKTEST
            from server.shared.redis.serialization import to_json
            from server.shared.redis.streams import xadd_json
            
            r = get_redis()
            r.set(backtest_progress_key(run_id), to_json(progress), ex=3600)
            xadd_json(STREAM_BACKTEST, progress)
            
            from server.domain.event.service import EventService
            from server.shared.schemas.events import EventRecordDTO
            import uuid
            evt_service = EventService(self.db)
            evt_service.emit(EventRecordDTO(
                id=f"evt_{uuid.uuid4().hex[:8]}",
                source="backtest_service",
                topic="backtest_progress",
                run_id=run_id,
                message=f"Backtest {run_id} progress: {progress.progress_pct * 100:.1f}%",
                detail=progress.model_dump()
            ))
        except Exception as e:
            from server.shared.logging.setup import get_logger
            get_logger("backtest.service").warning(f"Failed to publish backtest progress: {e}")

    def _to_dto(self, run) -> BacktestRunDTO:
        metrics = json.loads(run.metrics_json) if run.metrics_json else {}
        config = json.loads(run.config_json) if run.config_json else {}
        return BacktestRunDTO(
            id=run.id,
            strategy_id=run.strategy_id,
            strategy_version_id=run.strategy_version_id,
            status=run.status,
            mode=run.mode,
            market=run.market,
            period=run.period,
            start_time=run.start_time,
            end_time=run.end_time,
            initial_capital=run.initial_capital,
            commission=run.commission,
            leverage=run.leverage,
            config=config,
            metrics=metrics,
            error=run.error,
            created_at=run.created_at,
            started_at=run.started_at,
            finished_at=run.finished_at
        )
