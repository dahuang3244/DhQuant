# server/apps/backtest_worker/main.py
from __future__ import annotations
import threading
import time

from server.shared.config.settings import get_settings
from server.shared.logging.setup import setup_logging, get_logger
from server.shared.redis.heartbeat import write_heartbeat
# 导入 runner 确保任务被注册
from server.apps.backtest_worker.runner import run_backtest_task

logger = get_logger("backtest_worker.main")


def _heartbeat_loop():
    """定期写入 backtest_worker 服务的心跳。"""
    while True:
        try:
            write_heartbeat("backtest_worker")
        except Exception as e:
            logger.warn(f"Failed to write backtest_worker heartbeat: {e}")
        time.sleep(5.0)


# ── Dramatiq 载入时执行初始化 ──────────────────────────────────────────────────
s = get_settings()
setup_logging("backtest_worker", s.log_dir)
logger.info("Initializing Backtest Worker Service Dramatiq Worker...")

t = threading.Thread(target=_heartbeat_loop, name="backtest_worker_heartbeat", daemon=True)
t.start()
