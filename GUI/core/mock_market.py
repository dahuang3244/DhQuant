from __future__ import annotations

import math
import random
from datetime import datetime, timedelta

from core.enums import MarketKind, SearchMode
from core.models import (
    FundamentalIndicators,
    OhlcvBar,
    QuoteRow,
    TechnicalIndicators,
    TimingIndicators,
)


TIME_FRAMES = ("分钟", "小时", "日", "月", "年")
PREDICTION_UNITS = ("分钟", "小时", "天")
MAX_PREDICTION_DAYS = 30


def generate_quotes(market: str, mode: str, query: str) -> list[QuoteRow]:
    market_kind = MarketKind(market)
    if mode == SearchMode.SYMBOL.value:
        symbols = [query.strip().upper() or "AAPL"]
        names = [_name_for(symbols[0], market_kind)]
    elif market_kind == MarketKind.CHINA_A:
        symbols = ["600519", "601288", "600036", "601012", "601398"]
        names = ["贵州茅台", "农业银行", "招商银行", "隆基绿能", "工商银行"]
    elif market_kind == MarketKind.CRYPTO:
        symbols = ["BTC", "ETH", "BNB", "XRP", "SOL"]
        names = ["Bitcoin", "Ethereum", "Binance Coin", "XRP", "Solana"]
    else:
        symbols = ["AAPL", "MSFT", "GOOGL", "AMZN", "NVDA"]
        names = ["Apple Inc.", "Microsoft", "Alphabet", "Amazon", "NVIDIA"]

    rows: list[QuoteRow] = []
    for index, symbol in enumerate(symbols):
        seed = abs(hash((market, symbol))) % 10_000
        rnd = random.Random(seed)
        base = 90.0 + index * 42.0 + rnd.random() * 25.0
        if market_kind == MarketKind.CRYPTO:
            base *= 120.0
        bars = _bars(base, rnd, "分钟", 72)
        last = bars[-1].close
        prev = bars[-2].close
        change = (last - prev) / prev * 100.0
        volume = bars[-1].volume
        turnover = volume * last

        rows.append(
            QuoteRow(
                symbol=symbol,
                name=names[index],
                market=_market_label(market_kind),
                last_price=last,
                change_percent=change,
                volume=volume,
                turnover=turnover,
                update_time="14:35:20",
                bars=bars,
                time_frame="分钟",
                custom_count=72,
                prediction_unit="天",
                prediction_amount=1,
                forecast=[],
                forecast_start_index=len(bars),
                technical=_technical(bars),
                fundamental=_fundamental(index, last),
                timing=_timing(index, change),
            )
        )
    return rows


def generate_bars(
    base: float,
    symbol: str,
    time_frame: str,
    custom_count: int = 72,
) -> list[OhlcvBar]:
    frame = time_frame if time_frame in TIME_FRAMES else "分钟"
    count = max(6, min(6000, custom_count))
    seed = abs(hash(("bars", symbol, frame, count))) % 10_000
    rnd = random.Random(seed)
    return _bars(base, rnd, frame, count)


def normalize_prediction_amount(unit: str, amount: int) -> int:
    value = max(1, amount)
    if unit == "分钟":
        return min(MAX_PREDICTION_DAYS * 24 * 60, value)
    if unit == "小时":
        return min(MAX_PREDICTION_DAYS * 24, value)
    return min(MAX_PREDICTION_DAYS, value)


def technical_for_bars(bars: list[OhlcvBar]) -> TechnicalIndicators:
    return _technical(bars)


def generate_prediction(
    bars: list[OhlcvBar],
    symbol: str,
    unit: str,
    amount: int,
) -> list[OhlcvBar]:
    if not bars:
        return []

    horizon_unit = unit if unit in PREDICTION_UNITS else "天"
    horizon_amount = normalize_prediction_amount(horizon_unit, amount)
    points = _prediction_points(horizon_unit, horizon_amount)
    seed = abs(hash(("kronos", symbol, horizon_unit, horizon_amount, bars[-1].close))) % 10_000
    rnd = random.Random(seed)
    closes = [bar.close for bar in bars]
    short_ma = _sma(closes, min(8, len(closes)))
    long_ma = _sma(closes, min(28, len(closes)))
    trend = (short_ma - long_ma) / max(1.0, points)
    volatility = max(0.08, sum(abs(closes[i] - closes[i - 1]) for i in range(1, len(closes))) / max(1, len(closes) - 1))

    rows: list[OhlcvBar] = []
    price = bars[-1].close
    for i in range(points):
        wave = math.sin((i + 1) / 3.2) * volatility * 0.22
        drift = trend * 0.55 + wave + rnd.uniform(-volatility * 0.18, volatility * 0.18)
        open_price = price
        close = max(0.5, open_price + drift)
        high = max(open_price, close) + volatility * rnd.uniform(0.15, 0.55)
        low = min(open_price, close) - volatility * rnd.uniform(0.15, 0.55)
        rows.append(
            OhlcvBar(
                time=_prediction_label(horizon_unit, horizon_amount, i, points),
                open=open_price,
                high=high,
                low=max(0.5, low),
                close=close,
                volume=bars[-1].volume,
            )
        )
        price = close
    return rows


def _name_for(symbol: str, market: MarketKind) -> str:
    known = {
        "AAPL": "Apple Inc.",
        "MSFT": "Microsoft",
        "NVDA": "NVIDIA",
        "600519": "贵州茅台",
        "BTC": "Bitcoin",
        "ETH": "Ethereum",
    }
    return known.get(symbol, f"{_market_label(market)} {symbol}")


def _market_label(market: MarketKind) -> str:
    return {
        MarketKind.US: "US",
        MarketKind.CHINA_A: "A",
        MarketKind.CRYPTO: "Crypto",
    }[market]


def _bars(base: float, rnd: random.Random, time_frame: str, count: int) -> list[OhlcvBar]:
    now = datetime(2026, 5, 3, 14, 35)
    rows: list[OhlcvBar] = []
    price = base
    bar_count, step, label_format = _bar_profile(time_frame, count)
    for i in range(bar_count):
        drift = math.sin(i / 7.0) * 0.45 + rnd.uniform(-0.55, 0.75)
        open_price = price
        close = max(1.0, open_price + drift)
        high = max(open_price, close) + rnd.uniform(0.15, 1.2)
        low = min(open_price, close) - rnd.uniform(0.15, 1.0)
        volume = 850_000 + i * 13_000 + rnd.random() * 480_000
        rows.append(
            OhlcvBar(
                time=_format_bar_time(now - step * (bar_count - 1 - i), label_format),
                open=open_price,
                high=high,
                low=max(0.5, low),
                close=close,
                volume=volume,
            )
        )
        price = close
    return rows


def _bar_profile(time_frame: str, count: int) -> tuple[int, timedelta, str]:
    safe = max(6, min(6000, count))
    if time_frame == "小时":
        return safe, timedelta(hours=1), "%m-%d %H时"
    if time_frame == "日":
        return safe, timedelta(days=1), "%m-%d"
    if time_frame == "月":
        return safe, timedelta(days=30), "%Y-%m"
    if time_frame == "年":
        return min(600, safe), timedelta(days=365), "%Y"
    return safe, timedelta(minutes=5), "%H:%M"


def _format_bar_time(value: datetime, label_format: str) -> str:
    return value.strftime(label_format)


def _prediction_points(unit: str, amount: int) -> int:
    if unit == "分钟":
        return min(96, max(6, amount))
    if unit == "小时":
        return min(96, max(6, amount * 2))
    return min(96, max(6, amount * 4))


def _prediction_label(unit: str, amount: int, index: int, points: int) -> str:
    value = max(1, round((index + 1) * amount / max(1, points)))
    suffix = {"分钟": "m", "小时": "h", "天": "d"}[unit]
    return f"+{value}{suffix}"


def _sma(values: list[float], window: int) -> float:
    if not values:
        return 0.0
    take = values[-window:]
    return sum(take) / len(take)


def _technical(bars: list[OhlcvBar]) -> TechnicalIndicators:
    closes = [bar.close for bar in bars]
    ma5 = _sma(closes, 5)
    ma10 = _sma(closes, 10)
    ma20 = _sma(closes, 20)
    dif = ma5 - ma20
    dea = (ma10 - ma20) * 0.65
    gains = [max(0.0, closes[i] - closes[i - 1]) for i in range(1, len(closes))]
    losses = [max(0.0, closes[i - 1] - closes[i]) for i in range(1, len(closes))]
    avg_gain = _sma(gains, 14)
    avg_loss = _sma(losses, 14) or 0.001
    rsi = 100.0 - 100.0 / (1.0 + avg_gain / avg_loss)
    return TechnicalIndicators(
        ma5=ma5,
        ma10=ma10,
        ma20=ma20,
        ma50=_sma(closes, 50),
        ma200=_sma(closes, 72),
        ema12=ma10 * 0.4 + closes[-1] * 0.6,
        ema26=ma20 * 0.55 + closes[-1] * 0.45,
        bull_line=_sma(closes, 72),
        rsi=rsi,
        kd_k=min(100.0, max(0.0, 50.0 + dif * 6.0)),
        kd_d=min(100.0, max(0.0, 48.0 + dea * 6.0)),
        macd_dif=dif,
        macd_dea=dea,
        macd_hist=dif - dea,
        volume_ma5=_sma([bar.volume for bar in bars], 5),
    )


def _fundamental(index: int, price: float) -> FundamentalIndicators:
    eps = 3.8 + index * 0.45
    return FundamentalIndicators(
        eps=eps,
        pe=price / eps,
        pb=2.4 + index * 0.28,
        dividend_yield=1.2 + index * 0.25,
        net_profit=18.0 + index * 3.6,
        debt_to_asset=31.0 + index * 2.5,
    )


def _timing(index: int, change: float) -> TimingIndicators:
    return TimingIndicators(
        ma_cross_signal=index % 2 == 0,
        is_above_ma=change >= 0,
        macd_cross_signal=change >= 0.35,
        ems_value=42.0 + index * 7.0,
        ems_rising=index % 2 == 1,
        sentiment_score=55.0 + index * 5.0,
    )
