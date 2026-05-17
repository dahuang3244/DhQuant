from __future__ import annotations

from PySide6.QtCore import QObject, Property, Signal, Slot


class JournalController(QObject):
    stateChanged = Signal()
    unifiedChanged = Signal()
    comparisonChanged = Signal()

    def __init__(self) -> None:
        super().__init__()
        self._source = ""
        self._quick_filter = "all"
        self._panel_open = False
        self._summary_result: dict = {}
        self._unified_rows: list[dict] = []
        self._comparison_result: dict = {}

    @Property(str, notify=stateChanged)
    def source(self) -> str:
        return self._source

    @Property(str, notify=stateChanged)
    def quickFilter(self) -> str:
        return self._quick_filter

    @Property(str, notify=stateChanged)
    def selectedSymbol(self) -> str:
        return ""

    @Property(bool, notify=stateChanged)
    def loading(self) -> bool:
        return False

    @Property(bool, notify=stateChanged)
    def panelOpen(self) -> bool:
        return self._panel_open

    @Property(str, notify=stateChanged)
    def panelMode(self) -> str:
        return "summary"

    @Property(int, notify=stateChanged)
    def eventCount(self) -> int:
        return len(self._unified_rows)

    @Property(int, notify=stateChanged)
    def tradeCount(self) -> int:
        return 0

    @Property(int, notify=stateChanged)
    def winCount(self) -> int:
        return 0

    @Property(int, notify=stateChanged)
    def lossCount(self) -> int:
        return 0

    @Property(float, notify=stateChanged)
    def totalPnl(self) -> float:
        return 0.0

    @Property(float, notify=stateChanged)
    def winRate(self) -> float:
        return 0.0

    @Property("QVariantList", notify=unifiedChanged)
    def unifiedRows(self) -> list[dict]:
        return self._unified_rows

    @Property("QVariantMap", notify=comparisonChanged)
    def summaryResult(self) -> dict:
        return self._summary_result

    @Property("QVariantMap", notify=comparisonChanged)
    def comparisonResult(self) -> dict:
        return self._comparison_result

    @Slot(str)
    def setQuickFilter(self, value: str) -> None:
        self._quick_filter = value
        self.stateChanged.emit()

    @Slot(str)
    def setSelectedSymbol(self, value: str) -> None:
        self.stateChanged.emit()

    @Slot(str)
    def setPanelMode(self, value: str) -> None:
        self.stateChanged.emit()

    @Slot(str)
    def openPanel(self, value: str) -> None:
        self._panel_open = True
        self.stateChanged.emit()

    @Slot()
    @Slot(str)
    def refresh(self, source: str = "") -> None:
        self._source = source
        self._unified_rows = []
        self._summary_result = {}
        self._comparison_result = {}
        self.unifiedChanged.emit()
        self.comparisonChanged.emit()
        self.stateChanged.emit()

    @Slot()
    def runAnalysis(self) -> None:
        self._summary_result = {}
        self.comparisonChanged.emit()

    @Slot()
    def openSummary(self) -> None:
        self._panel_open = True
        self.stateChanged.emit()

    @Slot()
    def closePanel(self) -> None:
        self._panel_open = False
        self.stateChanged.emit()
