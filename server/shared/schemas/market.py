# server/shared/schemas/market.py
from __future__ import annotations
from datetime import datetime
from pydantic import BaseModel, Field


class QuoteDTO(BaseModel):
    """实时报价。"""
    instrument_id: str
    symbol: str
    name: str
    price: float
    change: float           # 涨跌额
    change_pct: float       # 涨跌幅（如 0.025 = 2.5%）
    volume: int             # 成交量（手）
    turnover: float         # 成交额（元）
    high: float
    low: float
    open: float
    prev_close: float
    timestamp: datetime


class BarDTO(BaseModel):
    """一根 K 线。"""
    instrument_id: str
    period: str             # "1m" / "5m" / "1d" 等
    open: float
    high: float
    low: float
    close: float
    volume: int
    turnover: float
    timestamp: datetime


class IndicatorDTO(BaseModel):
    """技术指标计算结果。"""
    instrument_id: str
    period: str
    ma5: float | None = None
    ma10: float | None = None
    ma20: float | None = None
    macd: float | None = None
    macd_signal: float | None = None
    rsi14: float | None = None
    calculated_at: datetime


class InstrumentDTO(BaseModel):
    """交易标的。"""
    id: str
    symbol: str
    name: str
    exchange: str
    asset_type: str
    is_active: bool = True
    created_at: str | None = None
    updated_at: str | None = None


class BarCacheDTO(BaseModel):
    """K 线缓存索引元数据。"""
    id: str
    instrument_id: str
    period: str
    start_time: str
    end_time: str
    source: str
    storage_type: str = "parquet"
    storage_path: str
    row_count: int = 0
    checksum: str | None = None
