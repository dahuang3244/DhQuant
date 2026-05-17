from __future__ import annotations

from PySide6.QtCore import QObject, Property, Signal, Slot


BUILTIN_STRATEGIES: list[str] = []


class StrategyController(QObject):
    stateChanged = Signal()
    strategiesChanged = Signal()

    def __init__(self) -> None:
        super().__init__()
        self._active_tab = "data"
        self._data_sources: list[dict] = []
        self._custom_data_fields: list[str] = []
        self._factors: list[dict] = []
        self._factor_category = "全部"
        self._selected_factors: list[str] = []
        self._mined_factors: list[dict] = []
        self._ml_models: list[dict] = []
        self._selected_ml_model = ""
        self._mining_method = "AI 生成"
        self._strategy_name = ""
        self._strategy_type = "趋势跟踪"
        self._ai_loading = False
        self._ai_analysis = ""
        self._current_code = ""
        self._current_strategy = ""
        self._all_strategies: list[str] = []

    @Property(str, notify=stateChanged)
    def activeTab(self) -> str:
        return self._active_tab

    @Property("QVariantList", notify=stateChanged)
    def dataSources(self) -> list[dict]:
        return self._data_sources

    @Property("QVariantList", notify=stateChanged)
    def customDataFields(self) -> list[str]:
        return self._custom_data_fields

    @Property("QVariantList", notify=stateChanged)
    def factors(self) -> list[dict]:
        return self._factors

    @Property(str, notify=stateChanged)
    def factorCategory(self) -> str:
        return self._factor_category

    @Property("QVariantList", notify=stateChanged)
    def selectedFactors(self) -> list[str]:
        return self._selected_factors

    @Property("QVariantList", notify=stateChanged)
    def minedFactors(self) -> list[dict]:
        return self._mined_factors

    @Property("QVariantList", notify=stateChanged)
    def mlModels(self) -> list[dict]:
        return self._ml_models

    @Property(str, notify=stateChanged)
    def selectedMlModel(self) -> str:
        return self._selected_ml_model

    @Property(str, notify=stateChanged)
    def miningMethod(self) -> str:
        return self._mining_method

    @Property(str, notify=stateChanged)
    def strategyName(self) -> str:
        return self._strategy_name

    @Property(str, notify=stateChanged)
    def strategyType(self) -> str:
        return self._strategy_type

    @Property(bool, notify=stateChanged)
    def aiLoading(self) -> bool:
        return self._ai_loading

    @Property(str, notify=stateChanged)
    def aiAnalysis(self) -> str:
        return self._ai_analysis

    @Property(str, notify=stateChanged)
    def currentCode(self) -> str:
        return self._current_code

    @Property(str, notify=strategiesChanged)
    def currentStrategy(self) -> str:
        return self._current_strategy

    @Property("QVariantList", notify=strategiesChanged)
    def allStrategies(self) -> list[str]:
        return self._all_strategies

    @Slot(str)
    def setTab(self, tab: str) -> None:
        self._active_tab = tab
        self.stateChanged.emit()

    @Slot(str)
    def setFactorCategory(self, category: str) -> None:
        self._factor_category = category
        self.stateChanged.emit()

    @Slot(str)
    def addDataField(self, name: str) -> None:
        value = name.strip()
        if value and value not in self._custom_data_fields:
            self._custom_data_fields.append(value)
            self.stateChanged.emit()

    @Slot(str)
    def toggleFactor(self, name: str) -> None:
        if name in self._selected_factors:
            self._selected_factors.remove(name)
        elif name:
            self._selected_factors.append(name)
        self.stateChanged.emit()

    @Slot()
    def clearSelectedFactors(self) -> None:
        self._selected_factors = []
        self.stateChanged.emit()

    @Slot(str)
    def setMiningMethod(self, value: str) -> None:
        self._mining_method = value
        self.stateChanged.emit()

    @Slot(str)
    def setMlModel(self, value: str) -> None:
        self._selected_ml_model = value
        self.stateChanged.emit()

    @Slot(str)
    def setStrategyName(self, value: str) -> None:
        self._strategy_name = value.strip()
        self.stateChanged.emit()

    @Slot(str)
    def setStrategyType(self, value: str) -> None:
        self._strategy_type = value
        self.stateChanged.emit()

    @Slot(str)
    def setCurrentCode(self, value: str) -> None:
        self._current_code = value
        self.stateChanged.emit()

    @Slot(str, str)
    def addCustomFactor(self, name: str, category: str) -> None:
        clean_name = name.strip()
        if clean_name and not any(row.get("name") == clean_name for row in self._factors):
            self._factors.append({"name": clean_name, "category": category, "desc": "", "ic": 0, "ir": 0})
            self.stateChanged.emit()

    @Slot()
    def newStrategy(self) -> None:
        self._current_strategy = ""
        self._strategy_name = ""
        self._current_code = ""
        self.strategiesChanged.emit()
        self.stateChanged.emit()

    @Slot(str)
    def selectStrategy(self, name: str) -> None:
        if name not in self._all_strategies:
            return
        self._current_strategy = name
        self._strategy_name = name
        self.strategiesChanged.emit()
        self.stateChanged.emit()

    @Slot()
    def saveStrategy(self) -> None:
        name = self._strategy_name.strip()
        if not name:
            return
        if name not in self._all_strategies:
            self._all_strategies.append(name)
        self._current_strategy = name
        self.strategiesChanged.emit()
        self.stateChanged.emit()

    @Slot()
    def aiWriteStrategy(self) -> None:
        self._ai_loading = False
        self._ai_analysis = ""
        self.stateChanged.emit()

    @Slot()
    def aiAnalyzeStrategy(self) -> None:
        self._ai_loading = False
        self._ai_analysis = ""
        self.stateChanged.emit()
