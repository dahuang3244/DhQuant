# server/shared/schemas/trading.py
from __future__ import annotations
from pydantic import BaseModel, Field
from typing import Any


class AccountDTO(BaseModel):
    id: str
    broker_id: str
    account_no: str
    name: str | None = None
    currency: str = "USD"
    cash: float = 0.0
    net_liquidation: float = 0.0
    buying_power: float = 0.0
    status: str = "active"  # active / disabled
    last_sync_at: str | None = None
    created_at: str | None = None
    updated_at: str | None = None


class PositionDTO(BaseModel):
    id: str
    account_id: str
    instrument_id: str
    side: str = "long"  # long / short
    qty: float = 0.0
    avg_price: float = 0.0
    market_value: float = 0.0
    unrealized_pnl: float = 0.0
    realized_pnl: float = 0.0
    weight: float = 0.0
    updated_at: str | None = None


class OrderDTO(BaseModel):
    id: str
    account_id: str | None = None
    strategy_id: str | None = None
    instrument_id: str
    broker_order_id: str | None = None
    side: str  # buy / sell
    order_type: str = "market"  # market / limit / stop
    qty: float
    price: float = 0.0
    status: str = "pending"  # pending/submitted/filled/cancelled/rejected
    submitted_at: str | None = None
    correlation_id: str | None = None
    raw_response: dict[str, Any] = Field(default_factory=dict)
    created_at: str | None = None
    updated_at: str | None = None


class FillDTO(BaseModel):
    id: str
    order_id: str
    instrument_id: str
    broker_fill_id: str | None = None
    side: str  # buy / sell
    qty: float
    price: float
    commission: float = 0.0
    filled_at: str
    raw_response: dict[str, Any] = Field(default_factory=dict)
    created_at: str | None = None


class OrderIntentDTO(BaseModel):
    """下单意图（前置风控）"""
    account_id: str
    strategy_id: str | None = None
    instrument_id: str
    side: str  # buy / sell
    order_type: str = "market"
    qty: float
    price: float = 0.0
    correlation_id: str | None = None


class ApprovedOrderDTO(BaseModel):
    """通过风控审批的订单（可投递给券商）"""
    intent: OrderIntentDTO
    risk_token: str
    approved_at: str
