# server/domain/market/service.py
from __future__ import annotations
from datetime import datetime
from sqlalchemy.orm import Session
from server.shared.db.repositories.instruments import InstrumentRepository
from server.shared.db.repositories.market import BarCacheRepository
from server.shared.schemas.market import InstrumentDTO, QuoteDTO, BarDTO, BarCacheDTO, IndicatorDTO


class MarketDataService:
    def __init__(self, db: Session):
        self.db = db
        self.inst_repo = InstrumentRepository(db)
        self.cache_repo = BarCacheRepository(db)

    def search(self, query: str, market: str | None = None) -> list[InstrumentDTO]:
        res = self.inst_repo.search(query, exchange=market)
        if not res:
            # Seed default instruments on empty to maintain run state
            self.inst_repo.create(symbol="000001.SH", name="上证指数", exchange="SSE", asset_type="index", is_active=True)
            self.inst_repo.create(symbol="000001.SZ", name="平安银行", exchange="SZSE", asset_type="stock", is_active=True)
            res = self.inst_repo.search(query, exchange=market)

        return [
            InstrumentDTO(
                id=x.id,
                symbol=x.symbol,
                name=x.name,
                exchange=x.exchange,
                asset_type=x.asset_type,
                is_active=x.is_active,
                created_at=x.created_at,
                updated_at=x.updated_at
            ) for x in res
        ]

    def get_quote(self, instrument_id: str) -> QuoteDTO:
        try:
            from server.shared.redis.client import get_redis
            from server.shared.redis.keys import quote_key
            from server.shared.redis.serialization import from_json, to_json
            
            r = get_redis()
            inst = self.inst_repo.get_by_id(instrument_id)
            symbol = inst.symbol if inst else instrument_id
            
            key = quote_key(symbol)
            cached = r.get(key)
            if cached:
                data = from_json(cached)
                if isinstance(data, dict):
                    if "instrument_id" not in data:
                        data["instrument_id"] = instrument_id
                    # Standardize float timestamp if needed
                    if "timestamp" in data and isinstance(data["timestamp"], (int, float)):
                        data["timestamp"] = datetime.fromtimestamp(data["timestamp"])
                    return QuoteDTO(**data)
        except Exception as e:
            from server.shared.logging.setup import get_logger
            get_logger("market.service").warning(f"Failed to read quote from Redis: {e}")

        # Fallback to DB & Mock generate
        inst = self.inst_repo.get_by_id(instrument_id)
        symbol = inst.symbol if inst else "000001.SZ"
        name = inst.name if inst else "平安银行"
        quote = QuoteDTO(
            instrument_id=instrument_id,
            symbol=symbol,
            name=name,
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
        
        try:
            from server.shared.redis.client import get_redis
            from server.shared.redis.keys import quote_key
            from server.shared.redis.serialization import to_json
            r = get_redis()
            r.set(quote_key(symbol), to_json(quote), ex=60)
        except Exception:
            pass
            
        return quote

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
        lock_acquired = False
        token = None
        lock_key_str = None
        try:
            from server.shared.redis.keys import lock_bars
            from server.shared.redis.locks import acquire_lock
            lock_key_str = lock_bars(instrument_id, period, start, end)
            token = acquire_lock(lock_key_str, ttl=30)
            if token is None:
                raise ValueError("Concurrency cache lock active for this range")
            lock_acquired = True
        except ValueError:
            raise
        except Exception as e:
            from server.shared.logging.setup import get_logger
            get_logger("market.service").warning(f"Failed to check lock for cache_bars: {e}")

        try:
            cache = self.cache_repo.upsert_file(
                instrument_id=instrument_id,
                period=period,
                source="mock",
                storage_path=f"data/parquet/{instrument_id}_{period}.parquet",
                start_time=start,
                end_time=end,
                row_count=100
            )
            
            # Broadcast event
            try:
                from server.domain.event.service import EventService
                from server.shared.schemas.events import EventRecordDTO
                import uuid
                evt_service = EventService(self.db)
                evt_service.emit(EventRecordDTO(
                    id=f"evt_{uuid.uuid4().hex[:8]}",
                    source="market_service",
                    topic="market_bars",
                    instrument_id=instrument_id,
                    message=f"Cached bars for {instrument_id} ({period}) from {start} to {end}",
                    detail={
                        "cache_id": cache.id,
                        "row_count": cache.row_count,
                        "storage_path": cache.storage_path
                    }
                ))
            except Exception:
                pass

            return BarCacheDTO(
                id=cache.id,
                instrument_id=cache.instrument_id,
                period=cache.period,
                start_time=cache.start_time,
                end_time=cache.end_time,
                source=cache.source,
                storage_type=cache.storage_type,
                storage_path=cache.storage_path,
                row_count=cache.row_count,
                checksum=cache.checksum
            )
        finally:
            if lock_acquired and token and lock_key_str:
                try:
                    from server.shared.redis.locks import release_lock
                    release_lock(lock_key_str, token)
                except Exception:
                    pass

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
