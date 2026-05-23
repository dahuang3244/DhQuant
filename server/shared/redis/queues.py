# server/shared/redis/queues.py
from __future__ import annotations
import dramatiq
from dramatiq.brokers.redis import RedisBroker
from server.shared.config.settings import get_settings
from .keys import (
    QUEUE_NEWS_FETCH, QUEUE_NEWS_AI_ANALYZE,
    QUEUE_BACKTEST_RUN, QUEUE_AI_SIGNAL_SCAN, QUEUE_MARKET_CACHE_BARS,
)


def setup_dramatiq() -> None:
    """在服务进程启动时调用一次，初始化 Dramatiq broker。"""
    s = get_settings()
    broker = RedisBroker(url=s.redis_url)
    dramatiq.set_broker(broker)


# 队列名常量（和 keys.py 保持一致，Dramatiq 队列名会用到）
NEWS_FETCH_QUEUE      = QUEUE_NEWS_FETCH
NEWS_AI_ANALYZE_QUEUE = QUEUE_NEWS_AI_ANALYZE
BACKTEST_RUN_QUEUE    = QUEUE_BACKTEST_RUN
AI_SIGNAL_SCAN_QUEUE  = QUEUE_AI_SIGNAL_SCAN
MARKET_CACHE_BARS_QUEUE = QUEUE_MARKET_CACHE_BARS
