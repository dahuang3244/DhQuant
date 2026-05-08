from __future__ import annotations

from PySide6.QtCore import QObject, Property, Signal, Slot

from core.enums import BrokerKind, MarketKind, PredictionRange, SearchMode
from core.mock_market import (
    generate_bars,
    generate_prediction,
    generate_quotes,
    normalize_prediction_amount,
    technical_for_bars,
)
from core.models import compact_money, compact_number


class WatchlistController(QObject):
    stateChanged = Signal()
    rowsChanged = Signal()
    expandedChanged = Signal()
    favoriteToggled = Signal(str, str, str, bool)

    def __init__(self) -> None:
        super().__init__()
        self._market = MarketKind.US.value
        self._broker = BrokerKind.MOCK.value
        self._search_mode = SearchMode.SYMBOL.value
        self._prediction_range = PredictionRange.DAY_1.value
        self._query = "AAPL"
        self._expanded_symbol = ""
        self._loading = False
        self._error = ""
        self._rows: list[dict] = []
        self._favorite_keys: set[str] = set()

    @Property(str, notify=stateChanged)
    def market(self) -> str:
        return self._market

    @Property(str, notify=stateChanged)
    def broker(self) -> str:
        return self._broker

    @Property(str, notify=stateChanged)
    def searchMode(self) -> str:
        return self._search_mode

    @Property(str, notify=stateChanged)
    def predictionRange(self) -> str:
        return self._prediction_range

    @Property(str, notify=stateChanged)
    def query(self) -> str:
        return self._query

    @Property(bool, notify=stateChanged)
    def loading(self) -> bool:
        return self._loading

    @Property(str, notify=stateChanged)
    def error(self) -> str:
        return self._error

    @Property("QVariantList", notify=rowsChanged)
    def rows(self) -> list[dict]:
        return self._rows

    @Property(str, notify=expandedChanged)
    def expandedSymbol(self) -> str:
        return self._expanded_symbol

    @Slot(str)
    def setMarket(self, value: str) -> None:
        if value == self._market:
            return
        self._market = value
        self.stateChanged.emit()

    @Slot(str)
    def setBroker(self, value: str) -> None:
        if value == self._broker:
            return
        self._broker = value
        self.stateChanged.emit()

    @Slot(str)
    def setSearchMode(self, value: str) -> None:
        if value == self._search_mode:
            return
        self._search_mode = value
        self.stateChanged.emit()

    @Slot(str)
    def setPredictionRange(self, value: str) -> None:
        if value == self._prediction_range:
            return
        self._prediction_range = value
        self.stateChanged.emit()

    @Slot(str)
    def setQuery(self, value: str) -> None:
        if value == self._query:
            return
        self._query = value
        self.stateChanged.emit()

    @Slot()
    def search(self) -> None:
        self._loading = True
        self._error = ""
        self.stateChanged.emit()
        try:
            quotes = generate_quotes(self._market, self._search_mode, self._query)
            self._rows = [quote.to_qml() for quote in quotes]
            for row in self._rows:
                row["isFavorite"] = self._row_key(row) in self._favorite_keys
            if self._rows and not self._expanded_symbol:
                self._expanded_symbol = self._rows[0]["symbol"]
        except Exception as exc:
            self._rows = []
            self._error = str(exc)
        finally:
            self._loading = False
            self.stateChanged.emit()
            self.rowsChanged.emit()
            self.expandedChanged.emit()

    @Slot(str)
    def toggleExpanded(self, symbol: str) -> None:
        self._expanded_symbol = "" if self._expanded_symbol == symbol else symbol
        self.expandedChanged.emit()

    @Slot(str)
    def toggleFavorite(self, symbol: str) -> None:
        row = self._find_row(symbol)
        if not row:
            return

        key = self._row_key(row)
        is_favorite = key not in self._favorite_keys
        if is_favorite:
            self._favorite_keys.add(key)
        else:
            self._favorite_keys.discard(key)

        row["isFavorite"] = is_favorite
        self.rowsChanged.emit()
        self.favoriteToggled.emit(
            str(row.get("symbol", "")),
            str(row.get("name", "")),
            str(row.get("market", "")),
            is_favorite,
        )

    @Slot(str, result="QVariantList")
    def barsFor(self, symbol: str) -> list[dict]:
        for row in self._rows:
            if row.get("symbol") == symbol:
                return row.get("bars", [])
        return []

    @Slot(str, result="QVariantMap")
    def rowFor(self, symbol: str) -> dict:
        for row in self._rows:
            if row.get("symbol") == symbol:
                return row
        return {}

    @Slot(str, str, int)
    def setTimeFrame(self, symbol: str, value: str, custom_count: int = 72) -> None:
        row = self._find_row(symbol)
        if not row:
            return

        count = max(6, min(6000, int(custom_count or 72)))
        if row.get("timeFrame") == value and int(row.get("customCount") or 72) == count:
            return

        base = self._last_close(row)
        bars = generate_bars(base, symbol, value, count)
        self._apply_bars(row, bars)
        row["timeFrame"] = value
        row["customCount"] = count
        row["forecast"] = []
        row["forecastStartIndex"] = len(bars)
        self.rowsChanged.emit()

    @Slot(str, str, str, result=bool)
    def requestPrediction(self, symbol: str, unit: str, amount: str) -> bool:
        row = self._find_row(symbol)
        if not row:
            return False

        try:
            raw_amount = int(float(amount))
        except (TypeError, ValueError):
            raw_amount = 1

        normalized = normalize_prediction_amount(unit, raw_amount)
        bars = row.get("bars", [])
        forecast = generate_prediction(
            bars=[self._bar_from_dict(bar) for bar in bars],
            symbol=symbol,
            unit=unit,
            amount=normalized,
        )
        row["predictionUnit"] = unit if unit in ("分钟", "小时", "天") else "天"
        row["predictionAmount"] = normalized
        row["forecastStartIndex"] = int(row.get("forecastStartIndex") or len(bars))
        if row["forecastStartIndex"] > len(bars):
            row["forecastStartIndex"] = len(bars)
        if not row.get("forecast"):
            row["forecastStartIndex"] = len(bars)
        row["forecast"] = [bar.to_qml() for bar in forecast]
        self.rowsChanged.emit()
        return True

    def _find_row(self, symbol: str) -> dict:
        for row in self._rows:
            if row.get("symbol") == symbol:
                return row
        return {}

    def _row_key(self, row: dict) -> str:
        return f"{row.get('market', '')}:{row.get('symbol', '')}"

    def _last_close(self, row: dict) -> float:
        bars = row.get("bars") or []
        if bars:
            return float(bars[-1].get("close", 1.0))
        try:
            return float(row.get("lastPrice", 1.0))
        except (TypeError, ValueError):
            return 1.0

    def _apply_bars(self, row: dict, bars: list) -> None:
        if not bars:
            return
        prev_close = bars[-2].close if len(bars) > 1 else bars[-1].open
        last_close = bars[-1].close
        change = (last_close - prev_close) / max(0.001, prev_close) * 100.0
        row["bars"] = [bar.to_qml() for bar in bars]
        row["lastPrice"] = f"{last_close:.2f}"
        row["changePercent"] = f"{change:+.2f}%"
        row["changeValue"] = change
        row["volume"] = compact_number(bars[-1].volume)
        row["turnover"] = compact_money(bars[-1].volume * last_close)
        row["updateTime"] = bars[-1].time
        row["technical"] = technical_for_bars(bars).to_qml()

    def _bar_from_dict(self, value: dict):
        from core.models import OhlcvBar

        return OhlcvBar(
            time=str(value.get("time", "")),
            open=float(value.get("open", 0.0)),
            high=float(value.get("high", 0.0)),
            low=float(value.get("low", 0.0)),
            close=float(value.get("close", 0.0)),
            volume=float(value.get("volume", 0.0)),
        )
