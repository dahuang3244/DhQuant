# server/shared/time/clock.py
from __future__ import annotations
from datetime import datetime, timezone
import zoneinfo

SHANGHAI_TZ = zoneinfo.ZoneInfo("Asia/Shanghai")


def now() -> datetime:
    """返回当前 Asia/Shanghai 时间（带时区信息）。"""
    return datetime.now(tz=SHANGHAI_TZ)


def to_utc(dt: datetime) -> datetime:
    """把任意带时区的 datetime 转成 UTC。"""
    return dt.astimezone(timezone.utc)


def from_timestamp(ts: float) -> datetime:
    """Unix 时间戳转 Asia/Shanghai datetime。"""
    return datetime.fromtimestamp(ts, tz=SHANGHAI_TZ)