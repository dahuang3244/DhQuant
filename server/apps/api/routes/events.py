# server/apps/api/routes/events.py
from __future__ import annotations
from fastapi import APIRouter, Depends, Query
from server.apps.api.dependencies import get_event_service
from server.domain.event.service import EventService
from server.shared.schemas.events import EventRecordDTO, EventQueryRequest

router = APIRouter(prefix="/events", tags=["events"])


@router.get("", response_model=list[EventRecordDTO])
def query_events(
    run_id: str | None = None,
    topic: str | None = None,
    source: str | None = None,
    instrument_id: str | None = None,
    limit: int = 100,
    offset: int = 0,
    event_service: EventService = Depends(get_event_service)
):
    """根据过滤条件分页查询历史系统与交易事件日志。"""
    req = EventQueryRequest(
        run_id=run_id,
        topic=topic,
        source=source,
        instrument_id=instrument_id,
        limit=limit,
        offset=offset
    )
    return event_service.query(req)


@router.get("/summary")
def get_events_summary(
    run_id: str,
    event_service: EventService = Depends(get_event_service)
):
    """获取指定回测运行或交易时段的事件统计摘要。"""
    return event_service.summary(run_id)
