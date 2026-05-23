# tests/server/domain/test_domain_services.py
from datetime import datetime
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from server.shared.db.base import Base
import server.shared.db.models  # 触发 ORM 模型类注册

from server.domain.runtime.service import RuntimeService
from server.domain.market.service import MarketDataService
from server.domain.news.service import NewsService
from server.domain.ai.service import AiService
from server.domain.strategy.service import StrategyService, FactorService
from server.domain.backtest.service import BacktestService
from server.domain.risk.service import RiskService
from server.domain.trading.service import BrokerService
from server.domain.settings.service import SettingsService
from server.domain.event.service import EventService
from server.domain.scheduler.service import SchedulerService

from server.shared.schemas.runtime import RuntimeStatusDTO, HealthReportDTO, ServiceInfoDTO
from server.shared.schemas.market import InstrumentDTO, QuoteDTO, BarDTO, BarCacheDTO, IndicatorDTO
from server.shared.schemas.news import NewsItemDTO
from server.shared.schemas.ai import NewsAiAnalysisResultDTO, StrategyAiAnalysisDTO, FactorScoresDTO, AiSignalDTO
from server.shared.schemas.strategy import StrategyDTO, StrategyVersionDTO, FactorDTO, StrategyCreateRequest, StrategyUpdateRequest, FactorEvaluateResult
from server.shared.schemas.backtest import BacktestRunRequest, BacktestRunDTO, BacktestResultDTO, BacktestProgressDTO
from server.shared.schemas.risk import RiskRuleDTO, RiskCheckResultDTO, RiskLogDTO
from server.shared.schemas.trading import AccountDTO, PositionDTO, OrderDTO, ApprovedOrderDTO, OrderIntentDTO
from server.shared.schemas.settings import AppSettingDTO, SecretDTO, PreferenceDTO, SecretCreateRequest
from server.shared.schemas.events import EventRecordDTO, EventQueryRequest
from server.shared.schemas.scheduler import JobSpecDTO


@pytest.fixture(scope="module")
def db():
    # 使用 sqlite 内存数据库，避免测试污染本地开发数据文件
    engine = create_engine("sqlite:///:memory:", connect_args={"check_same_thread": False})
    Base.metadata.create_all(engine)
    SessionClass = sessionmaker(bind=engine)
    session = SessionClass()
    try:
        yield session
    finally:
        session.close()


def test_runtime_service(db):
    service = RuntimeService(db)
    status = service.get_status()
    assert isinstance(status, RuntimeStatusDTO)
    assert status.profile == "dev"
    assert isinstance(status.health, HealthReportDTO)
    
    services = service.list_services()
    assert len(services) > 0
    assert all(isinstance(s, ServiceInfoDTO) for s in services)


def test_market_service(db):
    service = MarketDataService(db)
    instruments = service.search("000001")
    assert isinstance(instruments, list)
    assert len(instruments) > 0
    assert isinstance(instruments[0], InstrumentDTO)

    # 查出的 instrument 已经写进了数据库，我们拿它的真实 id 来查报价
    inst_id = instruments[0].id
    quote = service.get_quote(inst_id)
    assert isinstance(quote, QuoteDTO)
    assert quote.price == 10.5

    bars = service.get_bars(inst_id, "1d")
    assert isinstance(bars, list)
    assert len(bars) > 0
    assert isinstance(bars[0], BarDTO)

    cache = service.cache_bars(inst_id, "1d", "2024-01-01", "2024-01-31")
    assert isinstance(cache, BarCacheDTO)

    indicators = service.compute_indicators(inst_id, "1d")
    assert isinstance(indicators, IndicatorDTO)


def test_news_service(db):
    service = NewsService(db)
    news = service.fetch("eastmoney")
    assert len(news) > 0
    assert isinstance(news[0], NewsItemDTO)

    normalized = service.normalize({"id": "news_raw_1", "title": "Test Title"})
    assert isinstance(normalized, NewsItemDTO)
    assert normalized.title == "Test Title"

    assert service.deduplicate(normalized) is True
    assert service.classify_industry(normalized) == "financial"
    assert service.tag_sentiment(normalized) == "neutral"


def test_ai_service(db):
    service = AiService(db)
    news_analysis = service.analyze_news("news_1")
    assert isinstance(news_analysis, NewsAiAnalysisResultDTO)
    assert news_analysis.sentiment_score == 0.8

    strat_analysis = service.analyze_strategy("strat_1")
    assert isinstance(strat_analysis, StrategyAiAnalysisDTO)

    code = service.write_strategy("trend strategy")
    assert "class" in code

    scores = service.compute_scores("SZ.000001")
    assert isinstance(scores, FactorScoresDTO)

    signal = service.generate_signal("SZ.000001", scores)
    assert isinstance(signal, AiSignalDTO)


def test_strategy_and_factor_service(db):
    strat_service = StrategyService(db)
    fact_service = FactorService(db)

    req = StrategyCreateRequest(name="MyDoubleMA", strategy_type="trend_following", language="python", description="Test", code="class MyDoubleMA:\n    pass", config={})
    strat = strat_service.create_strategy(req)
    assert isinstance(strat, StrategyDTO)
    assert strat.name == "MyDoubleMA"

    # 保存新的版本，最新版本 id 应该被修改
    ver = strat_service.save_code(strat.id, "class MyDoubleMA:\n    pass")
    assert isinstance(ver, StrategyVersionDTO)

    strats = strat_service.list_strategies()
    assert len(strats) > 0
    assert isinstance(strats[0], StrategyDTO)

    factors = fact_service.list_factors()
    assert len(factors) > 0
    assert isinstance(factors[0], FactorDTO)

    eval_res = fact_service.evaluate_factor("factor_ma5")
    assert isinstance(eval_res, FactorEvaluateResult)


def test_backtest_service(db):
    service = BacktestService(db)
    req = BacktestRunRequest(strategy_id="strat_1", strategy_version_id="ver_1", mode="single", market="A股", period="1d", start_time="2024-01-01", end_time="2024-12-31", initial_capital=100000.0)
    run = service.create_run(req)
    assert isinstance(run, BacktestRunDTO)
    assert run.status == "pending"

    detail = service.get_run(run.id)
    assert isinstance(detail, BacktestRunDTO)


def test_risk_service(db):
    service = RiskService(db)
    rules = service.list_rules()
    assert len(rules) > 0
    assert isinstance(rules[0], RiskRuleDTO)

    # 修改规则阈值
    updated = service.update_rule("rule_weight_limit", {"threshold": 0.3})
    assert updated.threshold == 0.3

    intent = OrderIntentDTO(account_id="SIM_ACC", instrument_id="SZ.000001", side="buy", qty=100.0, price=10.5)
    check_result = service.pre_check(intent)
    assert isinstance(check_result, RiskCheckResultDTO)
    assert check_result.passed is True


def test_trading_service(db):
    service = BrokerService(db)
    conn = service.connect("sim_broker")
    assert conn["status"] == "connected"

    acc = service.get_account("SIM_ACC")
    assert isinstance(acc, AccountDTO)

    positions = service.get_positions("SIM_ACC")
    assert len(positions) > 0
    assert isinstance(positions[0], PositionDTO)

    intent = OrderIntentDTO(account_id="SIM_ACC", instrument_id="SZ.000001", side="buy", qty=100.0, price=10.5)
    approved = ApprovedOrderDTO(intent=intent, risk_token="token_123", approved_at=datetime.now().isoformat())
    order = service.place_order(approved)
    assert isinstance(order, OrderDTO)
    assert order.status == "submitted"


def test_settings_service(db):
    service = SettingsService(db)
    setting = service.get_setting("api_port")
    assert isinstance(setting, AppSettingDTO)

    secret = service.get_secret("openai_key")
    assert isinstance(secret, SecretDTO)


def test_event_service(db):
    service = EventService(db)
    req = EventQueryRequest(source="system", topic="info")
    events = service.query(req)
    assert len(events) > 0
    assert isinstance(events[0], EventRecordDTO)

    # Mock Redis Stream emit verification
    from unittest.mock import patch, MagicMock
    with patch("server.shared.redis.streams.get_redis") as mock_get_redis:
        mock_r = MagicMock()
        mock_get_redis.return_value = mock_r
        
        evt = EventRecordDTO(
            id="evt_test_redis_emit",
            source="test_source",
            topic="market_ticks",
            message="Test Redis Tick message"
        )
        service.emit(evt)
        assert mock_r.xadd.called


def test_market_service_redis(db):
    from unittest.mock import patch, MagicMock
    service = MarketDataService(db)
    
    # 1. Quote cached hit
    with patch("server.shared.redis.client.get_redis") as mock_get_redis:
        mock_r = MagicMock()
        mock_r.get.return_value = '{"instrument_id": "000001.SZ", "symbol": "000001.SZ", "name": "平安银行", "price": 12.3, "change": 0.1, "change_pct": 0.01, "volume": 1000, "turnover": 12300.0, "high": 12.5, "low": 12.1, "open": 12.2, "prev_close": 12.2, "timestamp": 1716440000}'
        mock_get_redis.return_value = mock_r
        
        quote = service.get_quote("000001.SZ")
        assert quote.price == 12.3
        assert mock_r.get.called

    # 2. Cache bars lock
    with patch("server.shared.redis.locks.get_redis") as mock_get_redis:
        mock_r = MagicMock()
        mock_r.set.return_value = True  # acquire lock success
        mock_get_redis.return_value = mock_r
        
        res = service.cache_bars("000001.SZ", "1d", "2024-01-01", "2024-01-31")
        assert res.row_count == 100
        assert mock_r.set.called


def test_risk_service_redis(db):
    from unittest.mock import patch, MagicMock
    service = RiskService(db)
    
    # 1. Order concurrency lock hit (first time acquire lock succeeds)
    with patch("server.shared.redis.locks.get_redis") as mock_get_redis:
        mock_r = MagicMock()
        mock_r.set.return_value = True
        mock_get_redis.return_value = mock_r
        
        intent = OrderIntentDTO(account_id="SIM_ACC", instrument_id="SZ.000001", side="buy", qty=100.0, price=10.5, correlation_id="unique_order_123")
        res = service.pre_check(intent)
        assert res.passed is True
        assert mock_r.set.called

    # 2. Concurrency lock fails (r.set returns None)
    with patch("server.shared.redis.locks.get_redis") as mock_get_redis:
        mock_r = MagicMock()
        mock_r.set.return_value = None  # Lock active
        mock_get_redis.return_value = mock_r
        
        intent = OrderIntentDTO(account_id="SIM_ACC", instrument_id="SZ.000001", side="buy", qty=100.0, price=10.5, correlation_id="unique_order_123")
        res = service.pre_check(intent)
        assert res.passed is False
        assert "并发重复订单" in res.message


def test_scheduler_service(db):
    service = SchedulerService(db)
    jobs = service.list_jobs()
    assert len(jobs) > 0
    assert isinstance(jobs[0], JobSpecDTO)

    # Pre-import packages to avoid AttributeError in mock target lookup
    import server.apps.market.runner
    import server.apps.news.runner
    import server.apps.ai.runner

    # Verify Dramatiq tasks can be enqueued from Scheduler
    from unittest.mock import patch
    with patch("server.apps.market.runner.cache_bars_task.send") as mock_market_send, \
         patch("server.apps.news.runner.fetch_news_task.send") as mock_news_send, \
         patch("server.apps.ai.runner.ai_signal_scan_task.send") as mock_ai_send:
         
         service.schedule_market_refresh()
         service.schedule_news_crawl()
         service.schedule_ai_signal_scan()
         
         assert mock_market_send.called
         assert mock_news_send.called
         assert mock_ai_send.called
