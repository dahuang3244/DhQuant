from __future__ import annotations

from typing import Optional

from sqlalchemy import select
from sqlalchemy.orm import Session

from server.shared.db.models import AppSetting, Preference, Secret
from server.shared.db.repositories.base import BaseRepository


class AppSettingRepository(BaseRepository[AppSetting]):
    def __init__(self, session: Session):
        super().__init__(AppSetting, session)

    def get_by_key(self, key: str) -> Optional[AppSetting]:
        stmt = select(AppSetting).where(AppSetting.key == key)
        return self.session.scalar(stmt)

    def set_value(
        self,
        key: str,
        value: str,
        *,
        value_type: str = "string",
        description: str = "",
    ) -> AppSetting:
        obj = self.get_by_key(key)
        if obj is None:
            return self.create(
                key=key,
                value=value,
                value_type=value_type,
                description=description,
            )
        obj.value = value
        obj.value_type = value_type
        if description:
            obj.description = description
        self.session.flush()
        return obj


class SecretRepository(BaseRepository[Secret]):
    def __init__(self, session: Session):
        super().__init__(Secret, session)

    def get_by_name(self, name: str) -> Optional[Secret]:
        stmt = select(Secret).where(Secret.name == name)
        return self.session.scalar(stmt)

    def list_by_provider(self, provider: str) -> list[Secret]:
        stmt = select(Secret).where(Secret.provider == provider).order_by(Secret.name)
        return list(self.session.scalars(stmt).all())

    def upsert_encrypted(self, name: str, encrypted_value: str, provider: str) -> Secret:
        obj = self.get_by_name(name)
        if obj is None:
            return self.create(name=name, encrypted_value=encrypted_value, provider=provider)
        obj.encrypted_value = encrypted_value
        obj.provider = provider
        self.session.flush()
        return obj


class PreferenceRepository(BaseRepository[Preference]):
    def __init__(self, session: Session):
        super().__init__(Preference, session)

    def get_by_key(self, key: str, *, namespace: str = "global") -> Optional[Preference]:
        stmt = select(Preference).where(
            Preference.namespace == namespace,
            Preference.key == key,
        )
        return self.session.scalar(stmt)

    def set_value(
        self,
        key: str,
        value: str,
        *,
        namespace: str = "global",
        value_type: str = "string",
    ) -> Preference:
        obj = self.get_by_key(key, namespace=namespace)
        if obj is None:
            return self.create(
                namespace=namespace,
                key=key,
                value=value,
                value_type=value_type,
            )
        obj.value = value
        obj.value_type = value_type
        self.session.flush()
        return obj

    def list_namespace(self, namespace: str) -> list[Preference]:
        stmt = select(Preference).where(Preference.namespace == namespace).order_by(Preference.key)
        return list(self.session.scalars(stmt).all())
