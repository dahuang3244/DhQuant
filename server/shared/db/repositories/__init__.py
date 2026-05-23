"""SQLite repository exports.

Repositories accept an existing SQLAlchemy Session. They flush changes but do
not commit; callers should use server.shared.db.session.get_session().
"""

from server.shared.db.repositories.backtest import (
    BacktestArtifactRepository,
    BacktestRunRepository,
    BacktestTradeRepository,
)
from server.shared.db.repositories.base import BaseRepository
from server.shared.db.repositories.events import EventRecordRepository
from server.shared.db.repositories.instruments import InstrumentRepository
from server.shared.db.repositories.market import BarCacheRepository
from server.shared.db.repositories.news import (
    NewsAiAnalysisRepository,
    NewsRepository,
    NewsSymbolLinkRepository,
)
from server.shared.db.repositories.risk import (
    RiskLogRepository,
    RiskRuleRepository,
    RiskSnapshotRepository,
)
from server.shared.db.repositories.settings import (
    AppSettingRepository,
    PreferenceRepository,
    SecretRepository,
)
from server.shared.db.repositories.strategies import (
    FactorRepository,
    StrategyFactorRepository,
    StrategyRepository,
    StrategyVersionRepository,
)
from server.shared.db.repositories.trading import (
    AccountRepository,
    BrokerRepository,
    FillRepository,
    OrderRepository,
    PositionRepository,
)

__all__ = [
    "AccountRepository",
    "AppSettingRepository",
    "BacktestArtifactRepository",
    "BacktestRunRepository",
    "BacktestTradeRepository",
    "BarCacheRepository",
    "BaseRepository",
    "BrokerRepository",
    "EventRecordRepository",
    "FactorRepository",
    "FillRepository",
    "InstrumentRepository",
    "NewsAiAnalysisRepository",
    "NewsRepository",
    "NewsSymbolLinkRepository",
    "OrderRepository",
    "PositionRepository",
    "PreferenceRepository",
    "RiskLogRepository",
    "RiskRuleRepository",
    "RiskSnapshotRepository",
    "SecretRepository",
    "StrategyFactorRepository",
    "StrategyRepository",
    "StrategyVersionRepository",
]
