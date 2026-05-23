# server/shared/redis/keys.py
"""
Redis key/stream/queue/lock 的统一定义。
所有模块必须通过这里的函数/常量来操作 Redis，不允许在业务代码里硬写字符串。
"""
from __future__ import annotations


# ── 热状态 Key（字符串/Hash，存最新值） ────────────────────────────────────

def quote_key(instrument_id: str) -> str:
    """实时报价：quote:{instrument_id}"""
    return f"quote:{instrument_id}"


def bars_latest_key(instrument_id: str, period: str) -> str:
    """最新一根 K 线：bars:latest:{instrument_id}:{period}"""
    return f"bars:latest:{instrument_id}:{period}"


def heartbeat_key(service_name: str) -> str:
    """服务心跳：service:heartbeat:{service_name}"""
    return f"service:heartbeat:{service_name}"


def backtest_progress_key(run_id: str) -> str:
    return f"backtest:progress:{run_id}"


def broker_status_key(broker_id: str) -> str:
    return f"broker:status:{broker_id}"


RISK_STATUS_KEY = "risk:status"


# ── Stream 名（事件流） ──────────────────────────────────────────────────────

STREAM_MARKET_TICKS = "stream:market:ticks"
STREAM_MARKET_BARS  = "stream:market:bars"
STREAM_NEWS         = "stream:news"
STREAM_AI_SIGNALS   = "stream:ai:signals"
STREAM_ORDERS       = "stream:orders"
STREAM_RISK         = "stream:risk"
STREAM_BACKTEST     = "stream:backtest"
STREAM_SYSTEM       = "stream:system"


# ── Queue 名（任务队列） ─────────────────────────────────────────────────────

QUEUE_NEWS_FETCH       = "queue:news.fetch"
QUEUE_NEWS_AI_ANALYZE  = "queue:news.ai_analyze"
QUEUE_BACKTEST_RUN     = "queue:backtest.run"
QUEUE_AI_SIGNAL_SCAN   = "queue:ai.signal_scan"
QUEUE_MARKET_CACHE_BARS = "queue:market.cache_bars"


# ── Lock Key（分布式锁） ─────────────────────────────────────────────────────

def lock_news_crawl(source_id: str) -> str:
    return f"lock:news:crawl:{source_id}"


def lock_backtest(config_hash: str) -> str:
    return f"lock:backtest:{config_hash}"


def lock_order(client_order_id: str) -> str:
    return f"lock:order:{client_order_id}"


def lock_bars(instrument_id: str, period: str, start: str, end: str) -> str:
    return f"lock:bars:{instrument_id}:{period}:{start}:{end}"
