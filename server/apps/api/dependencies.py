# server/apps/api/dependencies.py
from __future__ import annotations
from typing import Generator
from fastapi import Depends
from sqlalchemy.orm import Session
import redis

from server.shared.config.settings import get_settings, Settings
from server.shared.db.session import SessionLocal
from server.shared.redis.client import get_redis

from server.domain.runtime.service import RuntimeService
from server.domain.market.service import MarketDataService
from server.domain.news.service import NewsService
from server.domain.ai.service import AiService
from server.domain.strategy.service import StrategyService, FactorService
from server.domain.backtest.service import BacktestService
from server.domain.risk.service import RiskService
from server.domain.trading.service import BrokerService
from server.domain.settings.service import SettingsService
from server.domain.event.service import EventService
from server.domain.scheduler.service import SchedulerService


def get_api_settings() -> Settings:
    """获取全局配置。"""
    return get_settings()


def get_db() -> Generator[Session, None, None]:
    """数据库 Session 依赖项。"""
    db = SessionLocal()
    try:
        yield db
        db.commit()
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


def get_redis_client() -> redis.Redis:
    """Redis 客户端依赖项。"""
    return get_redis()


# ── 领域服务单例/实例依赖注入 ──────────────────────────────────────────────────

def get_runtime_service() -> RuntimeService:
    return RuntimeService()


def get_market_service() -> MarketDataService:
    return MarketDataService()


def get_news_service() -> NewsService:
    return NewsService()


def get_ai_service() -> AiService:
    return AiService()


def get_strategy_service() -> StrategyService:
    return StrategyService()


def get_factor_service() -> FactorService:
    return FactorService()


def get_backtest_service() -> BacktestService:
    return BacktestService()


def get_risk_service() -> RiskService:
    return RiskService()


def get_broker_service() -> BrokerService:
    return BrokerService()


def get_settings_service() -> SettingsService:
    return SettingsService()


def get_event_service() -> EventService:
    return EventService()


def get_scheduler_service() -> SchedulerService:
    return SchedulerService()
