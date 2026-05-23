# server/apps/broker/runner.py
from __future__ import annotations
import asyncio
from server.shared.logging.setup import get_logger
from server.shared.redis.client import get_redis
from server.shared.redis.keys import broker_status_key
from server.shared.redis.serialization import to_json

logger = get_logger("broker.runner")


async def run_broker_loop(stop_event: asyncio.Event):
    """交易网关服务主循环（同步账户与持仓状态，监听实盘成交）。"""
    logger.info("Starting Broker synchronization loop...")
    r = get_redis()
    broker_id = "sim_broker"
    
    while not stop_event.is_set():
        try:
            # 模拟同步账户和交易柜台状态
            broker_status = {
                "broker_id": broker_id,
                "connected": True,
                "account_no": "SIM-12345",
                "cash": 100000.0,
                "net_liquidation": 100000.0,
                "last_sync_at": asyncio.get_event_loop().time()
            }
            
            # 写入 Redis 缓存柜台连接状态
            r.set(broker_status_key(broker_id), to_json(broker_status), ex=60)
            logger.debug(f"Updated broker status for {broker_id} in Redis.")

        except Exception as e:
            logger.error(f"Error in broker loop: {e}")

        # 每 5 秒同步一次柜台状态
        await asyncio.sleep(5.0)
