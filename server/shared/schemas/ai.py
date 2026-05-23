# server/shared/schemas/ai.py
from __future__ import annotations
from datetime import datetime
from pydantic import BaseModel, Field
from typing import Any


class NewsAiAnalysisResultDTO(BaseModel):
    summary: str
    impact: str
    sentiment_score: float
    confidence: float
    evidence: list[str] = Field(default_factory=list)


class StrategyAiAnalysisDTO(BaseModel):
    strategy_id: str
    analysis: str
    code_suggestions: str | None = None
    performance_estimate: str | None = None
    analyzed_at: datetime


class FactorScoresDTO(BaseModel):
    instrument_id: str
    scores: dict[str, float] = Field(default_factory=dict)
    overall_score: float
    calculated_at: datetime


class AiSignalDTO(BaseModel):
    instrument_id: str
    direction: str  # "buy_long" / "sell_short" / "exit"
    confidence: float
    reason: str
    price_trigger: float | None = None
    generated_at: datetime


class StrategyGenRequest(BaseModel):
    prompt: str
    strategy_type: str = "trend_following"  # e.g., trend_following, mean_reversion
