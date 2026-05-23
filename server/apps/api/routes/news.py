# server/apps/api/routes/news.py
from __future__ import annotations
from fastapi import APIRouter, Depends
from server.apps.api.dependencies import get_news_service
from server.domain.news.service import NewsService
from server.shared.schemas.news import NewsItemDTO

router = APIRouter(prefix="/news", tags=["news"])


@router.get("", response_model=list[NewsItemDTO])
def list_news(
    source_id: str | None = None,
    industry: str | None = None,
    limit: int = 10,
    news_service: NewsService = Depends(get_news_service)
):
    """获取抓取到的新闻列表。"""
    return news_service.fetch(source_id or "all", industry, limit)


@router.get("/{news_id}", response_model=NewsItemDTO)
def get_news_details(
    news_id: str,
    news_service: NewsService = Depends(get_news_service)
):
    """获取指定新闻的详情。"""
    news_list = news_service.fetch("all", limit=50)
    for n in news_list:
        if n.id == news_id:
            return n
    # 如果找不到，返回一个 mock news
    return NewsItemDTO(
        id=news_id,
        title="新闻未找到 (Mock)",
        content="这只是一条 Mock 新闻占位符...",
        source="system",
        url="",
        publish_time="2026-05-23T10:00:00"
    )


@router.post("/fetch")
def trigger_news_fetch(source_id: str, limit: int = 10):
    """手动触发定时任务队列投递新闻爬取任务。"""
    # 骨架层，返回投递成功
    return {"status": "enqueued", "queue": "queue:news.fetch", "source_id": source_id}


@router.post("/{news_id}/analyze")
def trigger_news_ai_analysis(
    news_id: str,
    news_service: NewsService = Depends(get_news_service)
):
    """手动投递新闻 AI 分析任务到异步队列。"""
    news_service.enqueue_ai_analysis(news_id)
    return {"status": "enqueued", "queue": "queue:news.ai_analyze", "news_id": news_id}
