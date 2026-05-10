from __future__ import annotations

import copy
import random

from PySide6.QtCore import (
    QAbstractListModel,
    QByteArray,
    QModelIndex,
    QObject,
    Property,
    Qt,
    Signal,
    Slot,
    QTimer,
)

# 反向规则：current 越高越安全，跌破 threshold 才是问题
_INVERTED_IDS = {"margin_ratio", "net_value_floor", "available_cash"}

_RULES: list[dict] = [
    # ── 持仓暴露 ────────────────────────────────────────────────────────────
    # 单票集中、行业集中、风格集中、规模上限、个股止损
    {"id": "single_weight",   "category": "持仓暴露", "name": "单票权重上限",    "enabled": True,  "threshold": 15.0,    "current": 12.0,  "unit": "%",   "status": "pass", "lastTriggered": "14:22:31", "step": 1.0},
    {"id": "sector_conc",     "category": "持仓暴露", "name": "单行业集中度",    "enabled": True,  "threshold": 35.0,    "current": 28.5,  "unit": "%",   "status": "pass", "lastTriggered": "11:45:08", "step": 5.0},
    {"id": "market_cap",      "category": "持仓暴露", "name": "小盘股权重上限",  "enabled": True,  "threshold": 40.0,    "current": 22.0,  "unit": "%",   "status": "pass", "lastTriggered": "",         "step": 5.0},
    {"id": "max_positions",   "category": "持仓暴露", "name": "最大持仓股数",    "enabled": True,  "threshold": 20.0,    "current": 4.0,   "unit": "只",  "status": "pass", "lastTriggered": "",         "step": 5.0},
    {"id": "stock_loss",      "category": "持仓暴露", "name": "单票浮亏止损",    "enabled": True,  "threshold": 8.0,     "current": 5.2,   "unit": "%",   "status": "pass", "lastTriggered": "",         "step": 1.0},
    # ── 回撤控制 ────────────────────────────────────────────────────────────
    # 不同时间维度的回撤上限 + 净值熔断 + 连续亏损熔断
    {"id": "daily_drawdown",  "category": "回撤控制", "name": "日内回撤止损",    "enabled": True,  "threshold": 3.0,     "current": 0.7,   "unit": "%",   "status": "pass", "lastTriggered": "",         "step": 0.5},
    {"id": "weekly_drawdown", "category": "回撤控制", "name": "周度回撤止损",    "enabled": True,  "threshold": 5.0,     "current": 1.2,   "unit": "%",   "status": "pass", "lastTriggered": "",         "step": 0.5},
    {"id": "total_drawdown",  "category": "回撤控制", "name": "总回撤止损",      "enabled": True,  "threshold": 8.0,     "current": 2.1,   "unit": "%",   "status": "pass", "lastTriggered": "",         "step": 1.0},
    # net_value_floor: current=当前净值百分比，跌破 threshold 则触发；warnBand=距离阈值多少%内预警
    {"id": "net_value_floor", "category": "回撤控制", "name": "净值下限熔断",    "enabled": True,  "threshold": 90.0,    "current": 97.8,  "unit": "%",   "status": "pass", "lastTriggered": "",         "step": 1.0,  "warnBand": 4.0},
    {"id": "consec_loss",     "category": "回撤控制", "name": "连续亏损止步",    "enabled": True,  "threshold": 3.0,     "current": 1.0,   "unit": "次",  "status": "pass", "lastTriggered": "",         "step": 1.0},
    # ── 委托控制 ────────────────────────────────────────────────────────────
    # 单笔限额、频率、换手率、冲击成本、重复委托
    {"id": "order_size",      "category": "委托控制", "name": "单笔委托金额上限","enabled": True,  "threshold": 100000.0,"current": 21560.0,"unit": "元", "status": "pass", "lastTriggered": "",         "step": 10000.0},
    {"id": "trade_freq",      "category": "委托控制", "name": "日内最大交易次数","enabled": True,  "threshold": 20.0,    "current": 7.0,   "unit": "次",  "status": "pass", "lastTriggered": "",         "step": 5.0},
    {"id": "daily_turnover",  "category": "委托控制", "name": "日内换手率上限",  "enabled": True,  "threshold": 50.0,    "current": 18.3,  "unit": "%",   "status": "pass", "lastTriggered": "",         "step": 5.0},
    {"id": "order_impact",    "category": "委托控制", "name": "单笔量/日均量",   "enabled": True,  "threshold": 5.0,     "current": 1.2,   "unit": "%",   "status": "pass", "lastTriggered": "",         "step": 1.0},
    {"id": "dup_order",       "category": "委托控制", "name": "重复委托检测",    "enabled": True,  "threshold": 0.0,     "current": 0.0,   "unit": "开关","status": "pass", "lastTriggered": "",         "step": 0.0},
    # ── 账户健康 ────────────────────────────────────────────────────────────
    # 保证金率、现金留存、杠杆率（inverted: 数值越高越安全）
    {"id": "margin_ratio",    "category": "账户健康", "name": "保证金率下限",    "enabled": True,  "threshold": 30.0,    "current": 62.9,  "unit": "%",   "status": "pass", "lastTriggered": "",         "step": 5.0,  "warnBand": 5.0},
    {"id": "available_cash",  "category": "账户健康", "name": "现金比例下限",    "enabled": True,  "threshold": 5.0,     "current": 12.3,  "unit": "%",   "status": "pass", "lastTriggered": "",         "step": 1.0,  "warnBand": 3.0},
    {"id": "leverage_ratio",  "category": "账户健康", "name": "杠杆率上限",      "enabled": False, "threshold": 1.5,     "current": 1.1,   "unit": "x",   "status": "pass", "lastTriggered": "",         "step": 0.1},
    # ── 策略联动 ────────────────────────────────────────────────────────────
    # 单一策略子限额，防止全仓压注一个策略
    {"id": "strategy_dd",     "category": "策略联动", "name": "单策略最大回撤",  "enabled": True,  "threshold": 5.0,     "current": 1.8,   "unit": "%",   "status": "pass", "lastTriggered": "",         "step": 0.5},
    {"id": "strategy_weight", "category": "策略联动", "name": "单策略持仓上限",  "enabled": True,  "threshold": 60.0,    "current": 45.0,  "unit": "%",   "status": "pass", "lastTriggered": "",         "step": 5.0},
]

_EXPOSURES: list[dict] = [
    {"symbol": "600036", "name": "招商银行", "sector": "金融", "weight": 12.0, "limit": 15.0, "side": "多"},
    {"symbol": "000858", "name": "五粮液",   "sector": "消费", "weight": 8.5,  "limit": 15.0, "side": "多"},
    {"symbol": "600519", "name": "贵州茅台", "sector": "消费", "weight": 9.2,  "limit": 15.0, "side": "多"},
    {"symbol": "002475", "name": "立讯精密", "sector": "科技", "weight": 7.4,  "limit": 15.0, "side": "空"},
]

_SECTORS: list[dict] = [
    {"sector": "消费", "weight": 17.7, "limit": 35.0},
    {"sector": "金融", "weight": 12.0, "limit": 35.0},
    {"sector": "科技", "weight":  7.4, "limit": 35.0},
]

_CHECK_LOG: list[dict] = [
    {"time": "14:35:02", "symbol": "600036", "name": "招商银行", "side": "买入", "qty": 800,  "price": 43.20,  "passed": True,  "ruleName": "",          "checkVal": "",      "limit": ""},
    {"time": "14:22:31", "symbol": "002475", "name": "立讯精密", "side": "买入", "qty": 5000, "price": 27.80,  "passed": False, "ruleName": "单票权重上限","checkVal": "14.8%","limit": "15.0%"},
    {"time": "14:08:15", "symbol": "000858", "name": "五粮液",   "side": "买入", "qty": 300,  "price": 171.20, "passed": True,  "ruleName": "",          "checkVal": "",      "limit": ""},
    {"time": "11:45:08", "symbol": "000858", "name": "五粮液",   "side": "买入", "qty": 2000, "price": 171.50, "passed": False, "ruleName": "单行业集中度","checkVal": "34.2%","limit": "35.0%"},
    {"time": "10:12:33", "symbol": "600519", "name": "贵州茅台", "side": "买入", "qty": 50,   "price": 1690.0, "passed": True,  "ruleName": "",          "checkVal": "",      "limit": ""},
    {"time": "09:45:20", "symbol": "002475", "name": "立讯精密", "side": "卖出", "qty": 1000, "price": 28.50,  "passed": True,  "ruleName": "",          "checkVal": "",      "limit": ""},
]

_LOGS: list[dict] = [
    {"time": "14:35:02", "level": "PASS", "message": "600036 买入 800股 → 全部规则通过"},
    {"time": "14:22:31", "level": "RISK", "message": "单票权重 002475 触及 14.8% → 委托被拒"},
    {"time": "14:22:30", "level": "WARN", "message": "002475 委托将使权重升至 14.8%，接近上限 15.0%"},
    {"time": "14:08:15", "level": "PASS", "message": "000858 买入 300股 → 全部规则通过"},
    {"time": "11:45:08", "level": "RISK", "message": "消费板块集中度 34.2% 超限 → 委托被拒"},
    {"time": "10:12:33", "level": "PASS", "message": "600519 买入 50股 → 全部规则通过"},
    {"time": "09:45:20", "level": "PASS", "message": "002475 卖出 1000股 → 全部规则通过"},
    {"time": "09:30:05", "level": "INFO", "message": "风控规则加载完成，20 条规则已配置"},
    {"time": "09:30:03", "level": "INFO", "message": "风控引擎初始化成功"},
]


class DictListModel(QAbstractListModel):
    """Stable QML model for dict rows updated in-place via dataChanged."""

    _USER_ROLE = Qt.ItemDataRole.UserRole.value
    _MODEL_DATA_ROLE = _USER_ROLE + 1

    def __init__(self, rows: list[dict], parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._rows = rows
        keys: list[str] = []
        for row in rows:
            for key in row:
                if key not in keys:
                    keys.append(key)
        self._roles = {"modelData": self._MODEL_DATA_ROLE}
        for offset, key in enumerate(keys, start=2):
            self._roles[key] = self._USER_ROLE + offset
        self._role_names = {role: QByteArray(name.encode("utf-8")) for name, role in self._roles.items()}

    def rowCount(self, parent: QModelIndex = QModelIndex()) -> int:
        if parent.isValid():
            return 0
        return len(self._rows)

    def data(self, index: QModelIndex, role: int = Qt.ItemDataRole.DisplayRole):
        if not index.isValid() or index.row() < 0 or index.row() >= len(self._rows):
            return None
        row = self._rows[index.row()]
        if role == self._MODEL_DATA_ROLE:
            return dict(row)
        for name, role_id in self._roles.items():
            if role == role_id:
                return row.get(name)
        return None

    def roleNames(self) -> dict[int, QByteArray]:
        return self._role_names

    def refresh_all(self) -> None:
        if not self._rows:
            return
        top_left = self.index(0, 0)
        bottom_right = self.index(len(self._rows) - 1, 0)
        self.dataChanged.emit(top_left, bottom_right, list(self._role_names.keys()))

    def set_rows(self, rows: list[dict]) -> None:
        self.beginResetModel()
        self._rows = rows
        self.endResetModel()


class RiskController(QObject):
    stateChanged = Signal()

    def __init__(self) -> None:
        super().__init__()
        self._rules      = copy.deepcopy(_RULES)
        self._exposures  = copy.deepcopy(_EXPOSURES)
        self._sectors    = copy.deepcopy(_SECTORS)
        self._check_log  = copy.deepcopy(_CHECK_LOG)
        self._logs       = copy.deepcopy(_LOGS)
        self._rules_model = DictListModel(self._rules, self)
        self._exposures_model = DictListModel(self._exposures, self)
        self._sectors_model = DictListModel(self._sectors, self)
        self._check_log_model = DictListModel(self._check_log, self)
        self._logs_model = DictListModel(self._logs, self)
        self._check_latency_ms = 0.8
        self._refresh_statuses()

        self._tick = QTimer()
        self._tick.setInterval(3000)
        self._tick.timeout.connect(self._on_tick)
        self._tick.start()

    # ── internals ─────────────────────────────────────────────────────────────

    def _rule_status(self, r: dict) -> str:
        if not r["enabled"]:
            return "disabled"
        cur, thr = r["current"], r["threshold"]

        # 反向规则：current 必须高于 threshold 才安全
        if r["id"] in _INVERTED_IDS:
            if cur <= thr:                            return "fail"
            if cur <= thr + r.get("warnBand", 5.0):  return "warn"
            return "pass"

        # 布尔规则
        if r["id"] == "dup_order":
            return "fail" if cur > 0 else "pass"

        # 普通规则：current 越接近 threshold 越危险
        ratio = cur / thr if thr else 0.0
        if ratio >= 1.0:  return "fail"
        if ratio >= 0.85: return "warn"
        return "pass"

    def _refresh_statuses(self) -> None:
        for r in self._rules:
            r["status"] = self._rule_status(r)

    def _on_tick(self) -> None:
        # 持仓权重微扰
        for e in self._exposures:
            e["weight"] = round(
                max(0.5, min(e["limit"] * 0.97, e["weight"] + random.uniform(-0.12, 0.12))), 1
            )
        for s in self._sectors:
            s["weight"] = round(
                sum(e["weight"] for e in self._exposures if e["sector"] == s["sector"]), 1
            )

        # 各规则当前值更新
        for r in self._rules:
            rid = r["id"]
            if   rid == "single_weight":   r["current"] = round(max(e["weight"] for e in self._exposures), 1)
            elif rid == "sector_conc":     r["current"] = round(max(s["weight"] for s in self._sectors), 1)
            elif rid == "market_cap":      r["current"] = round(max(0.0, min(50.0, r["current"] + random.uniform(-0.2, 0.2))), 1)
            elif rid == "stock_loss":      r["current"] = round(max(0.0, min(r["threshold"] * 0.98, r["current"] + random.uniform(-0.1, 0.12))), 1)
            elif rid == "daily_drawdown":  r["current"] = round(max(0.0, r["current"] + random.uniform(-0.03, 0.04)), 2)
            elif rid == "weekly_drawdown": r["current"] = round(max(0.0, r["current"] + random.uniform(-0.02, 0.02)), 2)
            elif rid == "total_drawdown":  r["current"] = round(max(0.0, r["current"] + random.uniform(-0.01, 0.02)), 2)
            elif rid == "net_value_floor": r["current"] = round(max(88.0, min(100.0, r["current"] + random.uniform(-0.04, 0.04))), 1)
            elif rid == "consec_loss":     pass  # 连续亏损数量只在真实成交时变化
            elif rid == "daily_turnover":  r["current"] = round(max(0.0, min(60.0, r["current"] + random.uniform(-0.3, 0.5))), 1)
            elif rid == "order_impact":    r["current"] = round(max(0.0, min(6.0, r["current"] + random.uniform(-0.05, 0.10))), 1)
            elif rid == "margin_ratio":    r["current"] = round(max(25.0, r["current"] + random.uniform(-0.2, 0.2)), 1)
            elif rid == "available_cash":  r["current"] = round(max(3.0, min(20.0, r["current"] + random.uniform(-0.1, 0.1))), 1)
            elif rid == "leverage_ratio":  r["current"] = round(max(1.0, min(2.0, r["current"] + random.uniform(-0.01, 0.01))), 2)
            elif rid == "strategy_dd":     r["current"] = round(max(0.0, min(r["threshold"], r["current"] + random.uniform(-0.05, 0.06))), 1)
            elif rid == "strategy_weight": r["current"] = round(max(20.0, min(70.0, r["current"] + random.uniform(-0.3, 0.3))), 1)

        self._check_latency_ms = round(random.uniform(0.5, 1.4), 1)
        self._refresh_statuses()
        self._rules_model.refresh_all()
        self._exposures_model.refresh_all()
        self._sectors_model.refresh_all()
        self.stateChanged.emit()

    # ── properties ────────────────────────────────────────────────────────────

    @Property(str, notify=stateChanged)
    def globalStatus(self) -> str:
        if any(r["status"] == "fail" for r in self._rules):
            return "LOCKED"
        if any(r["status"] == "warn" for r in self._rules):
            return "WARN"
        return "PASS"

    @Property(int, notify=stateChanged)
    def rejectionCount(self) -> int:
        return sum(1 for c in self._check_log if not c["passed"])

    @Property(int, notify=stateChanged)
    def passCount(self) -> int:
        return sum(1 for c in self._check_log if c["passed"])

    @Property(float, notify=stateChanged)
    def checkLatencyMs(self) -> float:
        return self._check_latency_ms

    @Property(int, notify=stateChanged)
    def enabledRuleCount(self) -> int:
        return sum(1 for r in self._rules if r["enabled"])

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
        return round(sum(e["weight"] for e in self._exposures if e["side"] == "多"), 1)

    @Property(float, notify=stateChanged)
    def netShortWeight(self) -> float:
        return round(sum(e["weight"] for e in self._exposures if e["side"] == "空"), 1)

    @Property(QObject, constant=True)
    def rules(self) -> DictListModel:
        return self._rules_model

    @Property(QObject, constant=True)
    def exposures(self) -> DictListModel:
        return self._exposures_model

    @Property(QObject, constant=True)
    def sectors(self) -> DictListModel:
        return self._sectors_model

    @Property(QObject, constant=True)
    def checkLog(self) -> DictListModel:
        return self._check_log_model

    @Property(QObject, constant=True)
    def logs(self) -> DictListModel:
        return self._logs_model

    # ── slots ─────────────────────────────────────────────────────────────────

    @Slot(str)
    def toggleRule(self, rule_id: str) -> None:
        for r in self._rules:
            if r["id"] == rule_id:
                r["enabled"] = not r["enabled"]
                break
        self._refresh_statuses()
        self._rules_model.refresh_all()
        self.stateChanged.emit()

    @Slot(str, float)
    def adjustThreshold(self, rule_id: str, delta: float) -> None:
        for r in self._rules:
            if r["id"] == rule_id and r.get("step", 0) > 0:
                r["threshold"] = round(max(r["step"], r["threshold"] + delta), 1)
                break
        self._refresh_statuses()
        self._rules_model.refresh_all()
        self.stateChanged.emit()

    @Slot()
    def clearLogs(self) -> None:
        self._logs = []
        self._logs_model.set_rows(self._logs)
        self.stateChanged.emit()

    @Slot()
    def clearCheckLog(self) -> None:
        self._check_log = []
        self._check_log_model.set_rows(self._check_log)
        self.stateChanged.emit()
