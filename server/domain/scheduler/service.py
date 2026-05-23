# server/domain/scheduler/service.py
from __future__ import annotations
from datetime import datetime
from sqlalchemy.orm import Session
from server.shared.schemas.scheduler import JobSpecDTO


class SchedulerService:
    def __init__(self, db: Session | None = None):
        self.db = db

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
        try:
            from server.apps.market.runner import cache_bars_task
            cache_bars_task.send(instrument_id="000001.SZ", period="1d", start="2024-01-01", end="2024-01-31")
        except Exception as e:
            from server.shared.logging.setup import get_logger
            get_logger("scheduler.service").warning(f"Failed to enqueue market refresh task: {e}")

    def schedule_news_crawl(self) -> None:
        try:
            from server.apps.news.runner import fetch_news_task
            fetch_news_task.send(source_id="eastmoney")
        except Exception as e:
            from server.shared.logging.setup import get_logger
            get_logger("scheduler.service").warning(f"Failed to enqueue news crawl task: {e}")

    def schedule_ai_signal_scan(self) -> None:
        try:
            from server.apps.ai.runner import ai_signal_scan_task
            ai_signal_scan_task.send(instrument_id="000001.SZ")
        except Exception as e:
            from server.shared.logging.setup import get_logger
            get_logger("scheduler.service").warning(f"Failed to enqueue AI signal scan task: {e}")
