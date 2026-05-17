from __future__ import annotations

from PySide6.QtCore import QObject, Property, Signal, Slot


class BacktestController(QObject):
    stateChanged = Signal()
    symbolsChanged = Signal()
    resultsChanged = Signal()

    def __init__(self, strategy_ctrl: QObject | None = None) -> None:
        super().__init__()
        self._strategy_ctrl = strategy_ctrl
        self._query = ""
        self._market = "美股"
        self._period = "日K"
        self._start = "2024-01-01"
        self._end = "2026-05-13"
        self._loading = False
        self._error = ""
        self._symbols: list[dict] = []
        self._active_key = ""
        self._selected_strategy = ""
        self._selected_strategies: list[str] = []
        self._mode = "compare"
        self._capital = 100000.0
        self._leverage = 1
        self._commission = 0.001
        self._results: list[dict] = []

    @Property(str, notify=stateChanged)
    def query(self) -> str:
        return self._query

    @Property(str, notify=stateChanged)
    def market(self) -> str:
        return self._market

    @Property(str, notify=stateChanged)
    def period(self) -> str:
        return self._period

    @Property(str, notify=stateChanged)
    def startDate(self) -> str:
        return self._start

    @Property(str, notify=stateChanged)
    def endDate(self) -> str:
        return self._end

    @Property(bool, notify=stateChanged)
    def loading(self) -> bool:
        return self._loading

    @Property(str, notify=stateChanged)
    def error(self) -> str:
        return self._error

    @Property("QVariantList", notify=symbolsChanged)
    def cachedSymbols(self) -> list[dict]:
        return self._symbols

    @Property(str, notify=symbolsChanged)
    def activeKey(self) -> str:
        return self._active_key

    @Property("QVariantList", notify=stateChanged)
    def strategies(self) -> list[str]:
        if self._strategy_ctrl is not None and hasattr(self._strategy_ctrl, "allStrategies"):
            return list(getattr(self._strategy_ctrl, "allStrategies"))
        return []

    @Property(str, notify=stateChanged)
    def strategy(self) -> str:
        return self._selected_strategy

    @Property("QVariantList", notify=stateChanged)
    def selectedStrategies(self) -> list[str]:
        return self._selected_strategies

    @Property(str, notify=stateChanged)
    def mode(self) -> str:
        return self._mode

    @Property(float, notify=stateChanged)
    def initialCapital(self) -> float:
        return self._capital

    @Property(int, notify=stateChanged)
    def leverage(self) -> int:
        return self._leverage

    @Property(float, notify=stateChanged)
    def commission(self) -> float:
        return self._commission

    @Property(int, notify=symbolsChanged)
    def barCount(self) -> int:
        return 0

    @Property(int, notify=resultsChanged)
    def tradeCount(self) -> int:
        return 0

    @Property("QVariantList", notify=resultsChanged)
    def results(self) -> list[dict]:
        return self._results

    @Slot(str)
    def setQuery(self, value: str) -> None:
        self._query = value.strip()
        self.stateChanged.emit()

    @Slot(str)
    def setMarket(self, value: str) -> None:
        self._market = value
        self.stateChanged.emit()

    @Slot(str)
    def setPeriod(self, value: str) -> None:
        self._period = value
        self.stateChanged.emit()

    @Slot(str)
    def setStartDate(self, value: str) -> None:
        self._start = value.strip()
        self.stateChanged.emit()

    @Slot(str)
    def setEndDate(self, value: str) -> None:
        self._end = value.strip()
        self.stateChanged.emit()

    @Slot(str)
    def setStrategy(self, value: str) -> None:
        self._selected_strategy = value
        self.stateChanged.emit()

    @Slot(str)
    def addStrategy(self, value: str) -> None:
        if value and value not in self._selected_strategies:
            self._selected_strategies.append(value)
            self.stateChanged.emit()

    @Slot(str)
    def removeStrategy(self, value: str) -> None:
        if value in self._selected_strategies:
            self._selected_strategies.remove(value)
            self.stateChanged.emit()

    @Slot(str)
    def setMode(self, value: str) -> None:
        self._mode = value
        self.stateChanged.emit()

    @Slot(str)
    def setInitialCapital(self, value: str) -> None:
        self._capital = _to_float(value, self._capital)
        self.stateChanged.emit()

    @Slot(str)
    def setLeverage(self, value: str) -> None:
        self._leverage = max(1, int(_to_float(value, self._leverage)))
        self.stateChanged.emit()

    @Slot(str)
    def setCommission(self, value: str) -> None:
        self._commission = max(0.0, _to_float(value, self._commission))
        self.stateChanged.emit()

    @Slot()
    def search(self) -> None:
        self._loading = False
        self._error = ""
        self._symbols = []
        self._active_key = ""
        self.symbolsChanged.emit()
        self.stateChanged.emit()

    @Slot(str)
    def selectSymbol(self, key: str) -> None:
        self._active_key = key if any(row.get("key") == key for row in self._symbols) else ""
        self.symbolsChanged.emit()

    @Slot(str)
    def removeSymbol(self, key: str) -> None:
        self._symbols = [row for row in self._symbols if row.get("key") != key]
        if self._active_key == key:
            self._active_key = ""
        self.symbolsChanged.emit()

    @Slot()
    def runBacktest(self) -> None:
        self._loading = False
        self._error = ""
        self._results = []
        self.resultsChanged.emit()
        self.stateChanged.emit()

    @Slot()
    def clearResults(self) -> None:
        self._results = []
        self.resultsChanged.emit()

    @Slot(int, result="QVariantList")
    def bars(self, limit: int) -> list[dict]:
        return []

    @Slot(int, result="QVariantList")
    def trades(self, limit: int) -> list[dict]:
        return []

    @Slot(int, result="QVariantList")
    def equityCurve(self, limit: int) -> list[dict]:
        return []


def _to_float(value: str, fallback: float) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return fallback
