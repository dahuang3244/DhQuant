from __future__ import annotations

import os
import sys
from pathlib import Path

from PySide6.QtCore import QUrl
from PySide6.QtGui import QFont, QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuick import QQuickWindow

from pages.backtest_controller import BacktestController
from pages.dashboard_controller import DashboardController
from pages.journal_controller import JournalController
from pages.news_controller import NewsController
from pages.risk_controller import RiskController
from pages.strategy_controller import StrategyController
from pages.watchlist_controller import WatchlistController


def qml_root() -> Path:
    return Path(__file__).resolve().parent / "qml"


def main() -> int:
    os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")

    QQuickWindow.setDefaultAlphaBuffer(True)

    app = QGuiApplication(sys.argv)
    app.setOrganizationName("DhQuant")
    app.setApplicationName("DhQuant")
    app.setFont(QFont("Arial"))
    
    # Set application icon
    icon_path = qml_root() / "assets" / "icons" / "dhquant-logo.svg"
    if icon_path.exists():
        app.setWindowIcon(QIcon(str(icon_path)))

    dashboard = DashboardController()
    watchlist = WatchlistController()
    strategy  = StrategyController()
    backtest  = BacktestController(strategy_ctrl=strategy)
    risk      = RiskController()
    journal   = JournalController()
    news      = NewsController()

    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("dashboard", dashboard)
    engine.rootContext().setContextProperty("watchlist", watchlist)
    engine.rootContext().setContextProperty("strategy",  strategy)
    engine.rootContext().setContextProperty("backtest",  backtest)
    engine.rootContext().setContextProperty("risk",      risk)
    engine.rootContext().setContextProperty("journal",   journal)
    engine.rootContext().setContextProperty("news",      news)
    engine.addImportPath(str(qml_root()))
    engine.load(QUrl.fromLocalFile(str(qml_root() / "App.qml")))

    if not engine.rootObjects():
        return 1
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
