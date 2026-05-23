from __future__ import annotations

from typing import Optional

from sqlalchemy import desc, select
from sqlalchemy.orm import Session

from server.shared.db.models import Account, Broker, Fill, Order, Position
from server.shared.db.repositories.base import BaseRepository


class BrokerRepository(BaseRepository[Broker]):
    def __init__(self, session: Session):
        super().__init__(Broker, session)

    def get_by_key(self, broker_key: str) -> Optional[Broker]:
        stmt = select(Broker).where(Broker.broker_key == broker_key)
        return self.session.scalar(stmt)

    def set_status(self, broker_id: str, status: str) -> Optional[Broker]:
        return self.update(broker_id, status=status)


class AccountRepository(BaseRepository[Account]):
    def __init__(self, session: Session):
        super().__init__(Account, session)

    def get_by_account_no(self, broker_id: str, account_no: str) -> Optional[Account]:
        stmt = select(Account).where(
            Account.broker_id == broker_id,
            Account.account_no == account_no,
        )
        return self.session.scalar(stmt)

    def list_by_broker(self, broker_id: str) -> list[Account]:
        stmt = select(Account).where(Account.broker_id == broker_id).order_by(Account.account_no)
        return list(self.session.scalars(stmt).all())


class OrderRepository(BaseRepository[Order]):
    def __init__(self, session: Session):
        super().__init__(Order, session)

    def get_by_broker_order_id(self, broker_order_id: str) -> Optional[Order]:
        stmt = select(Order).where(Order.broker_order_id == broker_order_id)
        return self.session.scalar(stmt)

    def list_recent(
        self,
        *,
        account_id: str | None = None,
        status: str | None = None,
        limit: int = 100,
    ) -> list[Order]:
        stmt = select(Order)
        if account_id:
            stmt = stmt.where(Order.account_id == account_id)
        if status:
            stmt = stmt.where(Order.status == status)
        stmt = stmt.order_by(desc(Order.created_at)).limit(limit)
        return list(self.session.scalars(stmt).all())

    def update_status(self, order_id: str, status: str, **values) -> Optional[Order]:
        values["status"] = status
        return self.update(order_id, **values)


class FillRepository(BaseRepository[Fill]):
    def __init__(self, session: Session):
        super().__init__(Fill, session)

    def list_for_order(self, order_id: str) -> list[Fill]:
        stmt = select(Fill).where(Fill.order_id == order_id).order_by(Fill.filled_at)
        return list(self.session.scalars(stmt).all())

    def list_recent(self, *, instrument_id: str | None = None, limit: int = 100) -> list[Fill]:
        stmt = select(Fill)
        if instrument_id:
            stmt = stmt.where(Fill.instrument_id == instrument_id)
        stmt = stmt.order_by(desc(Fill.filled_at)).limit(limit)
        return list(self.session.scalars(stmt).all())


class PositionRepository(BaseRepository[Position]):
    def __init__(self, session: Session):
        super().__init__(Position, session)

    def get_position(self, account_id: str, instrument_id: str) -> Optional[Position]:
        stmt = select(Position).where(
            Position.account_id == account_id,
            Position.instrument_id == instrument_id,
        )
        return self.session.scalar(stmt)

    def list_for_account(self, account_id: str) -> list[Position]:
        stmt = select(Position).where(Position.account_id == account_id).order_by(Position.instrument_id)
        return list(self.session.scalars(stmt).all())

    def upsert_position(self, account_id: str, instrument_id: str, **values) -> Position:
        obj = self.get_position(account_id, instrument_id)
        if obj is None:
            return self.create(account_id=account_id, instrument_id=instrument_id, **values)
        self._validate_fields(values)
        for key, value in values.items():
            setattr(obj, key, value)
        self.session.flush()
        return obj
