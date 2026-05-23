# server/domain/trading/service.py
from __future__ import annotations
from datetime import datetime
from server.shared.schemas.trading import (
    AccountDTO, PositionDTO, OrderDTO, ApprovedOrderDTO
)

class BrokerService:
    def connect(self, broker_id: str) -> dict:
        return {"status": "connected", "broker_id": broker_id}

    def disconnect(self, broker_id: str) -> dict:
        return {"status": "disconnected", "broker_id": broker_id}

    def get_account(self, account_id: str) -> AccountDTO:
        return AccountDTO(
            id=account_id,
            broker_id="sim_broker",
            account_no="SIM-12345",
            name="模拟账户",
            cash=100000.0,
            net_liquidation=100000.0,
            buying_power=200000.0,
            status="active",
            last_sync_at=datetime.now().isoformat()
        )

    def get_positions(self, account_id: str) -> list[PositionDTO]:
        return [
            PositionDTO(
                id="pos_1",
                account_id=account_id,
                instrument_id="SZ.000001",
                side="long",
                qty=1000.0,
                avg_price=10.0,
                market_value=10500.0,
                unrealized_pnl=500.0,
                realized_pnl=0.0,
                weight=0.105,
                updated_at=datetime.now().isoformat()
            )
        ]

    def place_order(self, order: ApprovedOrderDTO) -> OrderDTO:
        return OrderDTO(
            id="order_1",
            account_id=order.intent.account_id,
            strategy_id=order.intent.strategy_id,
            instrument_id=order.intent.instrument_id,
            broker_order_id="broker_order_123",
            side=order.intent.side,
            order_type=order.intent.order_type,
            qty=order.intent.qty,
            price=order.intent.price,
            status="submitted",
            submitted_at=datetime.now().isoformat(),
            correlation_id=order.intent.correlation_id,
            created_at=datetime.now().isoformat()
        )

    def cancel_order(self, order_id: str) -> OrderDTO:
        return OrderDTO(
            id=order_id,
            instrument_id="SZ.000001",
            side="buy",
            qty=100.0,
            status="cancelled",
            created_at=datetime.now().isoformat()
        )

    def list_orders(self, account_id: str | None = None) -> list[OrderDTO]:
        return [
            OrderDTO(
                id="order_1",
                account_id=account_id or "acc_1",
                instrument_id="SZ.000001",
                side="buy",
                qty=100.0,
                price=10.5,
                status="filled",
                submitted_at=datetime.now().isoformat(),
                created_at=datetime.now().isoformat()
            )
        ]
