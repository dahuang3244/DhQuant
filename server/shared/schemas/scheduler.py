# server/shared/schemas/scheduler.py
from __future__ import annotations
from pydantic import BaseModel, Field
from datetime import datetime


class JobSpecDTO(BaseModel):
    job_id: str
    name: str
    cron_expression: str
    queue: str
    last_run_at: datetime | None = None
    next_run_at: datetime | None = None
    status: str = "active"  # active / paused / running


class TriggerCommandDTO(BaseModel):
    job_id: str
    force_run: bool = True
