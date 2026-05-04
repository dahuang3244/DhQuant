from __future__ import annotations

from PySide6.QtCore import QObject, Property, Signal, Slot

from core.enums import Page, RuntimeState


class DashboardController(QObject):
    pageChanged = Signal()
    runtimeChanged = Signal()
    toastChanged = Signal()

    def __init__(self) -> None:
        super().__init__()
        self._page = Page.WATCHLIST.value
        self._runtime = RuntimeState.STOPPED.value
        self._run_id = "paper-20260503-001"
        self._connection = "mock"
        self._toast_title = ""
        self._toast_message = ""
        self._toast_visible = False

    @Property(str, notify=pageChanged)
    def page(self) -> str:
        return self._page

    @Property(str, notify=runtimeChanged)
    def runtime(self) -> str:
        return self._runtime

    @Property(str, notify=runtimeChanged)
    def runId(self) -> str:
        return self._run_id

    @Property(str, notify=runtimeChanged)
    def connection(self) -> str:
        return self._connection

    @Property(bool, notify=toastChanged)
    def toastVisible(self) -> bool:
        return self._toast_visible

    @Property(str, notify=toastChanged)
    def toastTitle(self) -> str:
        return self._toast_title

    @Property(str, notify=toastChanged)
    def toastMessage(self) -> str:
        return self._toast_message

    @Slot(str)
    def setPage(self, page: str) -> None:
        if page == self._page:
            return
        self._page = page
        self.pageChanged.emit()

    @Slot()
    def startRuntime(self) -> None:
        if self._runtime == RuntimeState.RUNNING.value:
            return
        self._runtime = RuntimeState.RUNNING.value
        self.runtimeChanged.emit()
        self.showToast("Runtime Started", "Mock runtime is now running")

    @Slot()
    def stopRuntime(self) -> None:
        if self._runtime == RuntimeState.STOPPED.value:
            return
        self._runtime = RuntimeState.STOPPED.value
        self.runtimeChanged.emit()
        self.showToast("Runtime Stopped", "Mock runtime has been stopped")

    @Slot(str, str)
    def showToast(self, title: str, message: str) -> None:
        self._toast_title = title
        self._toast_message = message
        self._toast_visible = True
        self.toastChanged.emit()

    @Slot()
    def dismissToast(self) -> None:
        self._toast_visible = False
        self.toastChanged.emit()
