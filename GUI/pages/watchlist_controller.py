from __future__ import annotations

from PySide6.QtCore import QObject, Property, Signal, Slot

from core.enums import BrokerKind, MarketKind, PredictionRange, SearchMode
from core.mock_market import generate_quotes


class WatchlistController(QObject):
    stateChanged = Signal()
    rowsChanged = Signal()
    expandedChanged = Signal()

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
