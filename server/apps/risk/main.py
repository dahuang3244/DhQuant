# server/apps/risk/main.py
from __future__ import annotations
import asyncio
import signal
import threading
from server.shared.config.settings import get_settings
from server.shared.logging.setup import setup_logging, get_logger
from server.shared.redis.heartbeat import write_heartbeat
from server.apps.risk.runner import run_risk_loop

logger = get_logger("risk.main")
_hb_stop = threading.Event()


def _heartbeat_loop():
    """定期上报 Risk 进程心跳。"""
    while not _hb_stop.is_set():
        try:
            write_heartbeat("risk")
        except Exception as e:
            logger.warn(f"Failed to write risk heartbeat: {e}")
        _hb_stop.wait(5.0)


async def main():
    s = get_settings()
    setup_logging("risk", s.log_dir)
    logger.info("Initializing Risk Control Service...")

    # 1. 启动心跳线程
    _hb_stop.clear()
    t = threading.Thread(target=_heartbeat_loop, name="risk_heartbeat", daemon=True)
    t.start()

    # 2. 运行主循环
    stop_event = asyncio.Event()

    def handle_exit():
        logger.info("Received stop signal, shutting down risk service...")
        stop_event.set()

    loop = asyncio.get_running_loop()
    for sig in (signal.SIGINT, signal.SIGTERM):
        try:
            loop.add_signal_handler(sig, handle_exit)
        except NotImplementedError:
            pass

    try:
        await run_risk_loop(stop_event)
    finally:
        _hb_stop.set()
        t.join(timeout=2.0)
        logger.info("Risk Control Service stopped.")


if __name__ == "__main__":
    asyncio.run(main())
