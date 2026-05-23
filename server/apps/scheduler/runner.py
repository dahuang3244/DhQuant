# server/apps/scheduler/runner.py
from __future__ import annotations
import asyncio
from server.shared.logging.setup import get_logger

logger = get_logger("scheduler.runner")


async def run_scheduler_loop(stop_event: asyncio.Event):
    """定时调度服务主循环（定时向各服务队列投递任务）。"""
    logger.info("Starting Scheduler loop...")
    
    # 计数器用于控制不同频率的任务
    counter = 0

    while not stop_event.is_set():
        try:
            # 1. 每 10 秒触发一次新闻抓取
            if counter % 10 == 0:
                try:
                    from server.apps.news.runner import fetch_news_task
                    fetch_news_task.send(source_id="eastmoney", limit=10)
                    logger.info("Scheduler: Enqueued news fetch task for eastmoney.")
                except Exception as e:
                    logger.error(f"Scheduler failed to enqueue news fetch task: {e}")

            # 2. 每 30 秒触发一次 AI 信号扫描
            if counter % 30 == 0:
                try:
                    from server.apps.ai.runner import ai_signal_scan_task
                    ai_signal_scan_task.send(instrument_id="SZ.000001")
                    logger.info("Scheduler: Enqueued AI signal scan task for SZ.000001.")
                except Exception as e:
                    logger.error(f"Scheduler failed to enqueue AI signal scan task: {e}")

            # 3. 每 60 秒清理一次过期缓存（此处仅作日志记录）
            if counter % 60 == 0:
                logger.info("Scheduler: Triggered cache cleanup (mocked).")

            counter += 5

        except Exception as e:
            logger.error(f"Error in scheduler loop: {e}")

        # 每 5 秒迭代一次
        await asyncio.sleep(5.0)
