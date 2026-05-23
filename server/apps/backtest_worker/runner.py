# server/apps/backtest_worker/runner.py
from __future__ import annotations
import dramatiq
from server.shared.logging.setup import get_logger
from server.shared.redis.queues import setup_dramatiq, BACKTEST_RUN_QUEUE

logger = get_logger("backtest.runner")

# 初始化 Dramatiq 代理
setup_dramatiq()


# dramatiq 队列名不能包含冒号或点，做一下过滤转换
q_backtest = BACKTEST_RUN_QUEUE.replace("queue:", "").replace(".", "_")


@dramatiq.actor(queue_name=q_backtest)
def run_backtest_task(run_id: str):
    """异步任务：执行回测计算并输出绩效与权益曲线。"""
    logger.info(f"Executing run_backtest_task for run_id={run_id}...")
    
    # 模拟长时间运行的回测任务
    import time
    for i in range(1, 6):
        time.sleep(0.5)
        # 上报回测进度
        # 实际可用 redis.set(backtest_progress_key(run_id), progress_json)
        logger.info(f"Backtest {run_id} progress: {i * 20}%")
        
    logger.info(f"Successfully processed run_backtest_task for run_id={run_id}.")
