# server/apps/ai/main.py
from __future__ import annotations
import threading
import time

from server.shared.config.settings import get_settings
from server.shared.logging.setup import setup_logging, get_logger
from server.shared.redis.heartbeat import write_heartbeat
# 导入 runner 确保任务被注册
from server.apps.ai.runner import news_ai_analyze_task, ai_signal_scan_task

logger = get_logger("ai.main")


def _heartbeat_loop():
    """定期写入 ai 服务的心跳。"""
    while True:
        try:
            write_heartbeat("ai")
        except Exception as e:
            logger.warn(f"Failed to write AI heartbeat: {e}")
        time.sleep(5.0)


# ── Dramatiq 载入时执行初始化 ──────────────────────────────────────────────────
s = get_settings()
setup_logging("ai", s.log_dir)
logger.info("Initializing AI Service Dramatiq Worker...")

t = threading.Thread(target=_heartbeat_loop, name="ai_heartbeat", daemon=True)
t.start()
