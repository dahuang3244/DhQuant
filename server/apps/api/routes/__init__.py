# server/apps/api/routes/__init__.py
from __future__ import annotations
from fastapi import APIRouter

from .health import router as health_router
from .runtime import router as runtime_router
from .market import router as market_router
from .news import router as news_router
from .ai import router as ai_router
from .strategy import router as strategy_router
from .backtest import router as backtest_router
from .risk import router as risk_router
from .broker import router as broker_router
from .settings import router as settings_router
from .events import router as events_router

api_router = APIRouter()

# 注册所有子路由
api_router.include_router(health_router)
api_router.include_router(runtime_router)
api_router.include_router(market_router)
api_router.include_router(news_router)
api_router.include_router(ai_router)
api_router.include_router(strategy_router)
api_router.include_router(backtest_router)
api_router.include_router(risk_router)
api_router.include_router(broker_router)
api_router.include_router(settings_router)
api_router.include_router(events_router)
