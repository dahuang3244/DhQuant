# server/domain/backtest/service.py
from __future__ import annotations
from datetime import datetime
from server.shared.schemas.backtest import BacktestRunRequest, BacktestRunDTO, BacktestResultDTO, BacktestProgressDTO

class BacktestService:
    def create_run(self, request: BacktestRunRequest) -> BacktestRunDTO:
        return BacktestRunDTO(
            id="run_1",
            strategy_id=request.strategy_id,
            strategy_version_id=request.strategy_version_id,
            status="pending",
            mode=request.mode,
            market=request.market,
            period=request.period,
            start_time=request.start_time,
            end_time=request.end_time,
            initial_capital=request.initial_capital,
            commission=request.commission,
            leverage=request.leverage,
            config=request.config,
            created_at=datetime.now().isoformat()
        )

    def execute_run(self, run_id: str) -> None:
        # Mock execution: usually called by worker
        pass

    def get_run(self, run_id: str) -> BacktestRunDTO:
        return BacktestRunDTO(
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
            metrics={"sharpe": 1.5, "max_drawdown": 0.12, "annual_return": 0.25},
            created_at=datetime.now().isoformat()
        )

    def list_runs(self) -> list[BacktestRunDTO]:
        return [self.get_run("run_1")]

    def load_input_data(self, run: BacktestRunDTO) -> None:
        pass

    def persist_result(self, run_id: str, result: BacktestResultDTO) -> None:
        pass

    def publish_progress(self, run_id: str, progress: BacktestProgressDTO) -> None:
        pass
