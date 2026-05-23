# server/shared/db/models.py
from __future__ import annotations
import uuid
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import Boolean, Float, ForeignKey, Index, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _new_id() -> str:
    return str(uuid.uuid4())


# ── 第一组：身份表 ──────────────────────────────────────────────────────────

class Instrument(Base):
    """交易标的（股票、ETF 等）。"""
    __tablename__ = "instruments"
    __table_args__ = (
        Index("ix_instruments_exchange_symbol", "exchange", "symbol"),
    )

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_new_id)  # UUID 主键
    symbol: Mapped[str] = mapped_column(String(32), unique=True, nullable=False)  # 标的代码，如 000001.SZ
    name: Mapped[str] = mapped_column(String(128), nullable=False)  # 标的名称
    exchange: Mapped[str] = mapped_column(String(16), nullable=False)  # 交易所 SH / SZ / HK / US
    asset_type: Mapped[str] = mapped_column(String(16), nullable=False)  # 资产类型 stock / etf / index
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)  # 是否仍在使用（退市可置为 False）
    created_at: Mapped[str] = mapped_column(String(32), default=_now_iso)  # 入库创建时间
    updated_at: Mapped[str] = mapped_column(String(32), default=_now_iso, onupdate=_now_iso)  # 最后更新时间

    bar_caches: Mapped[list["BarCache"]] = relationship(back_populates="instrument")  # 关联行情缓存索引
    orders: Mapped[list["Order"]] = relationship(back_populates="instrument")  # 关联订单
    fills: Mapped[list["Fill"]] = relationship(back_populates="instrument")  # 关联成交回报
    positions: Mapped[list["Position"]] = relationship(back_populates="instrument")  # 关联持仓快照


class Broker(Base):
    """券商或交易网关身份，凭证正文放 secrets 表。"""
    __tablename__ = "brokers"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_new_id)  # UUID 主键
    broker_key: Mapped[str] = mapped_column(String(64), unique=True, nullable=False)  # 稳定机器名 futu / ibkr / longbridge
    name: Mapped[str] = mapped_column(String(128), nullable=False)  # 券商展示名称
    market: Mapped[str] = mapped_column(String(32), default="")  # 支持的主要市场
    status: Mapped[str] = mapped_column(String(32), default="disconnected")  # 网关连接状态
    config_json: Mapped[str] = mapped_column(Text, default="{}", nullable=False)  # 非敏感连接配置（JSON）
    created_at: Mapped[str] = mapped_column(String(32), default=_now_iso)  # 创建时间
    updated_at: Mapped[str] = mapped_column(String(32), default=_now_iso, onupdate=_now_iso)  # 更新时间

    accounts: Mapped[list["Account"]] = relationship(back_populates="broker")  # 关联名下交易账户


class Account(Base):
    """交易账户快照身份，资金明细和账单后续可独立扩展。"""
    __tablename__ = "accounts"
    __table_args__ = (
        UniqueConstraint("broker_id", "account_no", name="uq_accounts_broker_account_no"),
    )

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_new_id)  # UUID 主键
    broker_id: Mapped[str] = mapped_column(ForeignKey("brokers.id"), nullable=False)  # 所属券商 ID
    account_no: Mapped[str] = mapped_column(String(128), nullable=False)  # 券商侧账号名/ID
    name: Mapped[str] = mapped_column(String(128), default="")  # 账户备注别名
    currency: Mapped[str] = mapped_column(String(16), default="USD")  # 结算币种
    cash: Mapped[float] = mapped_column(Float, default=0.0)  # 剩余现金
    net_liquidation: Mapped[float] = mapped_column(Float, default=0.0)  # 净资产价值
    buying_power: Mapped[float] = mapped_column(Float, default=0.0)  # 当前购买力
    status: Mapped[str] = mapped_column(String(32), default="active")  # 账户状态 active / disabled
    last_sync_at: Mapped[str] = mapped_column(String(32), default="")  # 最后同步时间
    created_at: Mapped[str] = mapped_column(String(32), default=_now_iso)  # 创建时间
    updated_at: Mapped[str] = mapped_column(String(32), default=_now_iso, onupdate=_now_iso)  # 更新时间

    broker: Mapped["Broker"] = relationship(back_populates="accounts")  # 关联券商
    orders: Mapped[list["Order"]] = relationship(back_populates="account")  # 关联订单
    positions: Mapped[list["Position"]] = relationship(back_populates="account")  # 关联持仓


class Strategy(Base):
    """策略主表；历史可复现代码放 strategy_versions。"""
    __tablename__ = "strategies"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_new_id)  # UUID 主键
    name: Mapped[str] = mapped_column(String(128), unique=True, nullable=False)  # 策略名称
    strategy_type: Mapped[str] = mapped_column(String(64), default="")  # 策略类型（趋向、均值回归等）
    language: Mapped[str] = mapped_column(String(32), default="python")  # 编程语言
    description: Mapped[str] = mapped_column(Text, default="")  # 详细描述
    status: Mapped[str] = mapped_column(String(32), default="draft")  # 状态 draft / active / retired
    latest_version_id: Mapped[Optional[str]] = mapped_column(String, nullable=True)  # 当前最新版本 ID（非外键引用）
    config_json: Mapped[str] = mapped_column(Text, default="{}", nullable=False)  # 策略默认配置（JSON）
    created_at: Mapped[str] = mapped_column(String(32), default=_now_iso)  # 创建时间
    updated_at: Mapped[str] = mapped_column(String(32), default=_now_iso, onupdate=_now_iso)  # 更新时间

    versions: Mapped[list["StrategyVersion"]] = relationship(back_populates="strategy")  # 代码版本历史
    factors: Mapped[list["StrategyFactor"]] = relationship(back_populates="strategy")  # 所选用的因子关联


# ── 第二组：配置与凭证表 ────────────────────────────────────────────────────

class AppSetting(Base):
    """键值对配置项，存非敏感配置（如 UI 偏好、数据源选择）。"""
    __tablename__ = "settings"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_new_id)  # UUID 主键
    key: Mapped[str] = mapped_column(String(128), unique=True, nullable=False)  # 配置键
    value: Mapped[str] = mapped_column(Text, nullable=False)  # 配置内容
    value_type: Mapped[str] = mapped_column(String(16), default="string")  # string/int/float/bool/json 类型标识
    description: Mapped[str] = mapped_column(Text, default="")  # 配置项描述
    created_at: Mapped[str] = mapped_column(String(32), default=_now_iso)  # 创建时间
    updated_at: Mapped[str] = mapped_column(String(32), default=_now_iso, onupdate=_now_iso)  # 更新时间


class Secret(Base):
    """加密存储的凭证（AI Key、Broker Secret、数据源 Token）。"""
    __tablename__ = "secrets"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_new_id)  # UUID 主键
    name: Mapped[str] = mapped_column(String(128), unique=True, nullable=False)  # 凭证名称，如 openai_api_key
    encrypted_value: Mapped[str] = mapped_column(Text, nullable=False)  # 加密后的密文内容
    provider: Mapped[str] = mapped_column(String(64), nullable=False)  # 归属分类 ai / broker / datasource
    created_at: Mapped[str] = mapped_column(String(32), default=_now_iso)  # 创建时间
    updated_at: Mapped[str] = mapped_column(String(32), default=_now_iso, onupdate=_now_iso)  # 更新时间


class Preference(Base):
    """用户偏好，主要承接 GUI 开关、页面状态和轻量默认值。"""
    __tablename__ = "preferences"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_new_id)  # UUID 主键
    namespace: Mapped[str] = mapped_column(String(64), default="global")  # 偏好空间/模块（global/gui/dashboard）
    key: Mapped[str] = mapped_column(String(128), nullable=False)  # 偏好键
    value: Mapped[str] = mapped_column(Text, nullable=False)  # 偏好内容
    value_type: Mapped[str] = mapped_column(String(16), default="string")  # 偏好内容类型
    created_at: Mapped[str] = mapped_column(String(32), default=_now_iso)  # 创建时间
    updated_at: Mapped[str] = mapped_column(String(32), default=_now_iso, onupdate=_now_iso)  # 更新时间

    __table_args__ = (
        UniqueConstraint("namespace", "key", name="uq_preferences_namespace_key"),
    )


# ── 第三组：行情缓存元数据 ──────────────────────────────────────────────────

class BarCache(Base):
    """K 线缓存索引；K 线事实在 Parquet，SQLite 只保存元数据。"""
    __tablename__ = "bar_cache"
    __table_args__ = (
        UniqueConstraint("instrument_id", "period", "source", "storage_path", name="uq_bar_cache_file"),
        Index("ix_bar_cache_lookup", "instrument_id", "period", "start_time", "end_time"),
    )

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_new_id)  # UUID 主键
    instrument_id: Mapped[str] = mapped_column(ForeignKey("instruments.id"), nullable=False)  # 关联标的 ID
    period: Mapped[str] = mapped_column(String(16), nullable=False)  # K 线周期 1m / 5m / 1d
    start_time: Mapped[str] = mapped_column(String(32), nullable=False)  # 本文件覆盖的业务起始时间
    end_time: Mapped[str] = mapped_column(String(32), nullable=False)  # 本文件覆盖的业务结束时间
    source: Mapped[str] = mapped_column(String(64), nullable=False)  # 数据来源 akshare / broker / csv
    storage_type: Mapped[str] = mapped_column(String(16), default="parquet")  # 存储介质通常是 parquet
    storage_path: Mapped[str] = mapped_column(Text, nullable=False)  # 文件相对于存储根目录的路径
    row_count: Mapped[int] = mapped_column(Integer, default=0)  # 文件中包含的记录数
    checksum: Mapped[str] = mapped_column(String(128), default="")  # 文件校验和
    created_at: Mapped[str] = mapped_column(String(32), default=_now_iso)  # 创建时间
    updated_at: Mapped[str] = mapped_column(String(32), default=_now_iso, onupdate=_now_iso)  # 更新时间

    instrument: Mapped["Instrument"] = relationship(back_populates="bar_caches")  # 关联标的主数据对象


# ── 第四组：新闻与 AI 分析 ─────────────────────────────────────────────────

class NewsItem(Base):
    """新闻正文和元数据，供新闻页、AI 分析和复盘引用。"""
    __tablename__ = "news"
    __table_args__ = (
        Index("ix_news_publish_time", "publish_time"),
        Index("ix_news_industry", "industry"),
    )

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_new_id)  # UUID 主键
    title: Mapped[str] = mapped_column(Text, nullable=False)  # 新闻标题
    content: Mapped[str] = mapped_column(Text, default="")  # 新闻正文全文
    source: Mapped[str] = mapped_column(String(64), nullable=False)  # 信息来源（如 华尔街见闻、新浪财经）
    url: Mapped[str] = mapped_column(Text, unique=True, nullable=False)  # 原始链接（去重依据）
    publish_time: Mapped[str] = mapped_column(String(32), default="")  # 信息发布时间
    industry: Mapped[str] = mapped_column(String(64), default="")  # 涉及行业分类
    sentiment: Mapped[str] = mapped_column(String(32), default="")  # 情感评估关键词
    tags_json: Mapped[str] = mapped_column(Text, default="[]", nullable=False)  # 标签数组（JSON）
    ai_analyzed: Mapped[bool] = mapped_column(Boolean, default=False)  # 是否已由 AI 进行过处理分析
    created_at: Mapped[str] = mapped_column(String(32), default=_now_iso)  # 入库创建时间
    updated_at: Mapped[str] = mapped_column(String(32), default=_now_iso, onupdate=_now_iso)  # 最后更新时间

    analyses: Mapped[list["NewsAiAnalysis"]] = relationship(back_populates="news")  # 关联 AI 分析结果
    symbol_links: Mapped[list["NewsSymbolLink"]] = relationship(back_populates="news")  # 关联的相关标的


class NewsAiAnalysis(Base):
    """新闻 AI 摘要、影响判断和证据链元数据。"""
    __tablename__ = "news_ai_analysis"
    __table_args__ = (
        Index("ix_news_ai_analysis_news_id", "news_id"),
    )

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_new_id)  # UUID 主键
    news_id: Mapped[str] = mapped_column(ForeignKey("news.id"), nullable=False)  # 归属新闻 ID
    provider: Mapped[str] = mapped_column(String(64), default="")  # AI 服务商（OpenAI, DeepSeek 等）
    model_name: Mapped[str] = mapped_column(String(128), default="")  # 使用的具体模型名
    prompt_version: Mapped[str] = mapped_column(String(64), default="")  # Prompt 模板版本
    summary: Mapped[str] = mapped_column(Text, default="")  # AI 语义摘要
    impact: Mapped[str] = mapped_column(Text, default="")  # AI 判断的潜在影响
    sentiment_score: Mapped[float] = mapped_column(Float, default=0.0)  # 数字化情感得分 -1.0 到 1.0
    confidence: Mapped[float] = mapped_column(Float, default=0.0)  # AI 对本次分析的自信度
    evidence_json: Mapped[str] = mapped_column(Text, default="[]", nullable=False)  # 证据链或原文引用片段（JSON）
    tool_trace_id: Mapped[str] = mapped_column(String(128), default="")  # 关联的处理过程追踪 ID
    created_at: Mapped[str] = mapped_column(String(32), default=_now_iso)  # 分析生成时间

    news: Mapped["NewsItem"] = relationship(back_populates="analyses")  # 关联原始新闻对象


class NewsSymbolLink(Base):
    """新闻与标的的关联关系，用于新闻页过滤和 AI 证据链。"""
    __tablename__ = "news_symbol_links"
    __table_args__ = (
        UniqueConstraint("news_id", "instrument_id", name="uq_news_symbol_links_news_instrument"),
    )

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_new_id)  # UUID 主键
    news_id: Mapped[str] = mapped_column(ForeignKey("news.id"), nullable=False)  # 关联新闻 ID
    instrument_id: Mapped[str] = mapped_column(ForeignKey("instruments.id"), nullable=False)  # 关联标的 ID
    relevance: Mapped[float] = mapped_column(Float, default=0.0)  # 相关度（AI计算或人工标注）
    reason: Mapped[str] = mapped_column(Text, default="")  # 关联理由说明
    created_at: Mapped[str] = mapped_column(String(32), default=_now_iso)  # 建立关联时间

    news: Mapped["NewsItem"] = relationship(back_populates="symbol_links")  # 关联原新闻
    instrument: Mapped["Instrument"] = relationship()  # 关联标的对象


# ── 第五组：策略与因子 ─────────────────────────────────────────────────────

class StrategyVersion(Base):
    """策略版本快照；回测必须引用版本而不是可变策略主表。"""
    __tablename__ = "strategy_versions"
    __table_args__ = (
        UniqueConstraint("strategy_id", "version", name="uq_strategy_versions_strategy_version"),
    )

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_new_id)  # UUID 主键
    strategy_id: Mapped[str] = mapped_column(ForeignKey("strategies.id"), nullable=False)  # 所属策略主表 ID
    version: Mapped[int] = mapped_column(Integer, nullable=False)  # 版本号（递增整数）
    code: Mapped[str] = mapped_column(Text, nullable=False)  # 策略源代码快照
    config_json: Mapped[str] = mapped_column(Text, default="{}", nullable=False)  # 该版本对应的默认配置（JSON）
    notes: Mapped[str] = mapped_column(Text, default="")  # 版本修订说明
    created_at: Mapped[str] = mapped_column(String(32), default=_now_iso)  # 版本发布时间

    strategy: Mapped["Strategy"] = relationship(back_populates="versions")  # 关联策略主表对象
    backtest_runs: Mapped[list["BacktestRun"]] = relationship(back_populates="strategy_version")  # 引用该版本的历史回测记录


class Factor(Base):
    """因子库元数据；大规模因子矩阵仍存 Parquet。"""
    __tablename__ = "factors"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_new_id)  # UUID 主键
    name: Mapped[str] = mapped_column(String(128), unique=True, nullable=False)  # 因子名称标识
    category: Mapped[str] = mapped_column(String(64), default="")  # 因子分类（质量、动量、估值等）
    formula: Mapped[str] = mapped_column(Text, default="")  # 因子计算逻辑描述或公式
    description: Mapped[str] = mapped_column(Text, default="")  # 详细说明
    ic: Mapped[float] = mapped_column(Float, default=0.0)  # 最近计算的 IC 值摘要
    sharpe: Mapped[float] = mapped_column(Float, default=0.0)  # 该因子模拟表现的夏普比率
    win_rate: Mapped[float] = mapped_column(Float, default=0.0)  # 该因子模拟表现的胜率
    status: Mapped[str] = mapped_column(String(32), default="active")  # 因子状态 active / deprecated
    source: Mapped[str] = mapped_column(String(64), default="manual")  # 来源方式 manual / auto_mining
    created_at: Mapped[str] = mapped_column(String(32), default=_now_iso)  # 因子录入时间
    updated_at: Mapped[str] = mapped_column(String(32), default=_now_iso, onupdate=_now_iso)  # 最后更新时间

    strategies: Mapped[list["StrategyFactor"]] = relationship(back_populates="factor")  # 关联使用此因子的策略


class StrategyFactor(Base):
    """策略与因子的选择关系。"""
    __tablename__ = "strategy_factors"
    __table_args__ = (
        UniqueConstraint("strategy_id", "factor_id", name="uq_strategy_factors_strategy_factor"),
    )

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_new_id)  # UUID 主键
    strategy_id: Mapped[str] = mapped_column(ForeignKey("strategies.id"), nullable=False)  # 策略 ID
    factor_id: Mapped[str] = mapped_column(ForeignKey("factors.id"), nullable=False)  # 因子 ID
    weight: Mapped[float] = mapped_column(Float, default=1.0)  # 该因子在策略中的权重配置
    created_at: Mapped[str] = mapped_column(String(32), default=_now_iso)  # 绑定关联时间

    strategy: Mapped["Strategy"] = relationship(back_populates="factors")  # 所属策略
    factor: Mapped["Factor"] = relationship(back_populates="strategies")  # 所选因子


# ── 第六组：回测 ───────────────────────────────────────────────────────────

class BacktestRun(Base):
    """回测任务和指标摘要；曲线/标注等长序列放 Parquet artifact。"""
    __tablename__ = "backtest_runs"
    __table_args__ = (
        Index("ix_backtest_runs_status_created", "status", "created_at"),
    )

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_new_id)  # UUID 主键
    strategy_id: Mapped[str] = mapped_column(ForeignKey("strategies.id"), nullable=False)  # 回测目标策略 ID
    strategy_version_id: Mapped[Optional[str]] = mapped_column(ForeignKey("strategy_versions.id"), nullable=True)  # 具体代码版本 ID
    status: Mapped[str] = mapped_column(String(32), default="pending")  # 任务状态 pending/running/success/failed
    mode: Mapped[str] = mapped_column(String(32), default="single")  # 回测模式 single / batch / walk_forward
    market: Mapped[str] = mapped_column(String(32), default="")  # 回测涉及市场
    period: Mapped[str] = mapped_column(String(16), default="1d")  # 回测主要 K 线周期
    start_time: Mapped[str] = mapped_column(String(32), default="")  # 历史回测起始业务时间
    end_time: Mapped[str] = mapped_column(String(32), default="")  # 历史回测结束业务时间
    initial_capital: Mapped[float] = mapped_column(Float, default=0.0)  # 初始本金
    commission: Mapped[float] = mapped_column(Float, default=0.0)  # 默认佣金比例
    leverage: Mapped[float] = mapped_column(Float, default=1.0)  # 使用杠杆倍数
    config_json: Mapped[str] = mapped_column(Text, default="{}", nullable=False)  # 回测完整动态配置（JSON）
    metrics_json: Mapped[str] = mapped_column(Text, default="{}", nullable=False)  # 绩效指标摘要结果（JSON）
    error: Mapped[str] = mapped_column(Text, default="")  # 运行失败报错信息
    created_at: Mapped[str] = mapped_column(String(32), default=_now_iso)  # 任务触发创建时间
    started_at: Mapped[str] = mapped_column(String(32), default="")  # 引擎实际开始运行时间
    finished_at: Mapped[str] = mapped_column(String(32), default="")  # 运行结束完成时间

    strategy: Mapped["Strategy"] = relationship()  # 关联策略主表
    strategy_version: Mapped[Optional["StrategyVersion"]] = relationship(back_populates="backtest_runs")  # 关联具体代码版本
    trades: Mapped[list["BacktestTrade"]] = relationship(back_populates="run")  # 本次运行产生的交易明细
    artifacts: Mapped[list["BacktestArtifact"]] = relationship(back_populates="run")  # 产生的中间或结果文件引用


class BacktestTrade(Base):
    """回测交易明细；大规模明细可转 Parquet 后用 artifact 引用。"""
    __tablename__ = "backtest_trades"
    __table_args__ = (
        Index("ix_backtest_trades_run_exit", "run_id", "exit_time"),
    )

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_new_id)  # UUID 主键
    run_id: Mapped[str] = mapped_column(ForeignKey("backtest_runs.id"), nullable=False)  # 所属回测运行 ID
    instrument_id: Mapped[str] = mapped_column(ForeignKey("instruments.id"), nullable=False)  # 交易标的 ID
    entry_time: Mapped[str] = mapped_column(String(32), default="")  # 入场业务时间
    exit_time: Mapped[str] = mapped_column(String(32), default="")  # 出场业务时间
    side: Mapped[str] = mapped_column(String(16), nullable=False)  # 交易方向 buy_long / sell_short
    qty: Mapped[float] = mapped_column(Float, default=0.0)  # 交易数量
    entry_price: Mapped[float] = mapped_column(Float, default=0.0)  # 入场成交价格
    exit_price: Mapped[float] = mapped_column(Float, default=0.0)  # 出场成交价格
    pnl: Mapped[float] = mapped_column(Float, default=0.0)  # 本次交易盈亏额
    return_pct: Mapped[float] = mapped_column(Float, default=0.0)  # 本次交易回报率百分比
    hold_days: Mapped[float] = mapped_column(Float, default=0.0)  # 持仓天数
    created_at: Mapped[str] = mapped_column(String(32), default=_now_iso)  # 明细产生日期

    run: Mapped["BacktestRun"] = relationship(back_populates="trades")  # 回调回测运行记录
    instrument: Mapped["Instrument"] = relationship()  # 关联标的主数据


class BacktestArtifact(Base):
    """回测长序列或图表数据引用，例如权益曲线 Parquet 文件。"""
    __tablename__ = "backtest_artifacts"
    __table_args__ = (
        UniqueConstraint("run_id", "artifact_type", "storage_path", name="uq_backtest_artifacts_run_type_path"),
    )

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_new_id)  # UUID 主键
    run_id: Mapped[str] = mapped_column(ForeignKey("backtest_runs.id"), nullable=False)  # 所属回测运行 ID
    artifact_type: Mapped[str] = mapped_column(String(64), nullable=False)  # 产物类型 equity_curve / pnl_bars / signal_trace
    storage_type: Mapped[str] = mapped_column(String(16), default="parquet")  # 存储介质
    storage_path: Mapped[str] = mapped_column(Text, nullable=False)  # 存储相对路径
    row_count: Mapped[int] = mapped_column(Integer, default=0)  # 产物包含的记录行数
    checksum: Mapped[str] = mapped_column(String(128), default="")  # 离线文件校验和
    metadata_json: Mapped[str] = mapped_column(Text, default="{}", nullable=False)  # 产物额外元数据说明（JSON）
    created_at: Mapped[str] = mapped_column(String(32), default=_now_iso)  # 生成时间

    run: Mapped["BacktestRun"] = relationship(back_populates="artifacts")  # 归属的回测任务对象


# ── 第七组：风控 ───────────────────────────────────────────────────────────

class RiskRule(Base):
    """风控规则配置，可被 GUI 启停和调整阈值。"""
    __tablename__ = "risk_rules"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_new_id)  # UUID 主键
    name: Mapped[str] = mapped_column(String(128), nullable=False)  # 规则名称，如 单票持仓上限
    rule_type: Mapped[str] = mapped_column(String(64), default="")  # 规则分类 position / order / portfolio
    enabled: Mapped[bool] = mapped_column(Boolean, default=True)  # 是否启用该规则
    threshold: Mapped[float] = mapped_column(Float, default=0.0)  # 规则触发阈值
    current_value: Mapped[float] = mapped_column(Float, default=0.0)  # 当前实际监控值摘要
    step: Mapped[float] = mapped_column(Float, default=1.0)  # GUI 调节步长
    unit: Mapped[str] = mapped_column(String(32), default="")  # 数值单位（%, USD, share 等）
    status: Mapped[str] = mapped_column(String(32), default="idle")  # 规则当前状态 idle / alerting / triggered
    config_json: Mapped[str] = mapped_column(Text, default="{}", nullable=False)  # 复杂规则逻辑配置（JSON）
    created_at: Mapped[str] = mapped_column(String(32), default=_now_iso)  # 创建日期
    updated_at: Mapped[str] = mapped_column(String(32), default=_now_iso, onupdate=_now_iso)  # 最后修改日期

    logs: Mapped[list["RiskLog"]] = relationship(back_populates="rule")  # 归属该规则的历史风控检查日志


class RiskLog(Base):
    """风控检查日志，拒单原因和通过记录都可审计。"""
    __tablename__ = "risk_logs"
    __table_args__ = (
        Index("ix_risk_logs_created_result", "created_at", "result"),
    )

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_new_id)  # UUID 主键
    rule_id: Mapped[Optional[str]] = mapped_column(ForeignKey("risk_rules.id"), nullable=True)  # 触发的风控规则 ID
    order_id: Mapped[Optional[str]] = mapped_column(ForeignKey("orders.id"), nullable=True)  # 关联的订单 ID（如有）
    instrument_id: Mapped[Optional[str]] = mapped_column(ForeignKey("instruments.id"), nullable=True)  # 关联的标的 ID
    result: Mapped[str] = mapped_column(String(32), nullable=False)  # 检查结果 passed / rejected / warning
    level: Mapped[str] = mapped_column(String(16), default="info")  # 日志级别 info / warn / error
    message: Mapped[str] = mapped_column(Text, default="")  # 风控报告摘要信息
    check_value: Mapped[float] = mapped_column(Float, default=0.0)  # 本次检查的具体数值
    limit_value: Mapped[float] = mapped_column(Float, default=0.0)  # 本次检查时对应的阈值
    detail_json: Mapped[str] = mapped_column(Text, default="{}", nullable=False)  # 详细上下文证据（JSON）
    created_at: Mapped[str] = mapped_column(String(32), default=_now_iso)  # 日志生成时间

    rule: Mapped[Optional["RiskRule"]] = relationship(back_populates="logs")  # 关联的风控规则
    order: Mapped[Optional["Order"]] = relationship(back_populates="risk_logs")  # 关联的订单
    instrument: Mapped[Optional["Instrument"]] = relationship()  # 关联的标的


class RiskSnapshot(Base):
    """组合风险快照，供风控页展示敞口、行业权重等摘要。"""
    __tablename__ = "risk_snapshots"
    __table_args__ = (
        Index("ix_risk_snapshots_created", "created_at"),
    )

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_new_id)  # UUID 主键
    account_id: Mapped[Optional[str]] = mapped_column(ForeignKey("accounts.id"), nullable=True)  # 关联的账户 ID
    status: Mapped[str] = mapped_column(String(32), default="IDLE")  # 风险状态 IDLE / CRITICAL
    net_long_weight: Mapped[float] = mapped_column(Float, default=0.0)  # 组合净多头总权重
    net_short_weight: Mapped[float] = mapped_column(Float, default=0.0)  # 组合净空头总权重
    exposures_json: Mapped[str] = mapped_column(Text, default="[]", nullable=False)  # 风险敞口明细（JSON）
    sectors_json: Mapped[str] = mapped_column(Text, default="[]", nullable=False)  # 行业分布明细（JSON）
    metrics_json: Mapped[str] = mapped_column(Text, default="{}", nullable=False)  # 组合风险指标摘要（JSON）
    created_at: Mapped[str] = mapped_column(String(32), default=_now_iso)  # 快照生成时间


# ── 第八组：交易与审计 Journal ─────────────────────────────────────────────

class EventRecord(Base):
    """统一事件审计表；Redis Stream 负责实时推送，SQLite 负责长期审计。"""
    __tablename__ = "events"
    __table_args__ = (
        Index("ix_events_run_topic_created", "run_id", "topic", "created_at"),
        Index("ix_events_correlation", "correlation_id"),
    )

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_new_id)  # UUID 主键
    run_id: Mapped[str] = mapped_column(String(64), default="")  # 会话运行 ID（同一次回测或实盘进程）
    sequence: Mapped[int] = mapped_column(Integer, default=0)  # 该会话内的递增序号
    source: Mapped[str] = mapped_column(String(64), nullable=False)  # 事件来源模块或服务名
    topic: Mapped[str] = mapped_column(String(128), nullable=False)  # 事件主题/类型（order.created, market.bar）
    level: Mapped[str] = mapped_column(String(16), default="info")  # 事件级别 info / warn / error
    instrument_id: Mapped[Optional[str]] = mapped_column(ForeignKey("instruments.id"), nullable=True)  # 关联标的 ID
    correlation_id: Mapped[str] = mapped_column(String(128), default="")  # 链路追踪 ID（串联信号-订单-成交）
    causation_id: Mapped[str] = mapped_column(String(128), default="")  # 直接触发本事件的上游事件 ID
    message: Mapped[str] = mapped_column(Text, default="")  # 事件可读简述
    detail_json: Mapped[str] = mapped_column(Text, default="{}", nullable=False)  # 事件完整数据负载（JSON）
    event_time: Mapped[str] = mapped_column(String(32), default="")  # 业务发生时间
    created_at: Mapped[str] = mapped_column(String(32), default=_now_iso)  # 入库记录时间

    instrument: Mapped[Optional["Instrument"]] = relationship()  # 关联的标的对象


class Order(Base):
    """实盘/模拟盘订单事实；成交回报写 fills。"""
    __tablename__ = "orders"
    __table_args__ = (
        Index("ix_orders_account_status_created", "account_id", "status", "created_at"),
        Index("ix_orders_correlation", "correlation_id"),
    )

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_new_id)  # UUID 主键
    account_id: Mapped[Optional[str]] = mapped_column(ForeignKey("accounts.id"), nullable=True)  # 归属账户 ID
    strategy_id: Mapped[Optional[str]] = mapped_column(ForeignKey("strategies.id"), nullable=True)  # 触发下单的策略 ID
    instrument_id: Mapped[str] = mapped_column(ForeignKey("instruments.id"), nullable=False)  # 交易标的 ID
    broker_order_id: Mapped[str] = mapped_column(String(128), default="")  # 券商侧返回的订单号
    side: Mapped[str] = mapped_column(String(16), nullable=False)  # 买卖方向 buy / sell
    order_type: Mapped[str] = mapped_column(String(32), default="market")  # 订单类型 market / limit / stop
    qty: Mapped[float] = mapped_column(Float, nullable=False)  # 订单委托数量
    price: Mapped[float] = mapped_column(Float, default=0.0)  # 委托价格（市价单通常为 0）
    status: Mapped[str] = mapped_column(String(32), default="pending")  # 状态 pending/submitted/filled/cancelled/rejected
    submitted_at: Mapped[str] = mapped_column(String(32), default="")  # 提交到券商的时间
    updated_at: Mapped[str] = mapped_column(String(32), default=_now_iso, onupdate=_now_iso)  # 订单最后状态更新时间
    correlation_id: Mapped[str] = mapped_column(String(128), default="")  # 链路追踪 ID
    raw_json: Mapped[str] = mapped_column(Text, default="{}", nullable=False)  # 券商接口原始响应负载（JSON）
    created_at: Mapped[str] = mapped_column(String(32), default=_now_iso)  # 本地创建时间

    account: Mapped[Optional["Account"]] = relationship(back_populates="orders")  # 关联账户对象
    instrument: Mapped["Instrument"] = relationship(back_populates="orders")  # 关联标的对象
    fills: Mapped[list["Fill"]] = relationship(back_populates="order")  # 关联该订单产生的成交回报
    risk_logs: Mapped[list["RiskLog"]] = relationship(back_populates="order")  # 关联该订单触发的风控检查


class Fill(Base):
    """成交回报，驱动账本和持仓更新。"""
    __tablename__ = "fills"
    __table_args__ = (
        UniqueConstraint("order_id", "broker_fill_id", name="uq_fills_order_broker_fill"),
        Index("ix_fills_instrument_time", "instrument_id", "filled_at"),
    )

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_new_id)  # UUID 主键
    order_id: Mapped[str] = mapped_column(ForeignKey("orders.id"), nullable=False)  # 关联委托订单 ID
    instrument_id: Mapped[str] = mapped_column(ForeignKey("instruments.id"), nullable=False)  # 交易标的 ID
    broker_fill_id: Mapped[str] = mapped_column(String(128), default="")  # 券商侧返回的成交 ID
    side: Mapped[str] = mapped_column(String(16), nullable=False)  # 成交方向 buy / sell
    qty: Mapped[float] = mapped_column(Float, nullable=False)  # 本次成交数量
    price: Mapped[float] = mapped_column(Float, nullable=False)  # 本次成交价格
    commission: Mapped[float] = mapped_column(Float, default=0.0)  # 本次成交佣金
    filled_at: Mapped[str] = mapped_column(String(32), nullable=False)  # 券商侧成交业务时间
    raw_json: Mapped[str] = mapped_column(Text, default="{}", nullable=False)  # 券商接口原始成交数据（JSON）
    created_at: Mapped[str] = mapped_column(String(32), default=_now_iso)  # 本地入库时间

    order: Mapped["Order"] = relationship(back_populates="fills")  # 归属订单
    instrument: Mapped["Instrument"] = relationship(back_populates="fills")  # 关联标的


class Position(Base):
    """账户持仓快照，实时热状态可在 Redis，事实快照落 SQLite。"""
    __tablename__ = "positions"
    __table_args__ = (
        UniqueConstraint("account_id", "instrument_id", name="uq_positions_account_instrument"),
    )

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_new_id)  # UUID 主键
    account_id: Mapped[str] = mapped_column(ForeignKey("accounts.id"), nullable=False)  # 所属账户 ID
    instrument_id: Mapped[str] = mapped_column(ForeignKey("instruments.id"), nullable=False)  # 关联标的 ID
    side: Mapped[str] = mapped_column(String(16), default="long")  # 持仓方向 long / short
    qty: Mapped[float] = mapped_column(Float, default=0.0)  # 当前持仓数量
    avg_price: Mapped[float] = mapped_column(Float, default=0.0)  # 持仓均价（成本价）
    market_value: Mapped[float] = mapped_column(Float, default=0.0)  # 持仓市值快照
    unrealized_pnl: Mapped[float] = mapped_column(Float, default=0.0)  # 未实现盈亏
    realized_pnl: Mapped[float] = mapped_column(Float, default=0.0)  # 该标的累计已实现盈亏
    weight: Mapped[float] = mapped_column(Float, default=0.0)  # 该标的在账户中的仓位权重
    updated_at: Mapped[str] = mapped_column(String(32), default=_now_iso, onupdate=_now_iso)  # 最后一次同步更新时间

    account: Mapped["Account"] = relationship(back_populates="positions")  # 关联账户对象
    instrument: Mapped["Instrument"] = relationship(back_populates="positions")  # 关联标的对象


# ── 字段设计注释 ───────────────────────────────────────────────────────────
#
# 这份 ORM 只描述 SQLite 的职责范围：事务型事实、配置、元数据、审计索引。
# 历史 K 线、因子矩阵、回测权益曲线、批量交易明细等长序列不直接放 SQLite；
# SQLite 只通过 bar_cache / backtest_artifacts 保存 Parquet 文件路径和摘要信息，
# DuckDB 再负责对 Parquet 做本地分析查询。
#
# 1. instruments
#    - 全系统统一标的主数据表，其他模块不要直接用 symbol 字符串硬连。
#    - symbol: 标准代码，例如 AAPL、000001.SZ、BTCUSDT。
#    - exchange: 交易所或市场，如 SH、SZ、HK、US、CRYPTO。
#    - asset_type: stock / etf / index / crypto / future 等资产类型。
#    - is_active: 是否仍在系统中可用，退市或停用标的可置为 False。
#
# 2. brokers / accounts
#    - brokers 存券商或交易网关身份，不存明文密钥。
#    - broker_key: 稳定机器名，如 futu、ibkr、longbridge。
#    - config_json: 非敏感连接配置；敏感字段必须进入 secrets.encrypted_value。
#    - accounts 存券商账户身份和最近一次资金快照摘要。
#    - account_no: 券商侧账号；与 broker_id 组合唯一。
#    - cash / net_liquidation / buying_power: GUI 账户页和风控快照常用摘要。
#
# 3. settings / secrets / preferences
#    - settings: 系统级非敏感配置，适合按 key 读写。
#    - secrets: 加密凭证表，只保存密文和 provider 分类。
#    - preferences: 用户偏好和 GUI 页面状态，namespace + key 唯一。
#    - value_type: 由 Repository/Service 负责按 string/int/float/bool/json 解析。
#
# 4. bar_cache
#    - 行情缓存元数据表，不保存每根 K 线。
#    - instrument_id: 关联 instruments.id。
#    - period: K 线周期，如 1m、5m、1h、1d。
#    - start_time / end_time: 当前 Parquet 分区覆盖的业务时间范围。
#    - source: 数据来源，如 akshare、broker、csv_import。
#    - storage_type: 通常是 parquet，保留扩展空间。
#    - storage_path: 对应 Parquet 文件或目录路径。
#    - row_count / checksum: 用于缓存完整性检查、增量更新和去重。
#
# 5. news / news_ai_analysis / news_symbol_links
#    - news 存新闻正文和可追溯元数据，url 唯一用于爬虫去重。
#    - publish_time: 新闻发布时间；created_at 是本系统入库时间。
#    - tags_json: 标签数组，使用 JSON 文本保存。
#    - ai_analyzed: 是否已经完成 AI 分析，方便异步任务筛选。
#    - news_ai_analysis: 一条新闻可有多次不同模型或 prompt 版本的分析结果。
#    - evidence_json: AI 证据链、引用片段、反向证据等结构化内容。
#    - news_symbol_links: 新闻和标的的多对多关联，relevance 表示相关度。
#
# 6. strategies / strategy_versions / factors / strategy_factors
#    - strategies 是可变主表，保存当前策略身份、状态和默认配置。
#    - latest_version_id: 指向当前最新版本 ID；这里不加外键是为了避免循环依赖。
#    - strategy_versions 保存代码快照，回测必须引用版本，保证历史可复现。
#    - code: 策略源码或配置化策略文本。
#    - factors 存因子元数据和摘要指标；大规模因子矩阵仍进 Parquet。
#    - ic / sharpe / win_rate: 用于 GUI 因子页快速展示的摘要指标。
#    - strategy_factors: 策略选择了哪些因子，以及该因子的权重。
#
# 7. backtest_runs / backtest_trades / backtest_artifacts
#    - backtest_runs 是回测任务主表，保存状态、参数和指标摘要。
#    - status: pending / running / success / failed / cancelled。
#    - config_json: 回测完整配置，如标的列表、滑点模型、撮合模型。
#    - metrics_json: 收益率、胜率、最大回撤等轻量结果摘要。
#    - backtest_trades: 中小规模交易明细可直接入 SQLite，便于 GUI 分页查看。
#    - 大规模交易明细、权益曲线、annotated bars 应写 Parquet，再进 artifacts。
#    - artifact_type: equity_curve / annotated_bars / pnl_bars / trades 等。
#    - metadata_json: artifact 的列说明、时间范围、策略名等补充信息。
#
# 8. risk_rules / risk_logs / risk_snapshots
#    - risk_rules 存可配置风控规则，GUI 可以启停和调整阈值。
#    - rule_type: 规则类型，如 single_order、position、portfolio、system。
#    - threshold / current_value / step / unit: 支撑风控页阈值展示和微调。
#    - risk_logs 存每次风控检查结果，拒绝和通过都可审计。
#    - result: passed / rejected / warning。
#    - check_value / limit_value: 本次检查值与限制值，便于解释拒单原因。
#    - risk_snapshots 存组合风险摘要，明细 exposure/sector 用 JSON 文本保存。
#
# 9. events
#    - 统一事件审计表；实时推送走 Redis Stream，长期追溯走 SQLite。
#    - run_id: 一次回测、模拟盘、实盘会话或服务运行的 ID。
#    - sequence: 单 run 内递增序号，保证同时间事件仍可稳定排序。
#    - topic: 事件主题，如 market.bar.1m、order.updated、risk.rejected。
#    - correlation_id: 串联信号、订单、成交、风控、账本的链路 ID。
#    - causation_id: 直接触发当前事件的上游事件 ID。
#    - event_time: 业务时间；created_at 是本系统写入时间。
#    - detail_json: 事件完整扩展信息，便于 Journal 页面和调试查询。
#
# 10. orders / fills / positions
#    - orders 存订单事实，成交回报不直接覆盖订单，而是写 fills。
#    - broker_order_id: 券商侧订单号，可为空，提交后由 Broker 服务回填。
#    - side: buy / sell；order_type: market / limit / stop 等。
#    - raw_json: 保留券商原始回报，方便排查适配层问题。
#    - fills 存成交事实，是账户、持仓、账本更新的依据。
#    - broker_fill_id: 券商侧成交号，与 order_id 组合去重。
#    - positions 存账户持仓快照；实时最新值可在 Redis，事实快照落 SQLite。
#    - account_id + instrument_id 唯一，表示一个账户对一个标的的当前快照。
