# server/shared/schemas/backtest.py
from __future__ import annotations
from pydantic import BaseModel, Field
from typing import Any


class BacktestRunRequest(BaseModel):
    strategy_id: str
    strategy_version_id: str | None = None
    mode: str = "single"  # single / batch / walk_forward
    market: str = "A股"
    period: str = "1d"
    start_time: str
    end_time: str
    initial_capital: float = 100000.0
    commission: float = 0.0003
    leverage: float = 1.0
    config: dict[str, Any] = Field(default_factory=dict)


class BacktestRunDTO(BaseModel):
    id: str
    strategy_id: str
    strategy_version_id: str | None = None
    status: str = "pending"  # pending/running/success/failed
    mode: str = "single"
    market: str
    period: str
    start_time: str
    end_time: str
    initial_capital: float
    commission: float
    leverage: float
    config: dict[str, Any] = Field(default_factory=dict)
    metrics: dict[str, Any] = Field(default_factory=dict)
    error: str | None = None
    created_at: str | None = None
    started_at: str | None = None
    finished_at: str | None = None


class BacktestTradeDTO(BaseModel):
    id: str
    run_id: str
    instrument_id: str
    entry_time: str
    exit_time: str | None = None
    side: str  # buy_long / sell_short
    qty: float
    entry_price: float
    exit_price: float | None = None
    pnl: float = 0.0
    return_pct: float = 0.0
    hold_days: float = 0.0
    created_at: str | None = None


class BacktestProgressDTO(BaseModel):
    run_id: str
    progress: float  # 0.0 to 1.0
    current_time: str | None = None
    message: str | None = None


class BacktestResultDTO(BaseModel):
    run_id: str
    metrics: dict[str, Any]
    trades: list[BacktestTradeDTO] = Field(default_factory=list)
    equity_curve_path: str | None = None
    error: str | None = None
