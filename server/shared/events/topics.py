# server/shared/events/topics.py
"""事件 topic 常量。禁止在业务代码里直接写字符串。"""


class MarketTopics:
    QUOTE_UPDATED  = "market.quote.updated"
    BARS_CACHED    = "market.bars.cached"
    BARS_UPDATED   = "market.bars.updated"


class NewsTopics:
    FETCHED        = "news.fetched"
    DEDUPLICATED   = "news.deduplicated"
    AI_ANALYZED    = "news.ai_analyzed"


class AiTopics:
    SIGNAL_GENERATED   = "ai.signal.generated"
    ANALYSIS_COMPLETE  = "ai.analysis.complete"


class BacktestTopics:
    RUN_STARTED    = "backtest.run.started"
    PROGRESS       = "backtest.run.progress"
    RUN_COMPLETE   = "backtest.run.complete"
    RUN_FAILED     = "backtest.run.failed"


class RiskTopics:
    ORDER_APPROVED = "risk.order.approved"
    ORDER_REJECTED = "risk.order.rejected"
    RULE_TRIGGERED = "risk.rule.triggered"


class BrokerTopics:
    ORDER_PLACED   = "broker.order.placed"
    ORDER_FILLED   = "broker.order.filled"
    ORDER_CANCELLED = "broker.order.cancelled"
    CONNECTED      = "broker.connected"
    DISCONNECTED   = "broker.disconnected"


class SystemTopics:
    SERVICE_STARTED = "system.service.started"
    SERVICE_STOPPED = "system.service.stopped"
    ERROR           = "system.error"
