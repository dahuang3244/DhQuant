# server/shared/schemas/risk.py
from __future__ import annotations
from pydantic import BaseModel, Field
from typing import Any


class RiskRuleDTO(BaseModel):
    id: str
    name: str
    rule_type: str  # position / order / portfolio
    enabled: bool = True
    threshold: float = 0.0
    current_value: float = 0.0
    step: float = 1.0
    unit: str = ""
    status: str = "idle"  # idle / alerting / triggered
    config: dict[str, Any] = Field(default_factory=dict)
    created_at: str | None = None
    updated_at: str | None = None


class RiskLogDTO(BaseModel):
    id: str
    rule_id: str | None = None
    order_id: str | None = None
    instrument_id: str | None = None
    result: str  # passed / rejected / warning
    level: str = "info"  # info / warn / error
    message: str | None = None
    check_value: float = 0.0
    limit_value: float = 0.0
    detail: dict[str, Any] = Field(default_factory=dict)
    created_at: str | None = None


class RiskSnapshotDTO(BaseModel):
    id: str
    account_id: str | None = None
    status: str = "IDLE"  # IDLE / CRITICAL
    net_long_weight: float = 0.0
    net_short_weight: float = 0.0
    exposures: list[dict[str, Any]] = Field(default_factory=list)
    sectors: list[dict[str, Any]] = Field(default_factory=list)
    metrics: dict[str, Any] = Field(default_factory=dict)
    created_at: str | None = None


class RiskCheckResultDTO(BaseModel):
    passed: bool
    action: str  # "approve" / "reject" / "warn"
    triggered_rules: list[str] = Field(default_factory=list)
    message: str | None = None
    details: list[RiskLogDTO] = Field(default_factory=list)
