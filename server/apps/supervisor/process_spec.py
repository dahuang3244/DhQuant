# server/apps/supervisor/process_spec.py
from __future__ import annotations
import os
import sys

# 自动定位当前虚拟环境下的 dramatiq 命令行工具路径，确保 100% 的可移植性
_bin_dir = os.path.dirname(sys.executable)
DRAMATIQ_BIN = os.path.join(_bin_dir, "dramatiq") if os.path.exists(os.path.join(_bin_dir, "dramatiq")) else "dramatiq"

# 进程配置定义
PROCESS_SPECS = {
    "api": [sys.executable, "-m", "server.apps.api.main"],
    "market": [sys.executable, "-m", "server.apps.market.main"],
    "news": [DRAMATIQ_BIN, "server.apps.news.main", "--processes", "1"],
    "ai": [DRAMATIQ_BIN, "server.apps.ai.main", "--processes", "1"],
    "backtest_worker": [DRAMATIQ_BIN, "server.apps.backtest_worker.main", "--processes", "1"],
    "risk": [sys.executable, "-m", "server.apps.risk.main"],
    "broker": [sys.executable, "-m", "server.apps.broker.main"],
    "scheduler": [sys.executable, "-m", "server.apps.scheduler.main"]
}
