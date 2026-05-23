# server/shared/events/envelope.py
from __future__ import annotations
import uuid
from datetime import datetime, timezone
from typing import Any
from pydantic import BaseModel, Field


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _new_id() -> str:
    return str(uuid.uuid4())


class EventEnvelope(BaseModel):
    """
    所有系统事件的统一信封。
    
    字段含义：
    - event_id: 全局唯一 ID，用于去重和关联
    - run_id: 运行会话 ID（同一次回测或实盘进程）
    - sequence: 该会话内的递增序号
    - source: 事件来源服务（"market" / "news" / "ai" / "backtest" / "risk" / "broker" / "system"）
    - topic: 事件类型（见 topics.py）
    - level: 严重级别（"info" / "warning" / "error"）
    - instrument_id: 关联的标的 ID（无关联则 None）
    - correlation_id: 链路追踪 ID
    - causation_id: 触发当前事件的上游事件 ID
    - message: 人读的事件摘要
    - detail: 机器读的结构化数据（JSON 可序列化）
    - event_time: 业务发生时间
    - created_at: 事件发生时间（UTC）
    """
    event_id: str = Field(default_factory=_new_id)
    run_id: str = ""
    sequence: int = 0
    source: str
    topic: str
    level: str = "info"
    instrument_id: str | None = None
    correlation_id: str = ""
    causation_id: str = ""
    message: str
    detail: Any = None
    event_time: str = ""
    created_at: datetime = Field(default_factory=_now)
