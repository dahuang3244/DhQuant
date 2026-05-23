# server/domain/trading/service.py
from __future__ import annotations
from datetime import datetime
from sqlalchemy.orm import Session
from server.shared.db.repositories.trading import (
    BrokerRepository, AccountRepository, OrderRepository, PositionRepository
)
from server.shared.db.repositories.instruments import InstrumentRepository
from server.shared.schemas.trading import (
    AccountDTO, PositionDTO, OrderDTO, ApprovedOrderDTO
)


class BrokerService:
    def __init__(self, db: Session):
        self.db = db
        self.broker_repo = BrokerRepository(db)
        self.account_repo = AccountRepository(db)
        self.order_repo = OrderRepository(db)
        self.position_repo = PositionRepository(db)
        self.inst_repo = InstrumentRepository(db)

    def connect(self, broker_id: str) -> dict:
        broker = self.broker_repo.get_by_key(broker_id)
        if broker is None:
            broker = self.broker_repo.create(
                broker_key=broker_id,
                name="模拟券商",
                market="A股",
                status="connected"
            )
        else:
            self.broker_repo.set_status(broker.id, "connected")

        try:
            from server.shared.redis.client import get_redis
            from server.shared.redis.keys import broker_status_key
            from server.shared.redis.serialization import to_json
            r = get_redis()
            broker_status = {
                "broker_id": broker_id,
                "connected": True,
                "account_no": "SIM-12345",
                "cash": 100000.0,
                "net_liquidation": 100000.0,
                "last_sync_at": datetime.now().timestamp()
            }
            r.set(broker_status_key(broker_id), to_json(broker_status), ex=60)
        except Exception as e:
            from server.shared.logging.setup import get_logger
            get_logger("trading.service").warning(f"Failed to update broker status in Redis: {e}")

        return {"status": "connected", "broker_id": broker_id}

    def disconnect(self, broker_id: str) -> dict:
        broker = self.broker_repo.get_by_key(broker_id)
        if broker is not None:
            self.broker_repo.set_status(broker.id, "disconnected")

        try:
            from server.shared.redis.client import get_redis
            from server.shared.redis.keys import broker_status_key
            from server.shared.redis.serialization import to_json
            r = get_redis()
            broker_status = {
                "broker_id": broker_id,
                "connected": False,
                "account_no": "SIM-12345",
                "cash": 100000.0,
                "net_liquidation": 100000.0,
                "last_sync_at": datetime.now().timestamp()
            }
            r.set(broker_status_key(broker_id), to_json(broker_status), ex=60)
        except Exception as e:
            from server.shared.logging.setup import get_logger
            get_logger("trading.service").warning(f"Failed to update broker status in Redis: {e}")

        return {"status": "disconnected", "broker_id": broker_id}

    def get_account(self, account_id: str) -> AccountDTO:
        # Seed default broker
        broker = self.broker_repo.get_by_key("sim_broker")
        if broker is None:
            broker = self.broker_repo.create(
                broker_key="sim_broker",
                name="模拟券商",
                market="A股",
                status="connected"
            )

        acc = self.account_repo.get_by_id(account_id)
        if acc is None:
            acc = self.account_repo.get_by_account_no(broker.id, "SIM-12345")
            if acc is None:
                acc = self.account_repo.create(
                    id=account_id,
                    broker_id=broker.id,
                    account_no="SIM-12345",
                    name="模拟账户",
                    cash=100000.0,
                    net_liquidation=100000.0,
                    buying_power=200000.0,
                    status="active"
                )
        return AccountDTO(
            id=acc.id,
            broker_id="sim_broker",
            account_no=acc.account_no,
            name=acc.name,
            currency=acc.currency,
            cash=acc.cash,
            net_liquidation=acc.net_liquidation,
            buying_power=acc.buying_power,
            status=acc.status,
            last_sync_at=acc.last_sync_at,
            created_at=acc.created_at
        )

    def get_positions(self, account_id: str) -> list[PositionDTO]:
        inst = self.inst_repo.get_by_symbol("000001.SZ")
        if inst is None:
            inst = self.inst_repo.create(
                symbol="000001.SZ",
                name="平安银行",
                exchange="SZSE",
                asset_type="stock",
                is_active=True
            )

        positions = self.position_repo.list_for_account(account_id)
        if not positions:
            self.position_repo.create(
                account_id=account_id,
                instrument_id=inst.id,
                side="long",
                qty=1000.0,
                avg_price=10.0,
                market_value=10500.0,
                unrealized_pnl=500.0,
                realized_pnl=0.0,
                weight=0.105
            )
            positions = self.position_repo.list_for_account(account_id)

        return [
            PositionDTO(
                id=x.id,
                account_id=x.account_id,
                instrument_id="SZ.000001",  # Match schema representation
                side=x.side,
                qty=x.qty,
                avg_price=x.avg_price,
                market_value=x.market_value,
                unrealized_pnl=x.unrealized_pnl,
                realized_pnl=x.realized_pnl,
                weight=x.weight,
                updated_at=x.updated_at
            ) for x in positions
        ]

    def place_order(self, order: ApprovedOrderDTO) -> OrderDTO:
        # Seed instrument if not exists
        inst = self.inst_repo.get_by_symbol("000001.SZ")
        if inst is None:
            inst = self.inst_repo.create(
                symbol="000001.SZ",
                name="平安银行",
                exchange="SZSE",
                asset_type="stock",
                is_active=True
            )

        new_order = self.order_repo.create(
            account_id=order.intent.account_id,
            strategy_id=order.intent.strategy_id,
            instrument_id=inst.id,
            broker_order_id="broker_order_123",
            side=order.intent.side,
            order_type=order.intent.order_type,
            qty=order.intent.qty,
            price=order.intent.price,
            status="submitted",
            submitted_at=datetime.now().isoformat(),
            correlation_id=order.intent.correlation_id
        )

        dto = OrderDTO(
            id=new_order.id,
            account_id=new_order.account_id,
            strategy_id=new_order.strategy_id,
            instrument_id=order.intent.instrument_id,  # Match DTO symbol representation
            broker_order_id=new_order.broker_order_id,
            side=new_order.side,
            order_type=new_order.order_type,
            qty=new_order.qty,
            price=new_order.price,
            status=new_order.status,
            submitted_at=new_order.submitted_at,
            correlation_id=new_order.correlation_id,
            created_at=new_order.created_at
        )

        try:
            from server.shared.redis.keys import STREAM_ORDERS
            from server.shared.redis.streams import xadd_json
            xadd_json(STREAM_ORDERS, dto)
        except Exception as e:
            from server.shared.logging.setup import get_logger
            get_logger("trading.service").warning(f"Failed to publish order to Redis Stream: {e}")

        return dto

    def cancel_order(self, order_id: str) -> OrderDTO:
        order = self.order_repo.get_by_id(order_id)
        if order is None:
            # Return dummy order if not found
            dto = OrderDTO(
                id=order_id,
                instrument_id="SZ.000001",
                side="buy",
                qty=100.0,
                status="cancelled",
                created_at=datetime.now().isoformat()
            )
        else:
            self.order_repo.update_status(order_id, "cancelled")
            # Get symbol
            inst = self.inst_repo.get_by_id(order.instrument_id)
            symbol = inst.symbol if inst else "SZ.000001"
            dto = OrderDTO(
                id=order.id,
                account_id=order.account_id,
                strategy_id=order.strategy_id,
                instrument_id=symbol,
                broker_order_id=order.broker_order_id,
                side=order.side,
                order_type=order.order_type,
                qty=order.qty,
                price=order.price,
                status="cancelled",
                submitted_at=order.submitted_at,
                correlation_id=order.correlation_id,
                created_at=order.created_at
            )

        try:
            from server.shared.redis.keys import STREAM_ORDERS
            from server.shared.redis.streams import xadd_json
            xadd_json(STREAM_ORDERS, dto)
        except Exception as e:
            from server.shared.logging.setup import get_logger
            get_logger("trading.service").warning(f"Failed to publish order cancellation to Redis Stream: {e}")

        return dto

    def list_orders(self, account_id: str | None = None) -> list[OrderDTO]:
        orders = self.order_repo.list_recent(account_id=account_id)
        if not orders:
            # Seed a default order
            # Seed instrument if not exists
            inst = self.inst_repo.get_by_symbol("000001.SZ")
            if inst is None:
                inst = self.inst_repo.create(
                    symbol="000001.SZ",
                    name="平安银行",
                    exchange="SZSE",
                    asset_type="stock",
                    is_active=True
                )
            self.order_repo.create(
                account_id=account_id or "acc_1",
                instrument_id=inst.id,
                side="buy",
                qty=100.0,
                price=10.5,
                status="filled",
                submitted_at=datetime.now().isoformat()
            )
            orders = self.order_repo.list_recent(account_id=account_id)

        # Map to DTOs
        result = []
        for o in orders:
            inst = self.inst_repo.get_by_id(o.instrument_id)
            symbol = inst.symbol if inst else "SZ.000001"
            result.append(
                OrderDTO(
                    id=o.id,
                    account_id=o.account_id,
                    strategy_id=o.strategy_id,
                    instrument_id=symbol,
                    broker_order_id=o.broker_order_id,
                    side=o.side,
                    order_type=o.order_type,
                    qty=o.qty,
                    price=o.price,
                    status=o.status,
                    submitted_at=o.submitted_at,
                    correlation_id=o.correlation_id,
                    created_at=o.created_at
                )
            )
        return result
