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
        bars = _bars(base, rnd)
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
                technical=_technical(bars),
                fundamental=_fundamental(index, last),
                timing=_timing(index, change),
            )
        )
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


def _bars(base: float, rnd: random.Random) -> list[OhlcvBar]:
    now = datetime(2026, 5, 3, 14, 35)
    rows: list[OhlcvBar] = []
    price = base
    for i in range(72):
        drift = math.sin(i / 7.0) * 0.45 + rnd.uniform(-0.55, 0.75)
        open_price = price
        close = max(1.0, open_price + drift)
        high = max(open_price, close) + rnd.uniform(0.15, 1.2)
        low = min(open_price, close) - rnd.uniform(0.15, 1.0)
        volume = 850_000 + i * 13_000 + rnd.random() * 480_000
        rows.append(
            OhlcvBar(
                time=(now - timedelta(minutes=(71 - i) * 5)).strftime("%H:%M"),
                open=open_price,
                high=high,
                low=max(0.5, low),
                close=close,
                volume=volume,
            )
        )
        price = close
    return rows


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
