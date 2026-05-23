from __future__ import annotations

from typing import Optional

from sqlalchemy import desc, select
from sqlalchemy.orm import Session

from server.shared.db.models import NewsAiAnalysis, NewsItem, NewsSymbolLink
from server.shared.db.repositories.base import BaseRepository


class NewsRepository(BaseRepository[NewsItem]):
    def __init__(self, session: Session):
        super().__init__(NewsItem, session)

    def get_by_url(self, url: str) -> Optional[NewsItem]:
        stmt = select(NewsItem).where(NewsItem.url == url)
        return self.session.scalar(stmt)

    def list_latest(
        self,
        *,
        industry: str | None = None,
        instrument_id: str | None = None,
        limit: int = 50,
        offset: int = 0,
    ) -> list[NewsItem]:
        stmt = select(NewsItem)
        if industry and industry != "全部":
            stmt = stmt.where(NewsItem.industry == industry)
        if instrument_id:
            stmt = stmt.join(NewsSymbolLink).where(NewsSymbolLink.instrument_id == instrument_id)
        stmt = stmt.order_by(desc(NewsItem.publish_time), desc(NewsItem.created_at)).limit(limit).offset(offset)
        return list(self.session.scalars(stmt).unique().all())

    def list_unanalyzed(self, *, limit: int = 100) -> list[NewsItem]:
        stmt = (
            select(NewsItem)
            .where(NewsItem.ai_analyzed.is_(False))
            .order_by(desc(NewsItem.publish_time), desc(NewsItem.created_at))
            .limit(limit)
        )
        return list(self.session.scalars(stmt).all())

    def mark_analyzed(self, news_id: str) -> Optional[NewsItem]:
        return self.update(news_id, ai_analyzed=True)


class NewsAiAnalysisRepository(BaseRepository[NewsAiAnalysis]):
    def __init__(self, session: Session):
        super().__init__(NewsAiAnalysis, session)

    def list_for_news(self, news_id: str) -> list[NewsAiAnalysis]:
        stmt = (
            select(NewsAiAnalysis)
            .where(NewsAiAnalysis.news_id == news_id)
            .order_by(desc(NewsAiAnalysis.created_at))
        )
        return list(self.session.scalars(stmt).all())

    def create_for_news(self, news_id: str, **values) -> NewsAiAnalysis:
        analysis = self.create(news_id=news_id, **values)
        news = self.session.get(NewsItem, news_id)
        if news is not None:
            news.ai_analyzed = True
        self.session.flush()
        return analysis


class NewsSymbolLinkRepository(BaseRepository[NewsSymbolLink]):
    def __init__(self, session: Session):
        super().__init__(NewsSymbolLink, session)

    def link(
        self,
        *,
        news_id: str,
        instrument_id: str,
        relevance: float = 0.0,
        reason: str = "",
    ) -> NewsSymbolLink:
        stmt = select(NewsSymbolLink).where(
            NewsSymbolLink.news_id == news_id,
            NewsSymbolLink.instrument_id == instrument_id,
        )
        obj = self.session.scalar(stmt)
        if obj is None:
            return self.create(
                news_id=news_id,
                instrument_id=instrument_id,
                relevance=relevance,
                reason=reason,
            )
        obj.relevance = relevance
        obj.reason = reason
        self.session.flush()
        return obj

    def list_for_symbol(self, instrument_id: str, *, limit: int = 100) -> list[NewsSymbolLink]:
        stmt = (
            select(NewsSymbolLink)
            .where(NewsSymbolLink.instrument_id == instrument_id)
            .order_by(desc(NewsSymbolLink.created_at))
            .limit(limit)
        )
        return list(self.session.scalars(stmt).all())
