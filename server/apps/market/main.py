# server/apps/market/main.py
from __future__ import annotations
import asyncio
import signal
import threading
from server.shared.config.settings import get_settings
from server.shared.logging.setup import setup_logging, get_logger
from server.shared.redis.heartbeat import write_heartbeat
from server.apps.market.runner import run_market_loop

logger = get_logger("market.main")
_hb_stop = threading.Event()


def _heartbeat_loop():
    """定期上报 Market 进程心跳。"""
    while not _hb_stop.is_set():
        try:
            write_heartbeat("market")
        except Exception as e:
            logger.warn(f"Failed to write market heartbeat: {e}")
        _hb_stop.wait(5.0)


async def main():
    s = get_settings()
    setup_logging("market", s.log_dir)
    logger.info("Initializing Market Data Service...")

    # 1. 启动心跳线程
    _hb_stop.clear()
    t = threading.Thread(target=_heartbeat_loop, name="market_heartbeat", daemon=True)
    t.start()

    # 2. 运行主循环
    stop_event = asyncio.Event()

    # 优雅关闭处理
    def handle_exit():
        logger.info("Received stop signal, shutting down market service...")
        stop_event.set()

    loop = asyncio.get_running_loop()
    for sig in (signal.SIGINT, signal.SIGTERM):
        try:
            loop.add_signal_handler(sig, handle_exit)
        except NotImplementedError:
            # Windows 兼容
            pass

    try:
        await run_market_loop(stop_event)
    finally:
        _hb_stop.set()
        t.join(timeout=2.0)
        logger.info("Market Data Service stopped.")


if __name__ == "__main__":
    asyncio.run(main())
