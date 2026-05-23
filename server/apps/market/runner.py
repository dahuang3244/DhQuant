# server/apps/market/runner.py
from __future__ import annotations
import asyncio
import dramatiq
import random
from server.shared.logging.setup import get_logger
from server.shared.redis.client import get_redis
from server.shared.redis.keys import STREAM_MARKET_TICKS, quote_key
from server.shared.redis.serialization import to_json
from server.shared.redis.streams import xadd_json
from server.shared.redis.queues import setup_dramatiq, MARKET_CACHE_BARS_QUEUE

logger = get_logger("market.runner")

setup_dramatiq()
q_market_cache = MARKET_CACHE_BARS_QUEUE.replace("queue:", "").replace(".", "_")


@dramatiq.actor(queue_name=q_market_cache)
def cache_bars_task(instrument_id: str, period: str, start: str, end: str):
    logger.info(f"Executing cache_bars_task for instrument={instrument_id}, period={period} from {start} to {end}...")
    import time
    time.sleep(1.0)
    logger.info(f"Successfully finished cache_bars_task for instrument={instrument_id}.")


async def run_market_loop(stop_event: asyncio.Event):
    """行情处理与报价生成主循环（Mock 仿真）。"""
    logger.info("Starting Market Data loop...")
    r = get_redis()
    
    # 模拟标的
    symbols = ["000001.SZ", "600000.SH"]
    prices = {sym: 10.0 for sym in symbols}
    
    while not stop_event.is_set():
        try:
            for sym in symbols:
                # 随机模拟涨跌
                change = round(random.uniform(-0.02, 0.02), 4)
                prices[sym] = round(prices[sym] * (1.0 + change), 2)
                
                quote_data = {
                    "instrument_id": sym,
                    "symbol": sym,
                    "name": "Mock " + sym.split(".")[0],
                    "price": prices[sym],
                    "change": change,
                    "change_pct": change,
                    "volume": random.randint(100, 5000),
                    "turnover": prices[sym] * random.randint(100, 5000),
                    "high": prices[sym] * 1.01,
                    "low": prices[sym] * 0.99,
                    "open": prices[sym] * 1.0,
                    "prev_close": prices[sym] / (1.0 + change),
                    "timestamp": asyncio.get_event_loop().time()
                }
                
                # 1. 写入 Redis 热状态缓存
                r.set(quote_key(sym), to_json(quote_data), ex=60)
                
                # 2. 写入 Redis Stream 发布行情更新事件
                xadd_json(STREAM_MARKET_TICKS, quote_data)
                
                # 3. 广播到 PubSub 频道供 WebSocket 实时接收
                r.publish("channel:market", to_json(quote_data))

            logger.debug(f"Pushed mock quotes: {prices}")

        except Exception as e:
            logger.error(f"Error in market loop: {e}")

        # 每 2 秒刷新一次行情
        await asyncio.sleep(2.0)
