# tests/server/apps/test_api_routes.py
from __future__ import annotations
from fastapi.testclient import TestClient
from server.apps.api.main import app

client = TestClient(app)


def test_health_route():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert "status" in data
    assert "database_ok" in data
    assert "redis_ok" in data


def test_runtime_routes():
    response = client.get("/runtime/status")
    assert response.status_code == 200
    assert "profile" in response.json()

    response = client.get("/runtime/services")
    assert response.status_code == 200
    assert isinstance(response.json(), list)


def test_market_routes():
    response = client.get("/market/search?query=000001")
    assert response.status_code == 200
    results = response.json()
    assert len(results) > 0
    uuid = results[0]["id"]

    response = client.get(f"/market/quote/{uuid}")
    assert response.status_code == 200
    assert "price" in response.json()

    response = client.get(f"/market/bars/{uuid}?period=1d")
    assert response.status_code == 200
    assert len(response.json()) > 0

    response = client.post(f"/market/cache-bars?instrument_id={uuid}&period=1d&start=2024-01-01&end=2024-01-31")
    assert response.status_code == 200
    assert "storage_path" in response.json()

    response = client.get(f"/market/indicators/{uuid}?period=1d")
    assert response.status_code == 200
    assert "ma5" in response.json()


def test_news_routes():
    response = client.get("/news?source_id=eastmoney")
    assert response.status_code == 200
    results = response.json()
    assert len(results) > 0
    news_id = results[0]["id"]

    response = client.post(f"/news/{news_id}/analyze")
    assert response.status_code == 200
    assert response.json()["status"] == "enqueued"


def test_ai_routes():
    response = client.post("/ai/news/analyze?news_id=news_1")
    assert response.status_code == 200
    assert "sentiment_score" in response.json()

    response = client.post("/ai/strategy/analyze?strategy_id=strat_1")
    assert response.status_code == 200
    assert "performance_estimate" in response.json()

    response = client.post("/ai/strategy/write", json={"prompt": "trend follower", "strategy_type": "trend_following"})
    assert response.status_code == 200
    assert "code" in response.json()

    response = client.post("/ai/scores?instrument_id=SZ.000001")
    assert response.status_code == 200
    assert "overall_score" in response.json()

    response = client.post("/ai/signals?instrument_id=SZ.000001&threshold=0.5")
    assert response.status_code == 200
    assert "signal_generated" in response.json()


def test_strategy_routes():
    response = client.post("/strategies", json={
        "name": "MyDynamicMA",
        "strategy_type": "trend_following",
        "language": "python",
        "description": "Double MA",
        "code": "class MyMA:\n    pass",
        "config": {}
    })
    assert response.status_code == 201
    strat = response.json()
    assert strat["name"] == "MyDynamicMA"
    strat_id = strat["id"]

    response = client.get(f"/strategies/{strat_id}")
    assert response.status_code == 200
    assert response.json()["id"] == strat_id

    response = client.patch(f"/strategies/{strat_id}", json={
        "description": "Updated Double MA"
    })
    assert response.status_code == 200
    assert response.json()["description"] == "Updated Double MA"

    response = client.get("/strategies")
    assert response.status_code == 200
    assert len(response.json()) > 0

    response = client.get("/factors")
    assert response.status_code == 200
    assert len(response.json()) > 0


def test_backtest_routes():
    response = client.post("/backtest/runs", json={
        "strategy_id": "strat_1",
        "strategy_version_id": "ver_1",
        "mode": "single",
        "market": "A股",
        "period": "1d",
        "start_time": "2024-01-01",
        "end_time": "2024-12-31",
        "initial_capital": 100000.0
    })
    assert response.status_code == 201
    run = response.json()
    assert run["status"] == "pending"
    run_id = run["id"]

    response = client.get("/backtest/runs")
    assert response.status_code == 200
    assert len(response.json()) > 0

    response = client.get(f"/backtest/runs/{run_id}")
    assert response.status_code == 200
    assert response.json()["id"] == run_id

    response = client.get(f"/backtest/runs/{run_id}/trades")
    assert response.status_code == 200
    assert len(response.json()) > 0

    response = client.get(f"/backtest/runs/{run_id}/equity")
    assert response.status_code == 200
    assert "equity_curve_path" in response.json()


def test_risk_routes():
    response = client.get("/risk/rules")
    assert response.status_code == 200
    assert len(response.json()) > 0

    response = client.patch("/risk/rules/rule_weight_limit", json={"threshold": 0.25})
    assert response.status_code == 200
    assert response.json()["threshold"] == 0.25

    response = client.post("/risk/pre-check", json={
        "account_id": "acc_1",
        "instrument_id": "SZ.000001",
        "side": "buy",
        "qty": 100.0,
        "price": 10.5
    })
    assert response.status_code == 200
    assert response.json()["passed"] is True

    response = client.get("/risk/exposure")
    assert response.status_code == 200

    response = client.get("/risk/stats")
    assert response.status_code == 200


def test_broker_routes():
    response = client.post("/broker/connect?broker_id=sim_broker")
    assert response.status_code == 200
    assert response.json()["status"] == "connected"

    response = client.get("/broker/account?account_id=acc_1")
    assert response.status_code == 200
    assert response.json()["account_no"] == "SIM-12345"

    response = client.get("/broker/positions?account_id=acc_1")
    assert response.status_code == 200
    assert len(response.json()) > 0

    response = client.post("/broker/orders", json={
        "intent": {
            "account_id": "acc_1",
            "instrument_id": "SZ.000001",
            "side": "buy",
            "qty": 100.0,
            "price": 10.5
        },
        "risk_token": "token_123",
        "approved_at": "2026-05-23T11:00:00Z"
    })
    assert response.status_code == 200
    assert response.json()["status"] == "submitted"

    response = client.post("/broker/orders/order_1/cancel")
    assert response.status_code == 200
    assert response.json()["status"] == "cancelled"


def test_settings_routes():
    response = client.get("/settings")
    assert response.status_code == 200
    assert len(response.json()) > 0

    response = client.post("/settings?key=api_port&value=8765")
    assert response.status_code == 200

    response = client.get("/settings/secrets")
    assert response.status_code == 200
    assert len(response.json()) > 0

    response = client.post("/settings/secrets", json={
        "name": "openai_key",
        "value": "sk-proj-...",
        "provider": "ai"
    })
    assert response.status_code == 200

    response = client.get("/settings/preferences?key=theme&namespace=gui")
    assert response.status_code == 200


def test_events_routes():
    response = client.get("/events?source=system&topic=info")
    assert response.status_code == 200
    assert len(response.json()) > 0

    response = client.get("/events/summary?run_id=run_1")
    assert response.status_code == 200
    assert "total_events" in response.json()
