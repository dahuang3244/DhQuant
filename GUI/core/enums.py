from __future__ import annotations

from enum import Enum


class Page(str, Enum):
    OVERVIEW = "overview"
    WATCHLIST = "watchlist"
    ACCOUNT = "account"
    STRATEGY = "strategy"
    BACKTEST = "backtest"
    RISK = "risk"
    AGENT = "agent"
    JOURNAL = "journal"


class RuntimeState(str, Enum):
    STOPPED = "Stopped"
    STARTING = "Starting"
    RUNNING = "Running"
    ERROR = "Error"


class MarketKind(str, Enum):
    US = "US"
    CHINA_A = "ChinaA"
    CRYPTO = "Crypto"


class BrokerKind(str, Enum):
    CRYPTO_GATEWAY = "CryptoGateway"
    CHINA_BROKER = "ChinaBroker"
    US_BROKER = "UsBroker"


class SearchMode(str, Enum):
    SYMBOL = "Symbol"
    MARKET = "Market"


class PredictionRange(str, Enum):
    MINUTES_30 = "30m"
    HOURS_2 = "2h"
    DAY_1 = "1d"
    WEEK_1 = "1w"
