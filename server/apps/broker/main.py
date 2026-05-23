# server/apps/broker/main.py
from __future__ import annotations
import asyncio
import signal
import threading
from server.shared.config.settings import get_settings
from server.shared.logging.setup import setup_logging, get_logger
from server.shared.redis.heartbeat import write_heartbeat
from server.apps.broker.runner import run_broker_loop

logger = get_logger("broker.main")
_hb_stop = threading.Event()


def _heartbeat_loop():
    """定期上报 Broker 进程心跳。"""
    while not _hb_stop.is_set():
        try:
            write_heartbeat("broker")
        except Exception as e:
            logger.warn(f"Failed to write broker heartbeat: {e}")
        _hb_stop.wait(5.0)


async def main():
    s = get_settings()
    setup_logging("broker", s.log_dir)
    logger.info("Initializing Broker Gateway Service...")

    # 1. 启动心跳线程
    _hb_stop.clear()
    t = threading.Thread(target=_heartbeat_loop, name="broker_heartbeat", daemon=True)
    t.start()

    # 2. 运行主循环
    stop_event = asyncio.Event()

    def handle_exit():
        logger.info("Received stop signal, shutting down broker service...")
        stop_event.set()

    loop = asyncio.get_running_loop()
    for sig in (signal.SIGINT, signal.SIGTERM):
        try:
            loop.add_signal_handler(sig, handle_exit)
        except NotImplementedError:
            pass

    try:
        await run_broker_loop(stop_event)
    finally:
        _hb_stop.set()
        t.join(timeout=2.0)
        logger.info("Broker Gateway Service stopped.")


if __name__ == "__main__":
    asyncio.run(main())
