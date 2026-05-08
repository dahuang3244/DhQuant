from __future__ import annotations

import math
import random
from datetime import datetime, timedelta

from PySide6.QtCore import QObject, Property, Signal, Slot

from pages.strategy_controller import BUILTIN_STRATEGIES

_PERIOD_STEP: dict[str, tuple[timedelta, str, int]] = {
    "分钟K": (timedelta(minutes=1),  "%m-%d %H:%M", 240),
    "小时K": (timedelta(hours=1),    "%m-%d %H时",   168),
    "日K":   (timedelta(days=1),     "%Y-%m-%d",     500),
    "周K":   (timedelta(weeks=1),    "%Y-%m-%d",     200),
    "月K":   (timedelta(days=30),    "%Y-%m",        120),
}


def _mock_bars(symbol: str, period: str, start: str, end: str) -> list[dict]:
    seed = abs(hash((symbol, period, start, end))) % 10_000
    rnd = random.Random(seed)
    try:
        t0 = datetime.strptime(start, "%Y-%m-%d")
        t1 = datetime.strptime(end,   "%Y-%m-%d")
    except ValueError:
        t0, t1 = datetime(2023, 1, 1), datetime(2025, 1, 1)

    step, fmt, max_count = _PERIOD_STEP.get(period, _PERIOD_STEP["日K"])
    days = max(1, (t1 - t0).days)
    count = min(max_count, max(30, days // max(1, step.days or 1)))

    base = 80.0 + abs(hash(symbol)) % 300
    bars, price = [], base
    for i in range(count):
        drift = math.sin(i / 9.0) * 0.7 + rnd.uniform(-0.9, 1.1)
        o = price
        c = max(1.0, o + drift)
        h = max(o, c) + rnd.uniform(0.1, 1.8)
        lo = min(o, c) - rnd.uniform(0.1, 1.4)
        v = 600_000 + i * 4_000 + rnd.random() * 600_000
        bars.append({
            "time":   (t0 + step * i).strftime(fmt),
            "open":   round(o, 2),
            "high":   round(h, 2),
            "low":    round(max(0.5, lo), 2),
            "close":  round(c, 2),
            "volume": round(v),
            "inPosition":  False,
            "tradeEntry":  None,
            "tradeExit":   None,
        })
        price = c
    return bars


def _mock_result(strategy: str, bars: list[dict], capital: float, leverage: int, commission: float) -> dict:
    if not bars:
        return {}
    seed = abs(hash((strategy, capital, len(bars)))) % 10_000
    rnd = random.Random(seed)

    n = len(bars)
    avg_hold = rnd.randint(4, 18)
    trade_count = max(1, n // max(1, avg_hold + rnd.randint(4, 12)))

    annotated = [dict(b) for b in bars]
    trades: list[dict] = []
    equity = capital
    equity_curve = [{"time": bars[0]["time"], "strategy": round(capital, 2),
                     "benchmark": round(capital, 2)}]

    idx = rnd.randint(0, 6)
    for _ in range(trade_count):
        if idx >= n - 2:
            break
        direction = rnd.choice(["多", "空"])
        entry_i = idx
        hold = rnd.randint(max(1, avg_hold - 3), avg_hold + 6)
        exit_i = min(n - 1, entry_i + hold)

        ep = bars[entry_i]["close"]
        xp = bars[exit_i]["close"]
        raw = ((xp - ep) / ep) if direction == "多" else ((ep - xp) / ep)
        bias = (rnd.random() - 0.38) * 0.05
        pct = raw * leverage + bias - commission / 100.0

        pnl = equity * pct
        equity = max(0.01, equity + pnl)

        trades.append({
            "entryTime":  bars[entry_i]["time"],
            "exitTime":   bars[exit_i]["time"],
            "direction":  direction,
            "entryPrice": round(ep, 2),
            "exitPrice":  round(xp, 2),
            "pnl":        round(pnl, 2),
            "pnlPct":     round(pct * 100, 2),
            "holdDays":   exit_i - entry_i,
        })

        annotated[entry_i]["tradeEntry"] = {"direction": direction, "price": round(ep, 2)}
        annotated[exit_i]["tradeExit"]   = {"direction": direction,
                                             "pnlPct":   round(pct * 100, 2),
                                             "price":    round(xp, 2)}
        for k in range(entry_i, exit_i + 1):
            annotated[k]["inPosition"] = True

        bm_ref = bars[0]["close"]
        bm_val = capital * bars[exit_i]["close"] / bm_ref if bm_ref else capital
        equity_curve.append({"time": bars[exit_i]["time"],
                              "strategy":  round(equity, 2),
                              "benchmark": round(bm_val, 2)})
        idx = exit_i + rnd.randint(1, 7)

    if not trades:
        return {}

    ret_pct = (equity - capital) / capital * 100
    wins = sum(1 for t in trades if t["pnlPct"] > 0)
    win_rate = wins / len(trades) * 100

    peak, running, max_dd = capital, capital, 0.0
    for t in trades:
        running += t["pnl"]
        peak = max(peak, running)
        max_dd = max(max_dd, (peak - running) / peak * 100)

    max_float = max((abs(t["pnlPct"]) for t in trades if t["pnlPct"] < 0), default=0.0)
    avg_hold_d = sum(t["holdDays"] for t in trades) / len(trades)
    max_hold_d = max(t["holdDays"] for t in trades)

    return {
        "strategyName":   strategy,
        "initialCapital": round(capital, 2),
        "finalCapital":   round(equity, 2),
        "returnPct":      round(ret_pct, 2),
        "tradeCount":     len(trades),
        "winRate":        round(win_rate, 1),
        "maxDrawdown":    round(max_dd, 2),
        "maxFloatLoss":   round(max_float, 2),
        "avgHoldDays":    round(avg_hold_d, 1),
        "maxHoldDays":    max_hold_d,
        "trades":         trades,
        "equityCurve":    equity_curve,
        "annotatedBars":  annotated,
    }


class BacktestController(QObject):
    stateChanged   = Signal()
    symbolsChanged = Signal()
    resultsChanged = Signal()

    def __init__(self, strategy_ctrl=None) -> None:
        super().__init__()
        self._strategy_ctrl = strategy_ctrl
        if strategy_ctrl is not None:
            strategy_ctrl.strategiesChanged.connect(self.stateChanged)
        self._query    = ""
        self._market   = "美股"
        self._period   = "日K"
        self._start    = "2023-01-01"
        self._end      = "2025-01-01"
        self._loading  = False
        self._error    = ""
        self._cached: list[dict] = []
        self._active_key = ""
        self._strategy  = BUILTIN_STRATEGIES[0]
        self._selected_strategies: list[str] = [BUILTIN_STRATEGIES[0]]
        self._mode      = "compare"
        self._capital  = 10000.0
        self._leverage = 1
        self._commission = 0.0
        self._bars:    dict[str, list[dict]] = {}
        self._results: dict[str, list[dict]] = {}

    # ── properties ──────────────────────────────────────────────────────
    @Property(str,  notify=stateChanged)
    def query(self) -> str: return self._query

    @Property(str,  notify=stateChanged)
    def market(self) -> str: return self._market

    @Property(str,  notify=stateChanged)
    def period(self) -> str: return self._period

    @Property(str,  notify=stateChanged)
    def startDate(self) -> str: return self._start

    @Property(str,  notify=stateChanged)
    def endDate(self) -> str: return self._end

    @Property(bool, notify=stateChanged)
    def loading(self) -> bool: return self._loading

    @Property(str,  notify=stateChanged)
    def error(self) -> str: return self._error

    @Property("QVariantList", notify=symbolsChanged)
    def cachedSymbols(self) -> list[dict]: return self._cached

    @Property(str,  notify=symbolsChanged)
    def activeKey(self) -> str: return self._active_key

    @Property("QVariantList", notify=stateChanged)
    def strategies(self) -> list[str]:
        if self._strategy_ctrl is not None:
            return self._strategy_ctrl.allStrategies
        return BUILTIN_STRATEGIES

    @Property(str,  notify=stateChanged)
    def strategy(self) -> str: return self._strategy

    @Property("QVariantList", notify=stateChanged)
    def selectedStrategies(self) -> list[str]: return self._selected_strategies

    @Property(str,  notify=stateChanged)
    def mode(self) -> str: return self._mode

    @Property(float, notify=stateChanged)
    def initialCapital(self) -> float: return self._capital

    @Property(int,  notify=stateChanged)
    def leverage(self) -> int: return self._leverage

    @Property(float, notify=stateChanged)
    def commission(self) -> float: return self._commission

    @Property(int, notify=symbolsChanged)
    def barCount(self) -> int:
        return len(self._bars.get(self._active_key, []))

    @Property(int, notify=resultsChanged)
    def tradeCount(self) -> int:
        return sum(r.get("tradeCount", 0) for r in self._results.get(self._active_key, []))

    @Property("QVariantList", notify=resultsChanged)
    def results(self) -> list[dict]:
        return self._results.get(self._active_key, [])

    # ── setters ─────────────────────────────────────────────────────────
    @Slot(str)
    def setQuery(self, v: str) -> None:
        if self._query == v: return
        self._query = v; self.stateChanged.emit()

    @Slot(str)
    def setMarket(self, v: str) -> None:
        if self._market == v: return
        self._market = v; self.stateChanged.emit()

    @Slot(str)
    def setPeriod(self, v: str) -> None:
        if self._period == v: return
        self._period = v; self.stateChanged.emit()

    @Slot(str)
    def setStartDate(self, v: str) -> None:
        if self._start == v: return
        self._start = v; self.stateChanged.emit()

    @Slot(str)
    def setEndDate(self, v: str) -> None:
        if self._end == v: return
        self._end = v; self.stateChanged.emit()

    @Slot(str)
    def setStrategy(self, v: str) -> None:
        if self._strategy == v: return
        self._strategy = v; self.stateChanged.emit()

    @Slot(str)
    def addStrategy(self, v: str) -> None:
        if v not in self._selected_strategies:
            self._selected_strategies = self._selected_strategies + [v]
            self.stateChanged.emit()

    @Slot(str)
    def removeStrategy(self, v: str) -> None:
        if v in self._selected_strategies and len(self._selected_strategies) > 1:
            self._selected_strategies = [s for s in self._selected_strategies if s != v]
            self.stateChanged.emit()

    @Slot(str)
    def setMode(self, v: str) -> None:
        if self._mode == v: return
        self._mode = v; self.stateChanged.emit()

    @Slot(str)
    def setInitialCapital(self, v: str) -> None:
        try:    val = max(100.0, float(v))
        except: return
        if self._capital == val: return
        self._capital = val; self.stateChanged.emit()

    @Slot(str)
    def setLeverage(self, v: str) -> None:
        try:    val = max(1, min(20, int(v)))
        except: return
        if self._leverage == val: return
        self._leverage = val; self.stateChanged.emit()

    @Slot(str)
    def setCommission(self, v: str) -> None:
        try:    val = max(0.0, min(5.0, float(v)))
        except: return
        if self._commission == val: return
        self._commission = val; self.stateChanged.emit()

    # ── actions ─────────────────────────────────────────────────────────
    @Slot()
    def search(self) -> None:
        sym = self._query.strip().upper()
        if not sym:
            self._error = "请输入股票代码"
            self.stateChanged.emit()
            return
        key = f"{sym}:{self._market}"
        if not any(s["key"] == key for s in self._cached):
            if len(self._cached) >= 8:
                for i, s in enumerate(self._cached):
                    if s["key"] != self._active_key:
                        self._cached.pop(i); break
            self._cached.append({"key": key, "symbol": sym, "market": self._market})
            self._bars[key] = _mock_bars(sym, self._period, self._start, self._end)
        self._active_key = key
        self._error = ""
        self.stateChanged.emit()
        self.symbolsChanged.emit()

    @Slot(str)
    def selectSymbol(self, key: str) -> None:
        if self._active_key == key: return
        self._active_key = key
        self.symbolsChanged.emit()
        self.resultsChanged.emit()

    @Slot(str)
    def removeSymbol(self, key: str) -> None:
        self._cached = [s for s in self._cached if s["key"] != key]
        self._results.pop(key, None)
        self._bars.pop(key, None)
        if self._active_key == key:
            self._active_key = self._cached[0]["key"] if self._cached else ""
        self.symbolsChanged.emit()
        self.resultsChanged.emit()

    @Slot()
    def runBacktest(self) -> None:
        if not self._active_key: return
        bars = self._bars.get(self._active_key, [])
        all_s = self.strategies
        strats = all_s[:4] if self._mode == "compare" else self._selected_strategies
        results = [_mock_result(s, bars, self._capital, self._leverage, self._commission)
                   for s in strats]
        self._results[self._active_key] = [r for r in results if r]
        self.resultsChanged.emit()
        self.symbolsChanged.emit()

    @Slot()
    def clearResults(self) -> None:
        self._results.pop(self._active_key, None)
        self.resultsChanged.emit()

    # ── data accessors ───────────────────────────────────────────────────
    @Slot(int, result="QVariantList")
    def annotatedBarsForResult(self, index: int) -> list[dict]:
        rs = self._results.get(self._active_key, [])
        if 0 <= index < len(rs):
            return rs[index].get("annotatedBars", [])
        return self._bars.get(self._active_key, [])

    @Slot(int, result="QVariantList")
    def tradesForResult(self, index: int) -> list[dict]:
        rs = self._results.get(self._active_key, [])
        if 0 <= index < len(rs):
            return rs[index].get("trades", [])
        return []

    @Slot(int, result="QVariantList")
    def equityForResult(self, index: int) -> list[dict]:
        rs = self._results.get(self._active_key, [])
        if 0 <= index < len(rs):
            return rs[index].get("equityCurve", [])
        return []
