# server/apps/api/routes/health.py
from __future__ import annotations
from datetime import datetime
from fastapi import APIRouter, Depends
from server.shared.redis.client import ping_redis
from server.shared.db.session import ping_db
from server.apps.api.dependencies import get_runtime_service
from server.domain.runtime.service import RuntimeService

router = APIRouter()


@router.get("/health")
def health_check(runtime_service: RuntimeService = Depends(get_runtime_service)):
    """获取 API 及数据库、Redis 等基础设施的健康状态。"""
    db_ok = ping_db()
    redis_ok = ping_redis()
    
    # 聚合服务状态
    services = runtime_service.list_services()
    
    overall_ok = db_ok and redis_ok and all(s.status in ("alive", "stale") for s in services)

    return {
        "status": "healthy" if overall_ok else "unhealthy",
        "database_ok": db_ok,
        "redis_ok": redis_ok,
        "services": [s.model_dump() for s in services],
        "timestamp": datetime.now().isoformat()
    }
