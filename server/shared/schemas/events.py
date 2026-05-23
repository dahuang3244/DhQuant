# server/shared/schemas/events.py
from __future__ import annotations
from pydantic import BaseModel, Field
from typing import Any


class EventRecordDTO(BaseModel):
    id: str
    run_id: str | None = None
    sequence: int = 0
    source: str
    topic: str
    level: str = "info"
    instrument_id: str | None = None
    correlation_id: str | None = None
    causation_id: str | None = None
    message: str
    detail: dict[str, Any] = Field(default_factory=dict)
    event_time: str | None = None
    created_at: str | None = None


class EventQueryRequest(BaseModel):
    run_id: str | None = None
    topic: str | None = None
    source: str | None = None
    instrument_id: str | None = None
    correlation_id: str | None = None
    limit: int = Field(default=100, ge=1, le=1000)
    offset: int = Field(default=0, ge=0)
