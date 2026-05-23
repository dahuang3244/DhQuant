# server/apps/api/routes/market.py
from __future__ import annotations
from fastapi import APIRouter, Depends, Query
from server.apps.api.dependencies import get_market_service
from server.domain.market.service import MarketDataService
from server.shared.schemas.market import InstrumentDTO, QuoteDTO, BarDTO, BarCacheDTO, IndicatorDTO

router = APIRouter(prefix="/market", tags=["market"])


@router.get("/search", response_model=list[InstrumentDTO])
def search_instruments(
    query: str,
    market: str | None = None,
    market_service: MarketDataService = Depends(get_market_service)
):
    """搜索交易标的。"""
    return market_service.search(query, market)


@router.get("/quote/{instrument_id}", response_model=QuoteDTO)
def get_instrument_quote(
    instrument_id: str,
    market_service: MarketDataService = Depends(get_market_service)
):
    """获取指定标的的实时行情。"""
    return market_service.get_quote(instrument_id)


@router.get("/bars/{instrument_id}", response_model=list[BarDTO])
def get_instrument_bars(
    instrument_id: str,
    period: str = "1d",
    start: str | None = None,
    end: str | None = None,
    limit: int | None = 100,
    market_service: MarketDataService = Depends(get_market_service)
):
    """获取 K 线历史数据。"""
    return market_service.get_bars(instrument_id, period, start, end, limit)


@router.post("/cache-bars", response_model=BarCacheDTO)
def cache_instrument_bars(
    instrument_id: str,
    period: str,
    start: str,
    end: str,
    market_service: MarketDataService = Depends(get_market_service)
):
    """下载并缓存指定范围的 K 线数据。"""
    return market_service.cache_bars(instrument_id, period, start, end)


@router.get("/indicators/{instrument_id}", response_model=IndicatorDTO)
def get_technical_indicators(
    instrument_id: str,
    period: str = "1d",
    market_service: MarketDataService = Depends(get_market_service)
):
    """计算标的的技术指标 (MA, MACD, RSI)。"""
    return market_service.compute_indicators(instrument_id, period)
