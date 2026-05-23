# server/shared/schemas/strategy.py
from __future__ import annotations
from pydantic import BaseModel, Field
from typing import Any


class StrategyDTO(BaseModel):
    id: str
    name: str
    strategy_type: str
    language: str = "python"
    description: str | None = None
    status: str = "draft"  # draft / active / retired
    latest_version_id: str | None = None
    config: dict[str, Any] = Field(default_factory=dict)
    created_at: str | None = None
    updated_at: str | None = None


class StrategyVersionDTO(BaseModel):
    id: str
    strategy_id: str
    version: int
    code: str
    config: dict[str, Any] = Field(default_factory=dict)
    notes: str | None = None
    created_at: str | None = None


class FactorDTO(BaseModel):
    id: str
    name: str
    category: str
    formula: str | None = None
    description: str | None = None
    ic: float = 0.0
    sharpe: float = 0.0
    win_rate: float = 0.0
    status: str = "active"
    source: str = "manual"
    created_at: str | None = None
    updated_at: str | None = None


class StrategyFactorDTO(BaseModel):
    id: str
    strategy_id: str
    factor_id: str
    weight: float = 1.0
    created_at: str | None = None


class StrategyCreateRequest(BaseModel):
    name: str
    strategy_type: str
    language: str = "python"
    description: str | None = None
    code: str
    config: dict[str, Any] = Field(default_factory=dict)
    notes: str | None = None


class StrategyUpdateRequest(BaseModel):
    description: str | None = None
    status: str | None = None
    code: str | None = None
    config: dict[str, Any] | None = None
    notes: str | None = None


class FactorEvaluateResult(BaseModel):
    factor_id: str
    ic: float
    sharpe: float
    win_rate: float
    message: str | None = None
