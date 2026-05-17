from __future__ import annotations

from PySide6.QtCore import QObject, Property, Signal, Slot


class NewsController(QObject):
    stateChanged = Signal()
    newsListChanged = Signal()
    selectedChanged = Signal()

    def __init__(self) -> None:
        super().__init__()
        self._industry = "全部"
        self._loading = False
        self._selected_id = ""
        self._last_refresh = ""
        self._news_list: list[dict] = []
        self._industries = ["全部"]

    @Property(str, notify=stateChanged)
    def industry(self) -> str:
        return self._industry

    @Property(bool, notify=stateChanged)
    def loading(self) -> bool:
        return self._loading

    @Property(str, notify=selectedChanged)
    def selectedId(self) -> str:
        return self._selected_id

    @Property(str, notify=stateChanged)
    def lastRefresh(self) -> str:
        return self._last_refresh

    @Property("QVariantList", notify=newsListChanged)
    def newsList(self) -> list[dict]:
        return self._news_list

    @Property("QVariantMap", notify=selectedChanged)
    def selectedNews(self) -> dict:
        for item in self._news_list:
            if item.get("id") == self._selected_id:
                return item
        return {}

    @Property("QVariantList", notify=stateChanged)
    def industries(self) -> list[str]:
        return self._industries

    @Slot(str)
    def setIndustry(self, industry: str) -> None:
        self._industry = industry
        self.stateChanged.emit()

    @Slot(str)
    def selectNews(self, news_id: str) -> None:
        self._selected_id = news_id if any(item.get("id") == news_id for item in self._news_list) else ""
        self.selectedChanged.emit()

    @Slot()
    def refresh(self) -> None:
        self._loading = False
        self._news_list = []
        self._selected_id = ""
        self.newsListChanged.emit()
        self.selectedChanged.emit()
        self.stateChanged.emit()
