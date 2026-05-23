# server/apps/supervisor/healthcheck.py
from __future__ import annotations
from datetime import datetime
from server.shared.redis.heartbeat import get_service_status, read_heartbeat
from server.apps.supervisor.process_spec import PROCESS_SPECS


def run_healthcheck() -> dict[str, str]:
    """查询并打印所有后台服务的心跳状态。"""
    print("=" * 70)
    print(f"DhQuant Cluster Health Report - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 70)
    print(f"{'Service Name':<25} | {'Status':<10} | {'Last Heartbeat':<20}")
    print("-" * 70)

    report = {}
    for name in PROCESS_SPECS.keys():
        status = get_service_status(name)
        ts = read_heartbeat(name)
        ts_str = datetime.fromtimestamp(ts).strftime('%Y-%m-%d %H:%M:%S') if ts else "NEVER"
        
        # 终端颜色代码 (仅用于命令行友好输出)
        if status == "alive":
            color = "\033[92m"  # 绿色
        elif status == "stale":
            color = "\033[93m"  # 黄色
        else:
            color = "\033[91m"  # 红色
        reset = "\033[0m"
        
        print(f"{name:<25} | {color}{status:<10}{reset} | {ts_str:<20}")
        report[name] = status

    print("=" * 70)
    return report


if __name__ == "__main__":
    run_healthcheck()
