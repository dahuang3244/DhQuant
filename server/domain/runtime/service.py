# server/domain/runtime/service.py
from __future__ import annotations
from datetime import datetime
import os
from server.shared.schemas.runtime import RuntimeStatusDTO, HealthReportDTO, ServiceInfoDTO
from server.shared.redis.heartbeat import get_service_status, read_heartbeat
from server.shared.redis.client import ping_redis
from server.shared.db.session import ping_db

try:
    import psutil
except ImportError:
    psutil = None

class RuntimeService:
    def __init__(self):
        self.start_time = datetime.now()

    def get_status(self) -> RuntimeStatusDTO:
        uptime = (datetime.now() - self.start_time).total_seconds()
        return RuntimeStatusDTO(
            profile="dev",
            uptime_seconds=uptime,
            api_url="http://127.0.0.1:8765",
            health=self.get_health_report()
        )

    def list_services(self) -> list[ServiceInfoDTO]:
        services = ["api", "market", "news", "ai", "backtest_worker", "risk", "broker", "scheduler"]
        result = []
        for name in services:
            status = get_service_status(name)
            ts = read_heartbeat(name)
            last_hb = datetime.fromtimestamp(ts) if ts else None
            result.append(ServiceInfoDTO(
                service_name=name,
                status=status,
                last_heartbeat=last_hb,
                pid=os.getpid() if name == "api" else None
            ))
        return result

    def get_health_report(self) -> HealthReportDTO:
        # Check disk usage
        disk_pct = 0.0
        if psutil:
            try:
                disk = psutil.disk_usage("/")
                disk_pct = disk.percent
            except Exception:
                pass

        return HealthReportDTO(
            database_ok=ping_db(),
            redis_ok=ping_redis(),
            disk_usage_pct=disk_pct,
            services=self.list_services(),
            timestamp=datetime.now()
        )
