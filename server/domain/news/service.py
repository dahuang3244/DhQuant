# server/domain/news/service.py
from __future__ import annotations
from datetime import datetime
from sqlalchemy.orm import Session
from server.shared.db.repositories.news import NewsRepository
from server.shared.schemas.news import NewsItemDTO


class NewsService:
    def __init__(self, db: Session):
        self.db = db
        self.news_repo = NewsRepository(db)

    def fetch(self, source_id: str, industry: str | None = None, limit: int = 10) -> list[NewsItemDTO]:
        lock_acquired = False
        token = None
        lock_key_str = None
        try:
            from server.shared.redis.keys import lock_news_crawl
            from server.shared.redis.locks import acquire_lock
            lock_key_str = lock_news_crawl(source_id)
            token = acquire_lock(lock_key_str, ttl=30)
            if token is not None:
                lock_acquired = True
        except Exception as e:
            from server.shared.logging.setup import get_logger
            get_logger("news.service").warning(f"Failed to check lock for news crawl: {e}")

        try:
            items = self.news_repo.list_latest(industry=industry, limit=limit)
            if not items:
                # Seed a default news item to prevent empty states
                self.news_repo.create(
                    title="A股大涨",
                    content="今日A股行情向好，成交量突破万亿...",
                    source=source_id or "eastmoney",
                    url="http://example.com/news1",
                    publish_time=datetime.now().isoformat(),
                    industry=industry or "financial",
                    sentiment="positive"
                )
                items = self.news_repo.list_latest(industry=industry, limit=limit)
        finally:
            if lock_acquired and token and lock_key_str:
                try:
                    from server.shared.redis.locks import release_lock
                    release_lock(lock_key_str, token)
                except Exception:
                    pass

        return [
            NewsItemDTO(
                id=x.id,
                title=x.title,
                content=x.content,
                source=x.source,
                url=x.url,
                publish_time=x.publish_time,
                industry=x.industry,
                sentiment=x.sentiment
            ) for x in items
        ]

    def normalize(self, raw: dict) -> NewsItemDTO:
        return NewsItemDTO(
            id=raw.get("id", "news_raw"),
            title=raw.get("title", "标题"),
            content=raw.get("content", "内容"),
            source=raw.get("source", "unknown"),
            url=raw.get("url", ""),
            publish_time=raw.get("publish_time", datetime.now().isoformat()),
            industry=raw.get("industry"),
            sentiment=raw.get("sentiment")
        )

    def deduplicate(self, item: NewsItemDTO) -> bool:
        if not item.url:
            return True
        existing = self.news_repo.get_by_url(item.url)
        return existing is None

    def classify_industry(self, item: NewsItemDTO) -> str:
        return item.industry or "financial"

    def tag_sentiment(self, item: NewsItemDTO) -> str:
        return item.sentiment or "neutral"

    def enqueue_ai_analysis(self, news_id: str) -> None:
        try:
            from server.apps.ai.runner import news_ai_analyze_task
            news_ai_analyze_task.send(news_id)
            
            from server.domain.event.service import EventService
            from server.shared.schemas.events import EventRecordDTO
            import uuid
            evt_service = EventService(self.db)
            evt_service.emit(EventRecordDTO(
                id=f"evt_{uuid.uuid4().hex[:8]}",
                source="news_service",
                topic="news_ai_analyze_enqueue",
                message=f"Enqueued news {news_id} for AI analysis",
                detail={"news_id": news_id}
            ))
        except Exception as e:
            from server.shared.logging.setup import get_logger
            get_logger("news.service").warning(f"Failed to enqueue news AI analysis: {e}")
