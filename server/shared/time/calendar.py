from __future__ import annotations
from datetime import date, timedelta

# 第一版：简单规则（周一到周五是交易日，法定节假日后续再补）
# 后续可以接 akshare 的交易日历 API 替换这个实现

_WEEKDAYS = {0, 1, 2, 3, 4}  # Monday=0 ... Friday=4


def is_trading_day(d: date | None = None) -> bool:
    """第一版：周末不交易。生产版本需接真实节假日数据。"""
    if d is None:
        d = date.today()
    return d.weekday() in _WEEKDAYS


def next_trading_day(d: date | None = None) -> date:
    if d is None:
        d = date.today()
    candidate = d + timedelta(days=1)
    while not is_trading_day(candidate):
        candidate += timedelta(days=1)
    return candidate


def trading_days_in_range(start: date, end: date) -> list[date]:
    """生成范围内的所有交易日"""
    result = []
    curr = start
    while curr <= end:
        if is_trading_day(curr):
            result.append(curr)
        curr += timedelta(days=1)
    return result
