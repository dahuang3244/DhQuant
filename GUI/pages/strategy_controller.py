from __future__ import annotations

from PySide6.QtCore import QObject, Property, Signal, Slot, QTimer

_TABS = ["data", "factor", "mining", "analysis", "ml", "code"]

BUILTIN_STRATEGIES: list[str] = [
    "超买回落-做空策略",
    "止跌反弹-做多策略",
    "打出太马-做空策略",
    "超买占压-做多策略",
    "MACD金叉-做多策略",
    "均线突破-双向策略",
    "布林带反转-做多策略",
    "RSI超卖回升-做多策略",
    "成交量突破-做多策略",
    "KDJ死叉-做空策略",
    "双均线交叉-做多策略",
]

_DATA_SOURCES: list[dict] = [
    {"name": "TuShare A股",   "type": "astock", "status": "已配置", "note": "日K · 分钟K · 财务报表"},
    {"name": "Binance 加密",  "type": "crypto",  "status": "未配置", "note": "现货 · 合约 · 深度数据"},
    {"name": "Yahoo Finance", "type": "us",      "status": "未配置", "note": "美股 · ETF · 指数"},
    {"name": "Wind 债券",     "type": "bond",    "status": "未配置", "note": "收益率 · 信用评级"},
]

_MOCK_FACTORS: list[dict] = [
    {"name": "MA5",        "category": "趋势",  "ic": 0.032, "sharpe": 1.23, "win_rate": 53.2, "status": "优质"},
    {"name": "MA20",       "category": "趋势",  "ic": 0.028, "sharpe": 1.05, "win_rate": 51.8, "status": "优质"},
    {"name": "RSI14",      "category": "震荡",  "ic": 0.041, "sharpe": 1.67, "win_rate": 55.1, "status": "优质"},
    {"name": "MACD_HIST",  "category": "趋势",  "ic": 0.029, "sharpe": 1.12, "win_rate": 52.4, "status": "优质"},
    {"name": "BOLL_WIDTH", "category": "波动",  "ic": 0.019, "sharpe": 0.87, "win_rate": 49.3, "status": "一般"},
    {"name": "VOL_RATIO",  "category": "量价",  "ic": 0.038, "sharpe": 1.45, "win_rate": 54.0, "status": "优质"},
    {"name": "PE_TTM",     "category": "基本面", "ic": 0.022, "sharpe": 0.94, "win_rate": 50.6, "status": "一般"},
    {"name": "ROE",        "category": "基本面", "ic": 0.035, "sharpe": 1.38, "win_rate": 53.7, "status": "优质"},
    {"name": "MOM_10D",    "category": "动量",  "ic": 0.033, "sharpe": 1.28, "win_rate": 52.9, "status": "优质"},
    {"name": "REVERSAL",   "category": "反转",  "ic": 0.026, "sharpe": 0.99, "win_rate": 51.1, "status": "一般"},
    {"name": "ALPHA_001",  "category": "挖掘",  "ic": 0.051, "sharpe": 1.89, "win_rate": 56.3, "status": "优质"},
    {"name": "ALPHA_002",  "category": "挖掘",  "ic": 0.044, "sharpe": 1.72, "win_rate": 55.8, "status": "优质"},
]

_MINED_FACTORS: list[dict] = [
    {"formula": "rank(ts_corr(close, volume, 5)) - rank(ts_std(close, 10))", "ic": 0.048, "status": "优质", "source": "遗传算法"},
    {"formula": "where(rsi_14 < 30, -ts_rank(volume, 5), ts_rank(close, 5))", "ic": 0.051, "status": "优质", "source": "AI 生成"},
    {"formula": "(ema_12 - ema_26) / ts_std(close, 20)",                      "ic": 0.044, "status": "优质", "source": "AI 生成"},
    {"formula": "corr(rank(high - low), rank(volume), 10)",                    "ic": 0.038, "status": "一般", "source": "遗传算法"},
    {"formula": "ts_rank(close / delay(close, 5), 20) - 0.5",                 "ic": 0.029, "status": "一般", "source": "遗传算法"},
]

_ML_MODELS: list[dict] = [
    {"name": "LightGBM",    "type": "GBDT",   "accuracy": 0.573, "sharpe": 1.82, "status": "已训练", "features": 8},
    {"name": "XGBoost",     "type": "GBDT",   "accuracy": 0.561, "sharpe": 1.74, "status": "已训练", "features": 8},
    {"name": "LSTM",        "type": "深度学习", "accuracy": 0.548, "sharpe": 1.61, "status": "未训练", "features": 0},
    {"name": "Transformer", "type": "深度学习", "accuracy": 0.0,   "sharpe": 0.0,  "status": "未训练", "features": 0},
]

_STRATEGY_CODES: dict[str, str] = {
    "MACD金叉-做多策略": '''\
def initialize(context):
    context.symbol        = "AAPL"
    context.fast_period   = 12
    context.slow_period   = 26
    context.signal_period = 9
    context.position      = 0

def handle_data(context, data):
    prices = data.history(context.symbol, 'close', 35, '1d')

    # 计算 MACD
    ema_fast = prices.ewm(span=context.fast_period, adjust=False).mean()
    ema_slow = prices.ewm(span=context.slow_period, adjust=False).mean()
    dif = ema_fast - ema_slow
    dea = dif.ewm(span=context.signal_period, adjust=False).mean()

    golden = dif.iloc[-2] < dea.iloc[-2] and dif.iloc[-1] > dea.iloc[-1]
    dead   = dif.iloc[-2] > dea.iloc[-2] and dif.iloc[-1] < dea.iloc[-1]

    if golden and context.position == 0:
        order_target_percent(context.symbol, 0.95)
        context.position = 1
        log.info(f"开多 @ {data.current(context.symbol, 'close'):.2f}")

    elif dead and context.position == 1:
        order_target_percent(context.symbol, 0)
        context.position = 0
        log.info("平多仓")
''',
    "RSI超卖回升-做多策略": '''\
def initialize(context):
    context.symbol     = "AAPL"
    context.rsi_period = 14
    context.oversold   = 30   # RSI 低于此值视为超卖
    context.overbought = 70   # RSI 高于此值视为超买
    context.position   = 0

def handle_data(context, data):
    prices = data.history(context.symbol, 'close', 20, '1d')

    delta = prices.diff()
    gain  = delta.clip(lower=0).rolling(context.rsi_period).mean()
    loss  = (-delta.clip(upper=0)).rolling(context.rsi_period).mean()
    rsi   = 100 - 100 / (1 + gain / loss)

    cur_rsi  = rsi.iloc[-1]
    prev_rsi = rsi.iloc[-2]

    # 从超卖区回升 → 做多
    if prev_rsi < context.oversold and cur_rsi >= context.oversold and context.position == 0:
        order_target_percent(context.symbol, 0.9)
        context.position = 1
        log.info(f"RSI 回升开多: RSI={cur_rsi:.1f}")

    # 进入超买区 → 止盈平仓
    elif cur_rsi >= context.overbought and context.position == 1:
        order_target_percent(context.symbol, 0)
        context.position = 0
        log.info(f"RSI 超买平多: RSI={cur_rsi:.1f}")
''',
    "均线突破-双向策略": '''\
def initialize(context):
    context.symbol        = "AAPL"
    context.fast_window   = 5
    context.slow_window   = 20
    context.position_side = 0   # 1=多, -1=空, 0=空仓

def handle_data(context, data):
    prices = data.history(context.symbol, 'close', context.slow_window + 2, '1d')

    ma_fast = prices.rolling(context.fast_window).mean()
    ma_slow = prices.rolling(context.slow_window).mean()

    s_prev, s_cur = ma_fast.iloc[-2], ma_fast.iloc[-1]
    l_prev, l_cur = ma_slow.iloc[-2], ma_slow.iloc[-1]

    # 短线上穿长线 → 做多
    if s_prev < l_prev and s_cur >= l_cur:
        order_target_percent(context.symbol, 0.9)
        context.position_side = 1
        log.info("均线金叉 → 做多")

    # 短线下穿长线 → 做空
    elif s_prev > l_prev and s_cur <= l_cur:
        order_target_percent(context.symbol, -0.5)
        context.position_side = -1
        log.info("均线死叉 → 做空")
''',
    "布林带反转-做多策略": '''\
def initialize(context):
    context.symbol   = "AAPL"
    context.window   = 20
    context.std_dev  = 2.0
    context.position = 0

def handle_data(context, data):
    prices = data.history(context.symbol, 'close', context.window + 2, '1d')

    mid   = prices.rolling(context.window).mean()
    std   = prices.rolling(context.window).std()
    upper = mid + context.std_dev * std
    lower = mid - context.std_dev * std

    cur_price = prices.iloc[-1]

    # 触碰下轨 → 均值回归做多
    if cur_price <= lower.iloc[-1] and context.position == 0:
        order_target_percent(context.symbol, 0.85)
        context.position = 1
        log.info(f"布林下轨开多 @ {cur_price:.2f}")

    # 回归中轨 → 平仓
    elif cur_price >= mid.iloc[-1] and context.position == 1:
        order_target_percent(context.symbol, 0)
        context.position = 0
        log.info(f"回归中轨平仓 @ {cur_price:.2f}")
''',
    "新建策略": '''\
def initialize(context):
    """初始化策略参数"""
    context.symbol   = "AAPL"
    context.position = 0
    # TODO: 在此添加你的参数

def handle_data(context, data):
    """每根 K 线调用一次"""
    prices = data.history(context.symbol, 'close', 30, '1d')

    # TODO: 计算你的交易信号
    signal = None   # "买入" 或 "卖出"

    if signal == "买入" and context.position == 0:
        order_target_percent(context.symbol, 0.9)
        context.position = 1

    elif signal == "卖出" and context.position == 1:
        order_target_percent(context.symbol, 0)
        context.position = 0
''',
}

_AI_WRITE_TEMPLATE = '''\
# AI 生成策略 — 基于因子: {factors}
# 生成时间: 2026-05-08   模型: Claude Sonnet 4.6

def initialize(context):
    context.symbol             = "AAPL"
    context.rsi_oversold       = 35    # RSI 超卖阈值
    context.rsi_overbought     = 65    # RSI 超买阈值
    context.macd_confirm       = True  # 是否需要 MACD 柱线确认
    context.position           = 0

def handle_data(context, data):
    prices = data.history(context.symbol, 'close', 35, '1d')

    # ── 因子计算 ─────────────────────────────────────────────
    # RSI-14
    delta = prices.diff()
    gain  = delta.clip(lower=0).rolling(14).mean()
    loss  = (-delta.clip(upper=0)).rolling(14).mean()
    rsi   = 100 - 100 / (1 + gain / loss)

    # MACD 柱线
    ema12  = prices.ewm(span=12, adjust=False).mean()
    ema26  = prices.ewm(span=26, adjust=False).mean()
    dif    = ema12 - ema26
    dea    = dif.ewm(span=9, adjust=False).mean()
    hist   = dif - dea

    cur_rsi   = rsi.iloc[-1]
    cur_hist  = hist.iloc[-1]
    prev_hist = hist.iloc[-2]

    # ── 信号生成 ─────────────────────────────────────────────
    # 多头: RSI 超卖 + MACD 柱线由负转正
    long_signal = (
        cur_rsi < context.rsi_oversold
        and prev_hist < 0 and cur_hist >= 0
    )
    # 空头: RSI 超买 + MACD 柱线由正转负
    exit_signal = (
        cur_rsi > context.rsi_overbought
        and prev_hist > 0 and cur_hist <= 0
    )

    if long_signal and context.position == 0:
        order_target_percent(context.symbol, 0.9)
        context.position = 1
        log.info(f"AI 开多 | RSI={cur_rsi:.1f} MACD翻正")

    elif exit_signal and context.position == 1:
        order_target_percent(context.symbol, 0)
        context.position = 0
        log.info(f"AI 平多 | RSI={cur_rsi:.1f} MACD翻负")
'''

_AI_ANALYZE_APPEND = '''

# ── AI 分析报告 ──────────────────────────────────────────────
# 优点:
#   ✓ 使用多因子组合信号, 有效减少误触发
#   ✓ 动量因子(MACD)与超卖因子(RSI)互补
#   ✓ 逻辑清晰, 易于扩展和调参
#
# 风险提示:
#   ⚠ 震荡行情中 MACD 滞后性明显, 建议加过滤
#   ⚠ 仓位 0.9 较激进, 建议调至 0.6~0.75
#   ⚠ 缺少止损逻辑 — 极端行情下回撤可能扩大
#
# 改进建议:
#   1. 加入 ATR 动态止损: stop = entry - 2 * atr
#   2. 用成交量突破确认信号: volume > volume_ma * 1.5
#   3. Bollinger Band 中轨过滤: 仅在价格 > 中轨时做多
# ────────────────────────────────────────────────────────────
'''


class StrategyController(QObject):
    stateChanged     = Signal()
    strategiesChanged = Signal()

    def __init__(self) -> None:
        super().__init__()
        self._tab              = "data"
        self._selected_factors: list[str] = ["RSI14", "MACD_HIST", "MA5"]
        self._current_strategy = "MACD金叉-做多策略"
        self._strategy_name    = "MACD金叉-做多策略"
        self._strategy_type    = "趋势跟踪"
        self._current_code     = _STRATEGY_CODES["MACD金叉-做多策略"]
        self._ai_loading       = False
        self._ai_mode          = "write"
        self._custom_strategies: list[dict] = []
        self._custom_factors:   list[dict] = []
        self._selected_ml_model = "LightGBM"
        self._factor_category   = "全部"
        self._mining_method     = "AI 生成"
        self._custom_data_fields: list[str] = []

    # ── read properties ─────────────────────────────────────────────────

    @Property(str, notify=stateChanged)
    def activeTab(self) -> str: return self._tab

    @Property("QVariantList", notify=stateChanged)
    def factors(self) -> list[dict]:
        return _MOCK_FACTORS + self._custom_factors

    @Property("QVariantList", notify=stateChanged)
    def customDataFields(self) -> list[str]:
        return self._custom_data_fields

    @Property("QVariantList", notify=stateChanged)
    def selectedFactors(self) -> list[str]: return self._selected_factors

    @Property(str, notify=stateChanged)
    def factorCategory(self) -> str: return self._factor_category

    @Property("QVariantList", notify=stateChanged)
    def dataSources(self) -> list[dict]: return _DATA_SOURCES

    @Property("QVariantList", notify=stateChanged)
    def minedFactors(self) -> list[dict]: return _MINED_FACTORS

    @Property("QVariantList", notify=stateChanged)
    def mlModels(self) -> list[dict]: return _ML_MODELS

    @Property(str, notify=stateChanged)
    def currentStrategy(self) -> str: return self._current_strategy

    @Property(str, notify=stateChanged)
    def strategyName(self) -> str: return self._strategy_name

    @Property(str, notify=stateChanged)
    def strategyType(self) -> str: return self._strategy_type

    @Property(str, notify=stateChanged)
    def currentCode(self) -> str: return self._current_code

    @Property(bool, notify=stateChanged)
    def aiLoading(self) -> bool: return self._ai_loading

    @Property(str, notify=stateChanged)
    def selectedMlModel(self) -> str: return self._selected_ml_model

    @Property(str, notify=stateChanged)
    def miningMethod(self) -> str: return self._mining_method

    @Property("QVariantList", notify=strategiesChanged)
    def allStrategies(self) -> list[str]:
        return BUILTIN_STRATEGIES + [s["name"] for s in self._custom_strategies]

    @Property("QVariantList", notify=strategiesChanged)
    def customStrategies(self) -> list[dict]: return self._custom_strategies

    # ── slots ────────────────────────────────────────────────────────────

    @Slot(str)
    def setTab(self, tab: str) -> None:
        if tab in _TABS and self._tab != tab:
            self._tab = tab
            self.stateChanged.emit()

    @Slot(str)
    def toggleFactor(self, name: str) -> None:
        if name in self._selected_factors:
            if len(self._selected_factors) > 1:
                self._selected_factors = [f for f in self._selected_factors if f != name]
        else:
            self._selected_factors = self._selected_factors + [name]
        self.stateChanged.emit()

    @Slot(str)
    def setFactorCategory(self, cat: str) -> None:
        if self._factor_category != cat:
            self._factor_category = cat
            self.stateChanged.emit()

    @Slot(str)
    def selectStrategy(self, name: str) -> None:
        code = _STRATEGY_CODES.get(name, "")
        if not code:
            for s in self._custom_strategies:
                if s["name"] == name:
                    code = s.get("code", "")
                    break
        self._current_strategy = name
        self._strategy_name    = name
        self._current_code     = code or f"# {name}\n# 暂无代码模板\n"
        self.stateChanged.emit()

    @Slot()
    def newStrategy(self) -> None:
        self._current_strategy = "新建策略"
        self._strategy_name    = "我的新策略"
        self._strategy_type    = "趋势跟踪"
        self._current_code     = _STRATEGY_CODES["新建策略"]
        self._tab              = "code"
        self.stateChanged.emit()

    @Slot(str)
    def setCurrentCode(self, code: str) -> None:
        if self._current_code != code:
            self._current_code = code
            self.stateChanged.emit()

    @Slot(str)
    def setStrategyName(self, name: str) -> None:
        if self._strategy_name != name:
            self._strategy_name = name
            self.stateChanged.emit()

    @Slot(str)
    def setStrategyType(self, t: str) -> None:
        if self._strategy_type != t:
            self._strategy_type = t
            self.stateChanged.emit()

    @Slot(str)
    def setMlModel(self, name: str) -> None:
        if self._selected_ml_model != name:
            self._selected_ml_model = name
            self.stateChanged.emit()

    @Slot(str)
    def setMiningMethod(self, method: str) -> None:
        if self._mining_method != method:
            self._mining_method = method
            self.stateChanged.emit()

    @Slot(str, str)
    def addCustomFactor(self, name: str, category: str) -> None:
        name = name.strip()
        if not name:
            return
        all_names = [f["name"] for f in _MOCK_FACTORS + self._custom_factors]
        if name in all_names:
            return
        self._custom_factors = self._custom_factors + [{
            "name": name, "category": category or "自定义",
            "ic": 0.0, "sharpe": 0.0, "win_rate": 50.0, "status": "待计算",
        }]
        self.stateChanged.emit()

    @Slot()
    def clearSelectedFactors(self) -> None:
        if self._selected_factors:
            self._selected_factors = self._selected_factors[:1]
            self.stateChanged.emit()

    @Slot(str)
    def addDataField(self, name: str) -> None:
        name = name.strip()
        if name and name not in self._custom_data_fields:
            self._custom_data_fields = self._custom_data_fields + [name]
            self.stateChanged.emit()

    @Slot()
    def saveStrategy(self) -> None:
        name = self._strategy_name.strip()
        if not name:
            return
        for s in self._custom_strategies:
            if s["name"] == name:
                s["code"]    = self._current_code
                s["type"]    = self._strategy_type
                s["factors"] = list(self._selected_factors)
                self._current_strategy = name
                self.stateChanged.emit()
                self.strategiesChanged.emit()
                return
        self._custom_strategies = self._custom_strategies + [{
            "name":    name,
            "type":    self._strategy_type,
            "code":    self._current_code,
            "factors": list(self._selected_factors),
        }]
        self._current_strategy = name
        self.stateChanged.emit()
        self.strategiesChanged.emit()

    @Slot()
    def aiWriteStrategy(self) -> None:
        if self._ai_loading:
            return
        self._ai_mode    = "write"
        self._ai_loading = True
        self.stateChanged.emit()
        QTimer.singleShot(2200, self._on_ai_write_done)

    def _on_ai_write_done(self) -> None:
        factors_str = ", ".join(self._selected_factors) if self._selected_factors else "RSI14, MACD_HIST"
        self._current_code  = _AI_WRITE_TEMPLATE.format(factors=factors_str)
        self._strategy_name = f"AI策略-{'+'.join(self._selected_factors[:2])}"
        self._ai_loading    = False
        self.stateChanged.emit()

    @Slot()
    def aiAnalyzeStrategy(self) -> None:
        if self._ai_loading:
            return
        self._ai_mode    = "analyze"
        self._ai_loading = True
        self.stateChanged.emit()
        QTimer.singleShot(1800, self._on_ai_analyze_done)

    def _on_ai_analyze_done(self) -> None:
        self._current_code = self._current_code.rstrip() + "\n" + _AI_ANALYZE_APPEND
        self._ai_loading   = False
        self.stateChanged.emit()
