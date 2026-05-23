# server/domain/market/service.py
from __future__ import annotations
from datetime import datetime
from server.shared.schemas.market import InstrumentDTO, QuoteDTO, BarDTO, BarCacheDTO, IndicatorDTO

class MarketDataService:
    def search(self, query: str, market: str | None = None) -> list[InstrumentDTO]:
        return [
            InstrumentDTO(id="SH.000001", symbol="000001.SH", name="上证指数", exchange="SSE", asset_type="index"),
            InstrumentDTO(id="SZ.000001", symbol="000001.SZ", name="平安银行", exchange="SZSE", asset_type="stock"),
        ]

    def get_quote(self, instrument_id: str) -> QuoteDTO:
        return QuoteDTO(
            instrument_id=instrument_id,
            symbol="000001.SZ",
            name="平安银行",
            price=10.5,
            change=0.1,
            change_pct=0.0096,
            volume=10000,
            turnover=105000.0,
            high=10.6,
            low=10.4,
            open=10.4,
            prev_close=10.4,
            timestamp=datetime.now()
        )

    def get_bars(self, instrument_id: str, period: str, start: str | None = None, end: str | None = None, limit: int | None = None) -> list[BarDTO]:
        return [
            BarDTO(
                instrument_id=instrument_id,
                period=period,
                open=10.4,
                high=10.6,
                low=10.4,
                close=10.5,
                volume=10000,
                turnover=105000.0,
                timestamp=datetime.now()
            )
        ]

    def cache_bars(self, instrument_id: str, period: str, start: str, end: str) -> BarCacheDTO:
        return BarCacheDTO(
            id="cache_1",
            instrument_id=instrument_id,
            period=period,
            start_time=start,
            end_time=end,
            source="mock",
            storage_path=f"data/parquet/{instrument_id}_{period}.parquet",
            row_count=1
        )

    def compute_indicators(self, instrument_id: str, period: str) -> IndicatorDTO:
        return IndicatorDTO(
            instrument_id=instrument_id,
            period=period,
            ma5=10.5,
            ma10=10.48,
            ma20=10.45,
            macd=0.02,
            macd_signal=0.01,
            rsi14=55.0,
            calculated_at=datetime.now()
        )
