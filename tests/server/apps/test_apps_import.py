# tests/server/apps/test_apps_import.py
from __future__ import annotations
from fastapi.testclient import TestClient
from server.apps.api.main import app


def test_service_imports():
    """验证所有服务子进程的入口模块皆可正常 import。"""
    import server.apps.api.main as api_main
    import server.apps.market.main as market_main
    import server.apps.news.main as news_main
    import server.apps.ai.main as ai_main
    import server.apps.backtest_worker.main as backtest_main
    import server.apps.risk.main as risk_main
    import server.apps.broker.main as broker_main
    import server.apps.scheduler.main as scheduler_main
    import server.apps.supervisor.main as supervisor_main

    assert api_main is not None
    assert market_main is not None
    assert news_main is not None
    assert ai_main is not None
    assert backtest_main is not None
    assert risk_main is not None
    assert broker_main is not None
    assert scheduler_main is not None
    assert supervisor_main is not None


def test_api_health_endpoint():
    """使用 TestClient 测试 API 网关的健康状态接口。"""
    client = TestClient(app)
    response = client.get("/health")
    
    assert response.status_code == 200
    data = response.json()
    assert "status" in data
    assert "database_ok" in data
    assert "redis_ok" in data
    assert "services" in data
