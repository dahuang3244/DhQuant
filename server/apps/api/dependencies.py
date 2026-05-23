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

def get_runtime_service(db: Session = Depends(get_db)) -> RuntimeService:
    return RuntimeService(db)


def get_market_service(db: Session = Depends(get_db)) -> MarketDataService:
    return MarketDataService(db)


def get_news_service(db: Session = Depends(get_db)) -> NewsService:
    return NewsService(db)


def get_ai_service(db: Session = Depends(get_db)) -> AiService:
    return AiService(db)


def get_strategy_service(db: Session = Depends(get_db)) -> StrategyService:
    return StrategyService(db)


def get_factor_service(db: Session = Depends(get_db)) -> FactorService:
    return FactorService(db)


def get_backtest_service(db: Session = Depends(get_db)) -> BacktestService:
    return BacktestService(db)


def get_risk_service(db: Session = Depends(get_db)) -> RiskService:
    return RiskService(db)


def get_broker_service(db: Session = Depends(get_db)) -> BrokerService:
    return BrokerService(db)


def get_settings_service(db: Session = Depends(get_db)) -> SettingsService:
    return SettingsService(db)


def get_event_service(db: Session = Depends(get_db)) -> EventService:
    return EventService(db)


def get_scheduler_service(db: Session = Depends(get_db)) -> SchedulerService:
    return SchedulerService(db)
