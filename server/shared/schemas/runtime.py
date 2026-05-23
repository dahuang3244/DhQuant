# server/shared/schemas/runtime.py
from __future__ import annotations
from pydantic import BaseModel, Field
from datetime import datetime


class ServiceInfoDTO(BaseModel):
    service_name: str
    status: str  # alive / stale / down
    last_heartbeat: datetime | None = None
    pid: int | None = None


class HealthReportDTO(BaseModel):
    database_ok: bool
    redis_ok: bool
    disk_usage_pct: float
    services: list[ServiceInfoDTO] = Field(default_factory=list)
    timestamp: datetime


class RuntimeStatusDTO(BaseModel):
    profile: str
    uptime_seconds: float
    api_url: str
    health: HealthReportDTO
