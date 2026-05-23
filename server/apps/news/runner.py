# server/apps/news/runner.py
from __future__ import annotations
import dramatiq
from server.shared.logging.setup import get_logger
from server.shared.redis.queues import setup_dramatiq, NEWS_FETCH_QUEUE

logger = get_logger("news.runner")

# 初始化 Dramatiq 代理
setup_dramatiq()


# dramatiq 队列名不能包含冒号或点，做一下过滤转换
dramatiq_queue = NEWS_FETCH_QUEUE.replace("queue:", "").replace(".", "_")


@dramatiq.actor(queue_name=dramatiq_queue)
def fetch_news_task(source_id: str, limit: int = 10):
    """异步任务：抓取指定源的新闻并保存到数据库。"""
    logger.info(f"Executing fetch_news_task for source={source_id}, limit={limit}...")
    
    # Mock 行动
    import time
    time.sleep(1.0)
    
    logger.info(f"Successfully processed fetch_news_task for source={source_id}.")
