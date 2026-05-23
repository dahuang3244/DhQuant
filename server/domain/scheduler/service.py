# server/domain/scheduler/service.py
from __future__ import annotations
from datetime import datetime
from server.shared.schemas.scheduler import JobSpecDTO

class SchedulerService:
    def list_jobs(self) -> list[JobSpecDTO]:
        return [
            JobSpecDTO(
                job_id="job_news_crawl",
                name="新闻定时抓取",
                cron_expression="*/10 * * * *",
                queue="queue:news.fetch",
                status="active"
            )
        ]

    def trigger_job(self, job_id: str) -> bool:
        return True

    def enqueue_due_jobs(self) -> None:
        pass

    def schedule_market_refresh(self) -> None:
        pass

    def schedule_news_crawl(self) -> None:
        pass

    def schedule_ai_signal_scan(self) -> None:
        pass
