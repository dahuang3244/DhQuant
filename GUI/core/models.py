from __future__ import annotations

from dataclasses import asdict, dataclass, field
from typing import Any


@dataclass
class OhlcvBar:
    time: str
    open: float
    high: float
    low: float
    close: float
    volume: float

    def to_qml(self) -> dict[str, Any]:
        return asdict(self)


@dataclass
class TechnicalIndicators:
    ma5: float
    ma10: float
    ma20: float
    ma50: float
    ma200: float
    ema12: float
    ema26: float
    bull_line: float
    rsi: float
    kd_k: float
    kd_d: float
    macd_dif: float
    macd_dea: float
    macd_hist: float
    volume_ma5: float

    def to_qml(self) -> dict[str, Any]:
        return asdict(self)


@dataclass
class FundamentalIndicators:
    eps: float
    pe: float
    pb: float
    dividend_yield: float
    net_profit: float
    debt_to_asset: float

    def to_qml(self) -> dict[str, Any]:
        return asdict(self)


@dataclass
class TimingIndicators:
    ma_cross_signal: bool
    is_above_ma: bool
    macd_cross_signal: bool
    ems_value: float
    ems_rising: bool
    sentiment_score: float

    def to_qml(self) -> dict[str, Any]:
        return asdict(self)


@dataclass
class QuoteRow:
    symbol: str
    name: str
    market: str
    last_price: float
    change_percent: float
    volume: float
    turnover: float
    update_time: str
    bars: list[OhlcvBar] = field(default_factory=list)
    time_frame: str = "分钟"
    custom_count: int = 72
    prediction_unit: str = "天"
    prediction_amount: int = 1
    forecast: list[OhlcvBar] = field(default_factory=list)
    forecast_start_index: int = 0
    technical: TechnicalIndicators | None = None
    fundamental: FundamentalIndicators | None = None
    timing: TimingIndicators | None = None

    def to_qml(self) -> dict[str, Any]:
        change = f"{self.change_percent:+.2f}%"
        return {
            "symbol": self.symbol,
            "name": self.name,
            "market": self.market,
            "lastPrice": f"{self.last_price:.2f}",
            "changePercent": change,
            "changeValue": self.change_percent,
            "volume": compact_number(self.volume),
            "turnover": compact_money(self.turnover),
            "updateTime": self.update_time,
            "bars": [bar.to_qml() for bar in self.bars],
            "timeFrame": self.time_frame,
            "customCount": self.custom_count,
            "predictionUnit": self.prediction_unit,
            "predictionAmount": self.prediction_amount,
            "forecast": [bar.to_qml() for bar in self.forecast],
            "forecastStartIndex": self.forecast_start_index or len(self.bars),
            "technical": self.technical.to_qml() if self.technical else {},
            "fundamental": self.fundamental.to_qml() if self.fundamental else {},
            "timing": self.timing.to_qml() if self.timing else {},
        }


def compact_number(value: float) -> str:
    if abs(value) >= 1_000_000_000:
        return f"{value / 1_000_000_000:.2f}B"
    if abs(value) >= 1_000_000:
        return f"{value / 1_000_000:.2f}M"
    if abs(value) >= 1_000:
        return f"{value / 1_000:.2f}K"
    return f"{value:.0f}"


def compact_money(value: float) -> str:
    if abs(value) >= 1_000_000_000:
        return f"${value / 1_000_000_000:.2f}B"
    if abs(value) >= 1_000_000:
        return f"${value / 1_000_000:.2f}M"
    return f"${value:.0f}"
