from __future__ import annotations

import os
import sys
from pathlib import Path

from PySide6.QtCore import QUrl
from PySide6.QtGui import QFont, QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

from pages.dashboard_controller import DashboardController
from pages.watchlist_controller import WatchlistController


def qml_root() -> Path:
    return Path(__file__).resolve().parent / "qml"


def main() -> int:
    os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")

    app = QGuiApplication(sys.argv)
    app.setOrganizationName("DhQuant")
    app.setApplicationName("DhQuant")
    app.setFont(QFont("Arial"))

    dashboard = DashboardController()
    watchlist = WatchlistController()
    watchlist.search()

    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("dashboard", dashboard)
    engine.rootContext().setContextProperty("watchlist", watchlist)
    engine.addImportPath(str(qml_root()))
    engine.load(QUrl.fromLocalFile(str(qml_root() / "App.qml")))

    if not engine.rootObjects():
        return 1
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
