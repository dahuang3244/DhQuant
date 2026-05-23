# server/apps/news/main.py
from __future__ import annotations
import threading
import time

from server.shared.config.settings import get_settings
from server.shared.logging.setup import setup_logging, get_logger
from server.shared.redis.heartbeat import write_heartbeat
# 必须导入 runner 确保任务 actor 被 Dramatiq 注册
from server.apps.news.runner import fetch_news_task

logger = get_logger("news.main")


def _heartbeat_loop():
    """定期写入 news 服务的心跳到 Redis。"""
    while True:
        try:
            write_heartbeat("news")
        except Exception as e:
            logger.warn(f"Failed to write news heartbeat: {e}")
        time.sleep(5.0)


# ── Dramatiq 载入时执行初始化 ──────────────────────────────────────────────────
s = get_settings()
setup_logging("news", s.log_dir)
logger.info("Initializing News Service Dramatiq Worker...")

t = threading.Thread(target=_heartbeat_loop, name="news_heartbeat", daemon=True)
t.start()
