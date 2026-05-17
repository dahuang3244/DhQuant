from __future__ import annotations

from PySide6.QtCore import QObject, Property, Signal, Slot

from core.enums import BrokerKind, MarketKind, PredictionRange, SearchMode


class WatchlistController(QObject):
    stateChanged = Signal()
    rowsChanged = Signal()
    expandedChanged = Signal()
    favoriteToggled = Signal(str, str, str, bool)

    def __init__(self) -> None:
        super().__init__()
        self._market = MarketKind.US.value
        self._broker = BrokerKind.US_BROKER.value
        self._search_mode = SearchMode.MARKET.value
        self._query = ""
        self._prediction_range = PredictionRange.DAY_1.value
        self._loading = False
        self._error = ""
        self._rows: list[dict] = []
        self._expanded_symbol = ""

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
    def query(self) -> str:
        return self._query

    @Property(str, notify=stateChanged)
    def predictionRange(self) -> str:
        return self._prediction_range

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
    def setMarket(self, market: str) -> None:
        self._market = market
        self.stateChanged.emit()

    @Slot(str)
    def setBroker(self, broker: str) -> None:
        self._broker = broker
        self.stateChanged.emit()

    @Slot(str)
    def setSearchMode(self, mode: str) -> None:
        self._search_mode = mode
        self.stateChanged.emit()

    @Slot(str)
    def setQuery(self, query: str) -> None:
        self._query = query.strip()
        self.stateChanged.emit()

    @Slot(str)
    def setPredictionRange(self, value: str) -> None:
        self._prediction_range = value
        self.stateChanged.emit()

    @Slot()
    def search(self) -> None:
        self._loading = False
        self._error = ""
        self._rows = []
        self.rowsChanged.emit()
        self.stateChanged.emit()

    @Slot(str)
    def toggleExpanded(self, symbol: str) -> None:
        self._expanded_symbol = "" if self._expanded_symbol == symbol else symbol
        self.expandedChanged.emit()

    @Slot(str)
    def toggleFavorite(self, symbol: str) -> None:
        self.favoriteToggled.emit(symbol, "", self._market, False)

    @Slot(str, result="QVariantList")
    def barsFor(self, symbol: str) -> list[dict]:
        return []

    @Slot(str, result="QVariantMap")
    def indicatorsFor(self, symbol: str) -> dict:
        return {}

    @Slot(str, str, int)
    def setTimeFrame(self, symbol: str, time_frame: str, custom_count: int) -> None:
        self.rowsChanged.emit()

    @Slot(str, str, str, result=bool)
    def requestPrediction(self, symbol: str, unit: str, amount: str) -> bool:
        self.rowsChanged.emit()
        return False
