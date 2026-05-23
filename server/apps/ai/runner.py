# server/apps/ai/runner.py
from __future__ import annotations
import dramatiq
from server.shared.logging.setup import get_logger
from server.shared.redis.queues import setup_dramatiq, NEWS_AI_ANALYZE_QUEUE, AI_SIGNAL_SCAN_QUEUE

logger = get_logger("ai.runner")

# 初始化 Dramatiq 代理
setup_dramatiq()


# dramatiq 队列名不能包含冒号或点，做一下过滤转换
q_news_ai = NEWS_AI_ANALYZE_QUEUE.replace("queue:", "").replace(".", "_")
q_ai_scan = AI_SIGNAL_SCAN_QUEUE.replace("queue:", "").replace(".", "_")


@dramatiq.actor(queue_name=q_news_ai)
def news_ai_analyze_task(news_id: str):
    """异步任务：调用 LLM 分析单条新闻影响。"""
    logger.info(f"Executing news_ai_analyze_task for news_id={news_id}...")
    
    import time
    time.sleep(1.5)
    
    logger.info(f"Successfully processed news_ai_analyze_task for news_id={news_id}.")


@dramatiq.actor(queue_name=q_ai_scan)
def ai_signal_scan_task(instrument_id: str):
    """异步任务：扫描行情特征并生成交易信号。"""
    logger.info(f"Executing ai_signal_scan_task for instrument_id={instrument_id}...")
    
    import time
    time.sleep(1.0)
    
    logger.info(f"Successfully processed ai_signal_scan_task for instrument_id={instrument_id}.")
