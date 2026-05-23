# server/shared/schemas/news.py
from __future__ import annotations
from datetime import datetime
from pydantic import BaseModel, Field
from typing import Any


class NewsItemDTO(BaseModel):
    id: str
    title: str
    content: str
    source: str
    url: str
    publish_time: str
    industry: str | None = None
    sentiment: str | None = None
    tags: list[str] = Field(default_factory=list)
    ai_analyzed: bool = False
    created_at: str | None = None
    updated_at: str | None = None


class NewsAiAnalysisDTO(BaseModel):
    id: str
    news_id: str
    provider: str
    model_name: str
    prompt_version: str
    summary: str
    impact: str
    sentiment_score: float = 0.0
    confidence: float = 0.0
    evidence: list[str] = Field(default_factory=list)
    tool_trace_id: str | None = None
    created_at: str | None = None


class NewsSymbolLinkDTO(BaseModel):
    id: str
    news_id: str
    instrument_id: str
    relevance: float = 0.0
    reason: str | None = None
    created_at: str | None = None


class NewsItemCreateDTO(BaseModel):
    title: str
    content: str
    source: str
    url: str
    publish_time: str
    industry: str | None = None
    sentiment: str | None = None
    tags: list[str] = Field(default_factory=list)
