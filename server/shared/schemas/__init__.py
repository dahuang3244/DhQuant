# server/shared/schemas/__init__.py
from __future__ import annotations

from .common import ApiResponse, ErrorResponse, PageRequest, PageResult, TimeRange
from .market import QuoteDTO, BarDTO, IndicatorDTO, InstrumentDTO, BarCacheDTO
from .news import NewsItemDTO, NewsAiAnalysisDTO, NewsSymbolLinkDTO, NewsItemCreateDTO
from .ai import NewsAiAnalysisResultDTO, StrategyAiAnalysisDTO, FactorScoresDTO, AiSignalDTO, StrategyGenRequest
from .strategy import (
    StrategyDTO, StrategyVersionDTO, FactorDTO, StrategyFactorDTO,
    StrategyCreateRequest, StrategyUpdateRequest, FactorEvaluateResult
)
from .backtest import BacktestRunRequest, BacktestRunDTO, BacktestTradeDTO, BacktestProgressDTO, BacktestResultDTO
from .risk import RiskRuleDTO, RiskLogDTO, RiskSnapshotDTO, RiskCheckResultDTO
from .trading import AccountDTO, PositionDTO, OrderDTO, FillDTO, OrderIntentDTO, ApprovedOrderDTO
from .settings import AppSettingDTO, SecretDTO, PreferenceDTO, SecretCreateRequest
from .events import EventRecordDTO, EventQueryRequest
from .scheduler import JobSpecDTO, TriggerCommandDTO
from .runtime import ServiceInfoDTO, HealthReportDTO, RuntimeStatusDTO

__all__ = [
    # common
    "ApiResponse",
    "ErrorResponse",
    "PageRequest",
    "PageResult",
    "TimeRange",
    # market
    "QuoteDTO",
    "BarDTO",
    "IndicatorDTO",
    "InstrumentDTO",
    "BarCacheDTO",
    # news
    "NewsItemDTO",
    "NewsAiAnalysisDTO",
    "NewsSymbolLinkDTO",
    "NewsItemCreateDTO",
    # ai
    "NewsAiAnalysisResultDTO",
    "StrategyAiAnalysisDTO",
    "FactorScoresDTO",
    "AiSignalDTO",
    "StrategyGenRequest",
    # strategy
    "StrategyDTO",
    "StrategyVersionDTO",
    "FactorDTO",
    "StrategyFactorDTO",
    "StrategyCreateRequest",
    "StrategyUpdateRequest",
    "FactorEvaluateResult",
    # backtest
    "BacktestRunRequest",
    "BacktestRunDTO",
    "BacktestTradeDTO",
    "BacktestProgressDTO",
    "BacktestResultDTO",
    # risk
    "RiskRuleDTO",
    "RiskLogDTO",
    "RiskSnapshotDTO",
    "RiskCheckResultDTO",
    # trading
    "AccountDTO",
    "PositionDTO",
    "OrderDTO",
    "FillDTO",
    "OrderIntentDTO",
    "ApprovedOrderDTO",
    # settings
    "AppSettingDTO",
    "SecretDTO",
    "PreferenceDTO",
    "SecretCreateRequest",
    # events
    "EventRecordDTO",
    "EventQueryRequest",
    # scheduler
    "JobSpecDTO",
    "TriggerCommandDTO",
    # runtime
    "ServiceInfoDTO",
    "HealthReportDTO",
    "RuntimeStatusDTO",
]
