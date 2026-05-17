from __future__ import annotations

from PySide6.QtCore import QObject, Property, Signal, Slot


class RiskController(QObject):
    stateChanged = Signal()

    def __init__(self) -> None:
        super().__init__()
        self._rules: list[dict] = []
        self._exposures: list[dict] = []
        self._sectors: list[dict] = []
        self._check_log: list[dict] = []
        self._logs: list[dict] = []

    @Property(str, notify=stateChanged)
    def globalStatus(self) -> str:
        return "IDLE"

    @Property(int, notify=stateChanged)
    def passCount(self) -> int:
        return 0

    @Property(int, notify=stateChanged)
    def rejectionCount(self) -> int:
        return 0

    @Property(float, notify=stateChanged)
    def checkLatencyMs(self) -> float:
        return 0.0

    @Property(int, notify=stateChanged)
    def enabledRuleCount(self) -> int:
        return 0

    @Property(int, notify=stateChanged)
    def rulesCount(self) -> int:
        return len(self._rules)

    @Property(int, notify=stateChanged)
    def checkLogCount(self) -> int:
        return len(self._check_log)

    @Property(int, notify=stateChanged)
    def logsCount(self) -> int:
        return len(self._logs)

    @Property(float, notify=stateChanged)
    def netLongWeight(self) -> float:
        return 0.0

    @Property(float, notify=stateChanged)
    def netShortWeight(self) -> float:
        return 0.0

    @Property("QVariantList", notify=stateChanged)
    def rules(self) -> list[dict]:
        return self._rules

    @Property("QVariantList", notify=stateChanged)
    def exposures(self) -> list[dict]:
        return self._exposures

    @Property("QVariantList", notify=stateChanged)
    def sectors(self) -> list[dict]:
        return self._sectors

    @Property("QVariantList", notify=stateChanged)
    def checkLog(self) -> list[dict]:
        return self._check_log

    @Property("QVariantList", notify=stateChanged)
    def logs(self) -> list[dict]:
        return self._logs

    @Slot(str)
    def toggleRule(self, rule_id: str) -> None:
        self.stateChanged.emit()

    @Slot(str, float)
    def adjustThreshold(self, rule_id: str, delta: float) -> None:
        self.stateChanged.emit()

    @Slot()
    def clearCheckLog(self) -> None:
        self._check_log = []
        self.stateChanged.emit()

    @Slot()
    def clearLogs(self) -> None:
        self._logs = []
        self.stateChanged.emit()
