# server/apps/risk/runner.py
from __future__ import annotations
import asyncio
from server.shared.logging.setup import get_logger
from server.shared.redis.client import get_redis
from server.shared.redis.keys import RISK_STATUS_KEY
from server.shared.redis.serialization import to_json

logger = get_logger("risk.runner")


async def run_risk_loop(stop_event: asyncio.Event):
    """风险控制服务主循环（定期检查风险敞口并上报风险状态）。"""
    logger.info("Starting Risk monitoring loop...")
    r = get_redis()
    
    while not stop_event.is_set():
        try:
            # 模拟计算当前的风险状态
            risk_status = {
                "status": "IDLE",  # IDLE / CRITICAL
                "max_drawdown": 0.05,
                "exposure_pct": 0.13,
                "triggered_rules_count": 0,
                "timestamp": asyncio.get_event_loop().time()
            }
            
            # 写入 Redis 全局状态缓存
            r.set(RISK_STATUS_KEY, to_json(risk_status), ex=60)
            logger.debug("Updated risk status in Redis.")

        except Exception as e:
            logger.error(f"Error in risk loop: {e}")

        # 每 5 秒评估一次风险状态
        await asyncio.sleep(5.0)
