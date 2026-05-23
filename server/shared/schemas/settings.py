# server/shared/schemas/settings.py
from __future__ import annotations
from pydantic import BaseModel, Field


class AppSettingDTO(BaseModel):
    id: str
    key: str
    value: str
    value_type: str = "string"  # string/int/float/bool/json
    description: str | None = None
    created_at: str | None = None
    updated_at: str | None = None


class SecretDTO(BaseModel):
    id: str
    name: str
    provider: str  # ai / broker / datasource
    created_at: str | None = None
    updated_at: str | None = None


class PreferenceDTO(BaseModel):
    id: str
    namespace: str = "global"
    key: str
    value: str
    value_type: str = "string"
    created_at: str | None = None
    updated_at: str | None = None


class SecretCreateRequest(BaseModel):
    name: str
    value: str  # 传入明文，由 Service 写入时自动加密
    provider: str
