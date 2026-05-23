from __future__ import annotations

from typing import Generic, Optional, Type, TypeVar

from sqlalchemy import Select, func, select
from sqlalchemy.orm import Session

from server.shared.db.base import Base


ModelT = TypeVar("ModelT", bound=Base)


class BaseRepository(Generic[ModelT]):
    """Common CRUD helper.

    Repository methods flush but never commit. Transaction ownership stays with
    server.shared.db.session.get_session().
    """

    def __init__(self, model: Type[ModelT], session: Session):
        self.model = model
        self.session = session

    def get_by_id(self, id: str) -> Optional[ModelT]:
        return self.session.get(self.model, id)

    def list(
        self,
        *,
        limit: int = 100,
        offset: int = 0,
        order_by=None,
    ) -> list[ModelT]:
        stmt: Select = select(self.model)
        if order_by is not None:
            stmt = stmt.order_by(order_by)
        stmt = stmt.limit(limit).offset(offset)
        return list(self.session.scalars(stmt).all())

    def count(self) -> int:
        stmt = select(func.count()).select_from(self.model)
        return int(self.session.scalar(stmt) or 0)

    def create(self, **values) -> ModelT:
        self._validate_fields(values)
        obj = self.model(**values)
        self.session.add(obj)
        self.session.flush()
        return obj

    def update(self, id: str, **values) -> Optional[ModelT]:
        self._validate_fields(values)
        obj = self.get_by_id(id)
        if obj is None:
            return None
        for key, value in values.items():
            setattr(obj, key, value)
        self.session.flush()
        return obj

    def delete(self, id: str) -> bool:
        obj = self.get_by_id(id)
        if obj is None:
            return False
        self.session.delete(obj)
        self.session.flush()
        return True

    def require(self, id: str) -> ModelT:
        obj = self.get_by_id(id)
        if obj is None:
            raise LookupError(f"{self.model.__name__} not found: {id}")
        return obj

    def _validate_fields(self, values: dict) -> None:
        valid = set(self.model.__mapper__.attrs.keys())
        unknown = sorted(set(values) - valid)
        if unknown:
            fields = ", ".join(unknown)
            raise ValueError(f"Unknown field(s) for {self.model.__name__}: {fields}")
