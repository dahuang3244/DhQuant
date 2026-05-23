# server/domain/news/service.py
from __future__ import annotations
from datetime import datetime
from server.shared.schemas.news import NewsItemDTO

class NewsService:
    def fetch(self, source_id: str, industry: str | None = None, limit: int = 10) -> list[NewsItemDTO]:
        return [
            NewsItemDTO(
                id="news_1",
                title="A股大涨",
                content="今日A股行情向好...",
                source=source_id,
                url="http://example.com/news1",
                publish_time=datetime.now().isoformat(),
                industry=industry,
                sentiment="positive"
            )
        ]

    def normalize(self, raw: dict) -> NewsItemDTO:
        return NewsItemDTO(
            id=raw.get("id", "news_raw"),
            title=raw.get("title", "标题"),
            content=raw.get("content", "内容"),
            source=raw.get("source", "unknown"),
            url=raw.get("url", ""),
            publish_time=raw.get("publish_time", datetime.now().isoformat())
        )

    def deduplicate(self, item: NewsItemDTO) -> bool:
        return True  # Returns True if it's new / not duplicate

    def classify_industry(self, item: NewsItemDTO) -> str:
        return "financial"

    def tag_sentiment(self, item: NewsItemDTO) -> str:
        return "neutral"

    def enqueue_ai_analysis(self, news_id: str) -> None:
        pass
