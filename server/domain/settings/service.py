# server/domain/settings/service.py
from __future__ import annotations
from datetime import datetime
from server.shared.schemas.settings import (
    AppSettingDTO, SecretDTO, PreferenceDTO, SecretCreateRequest
)

class SettingsService:
    def get_setting(self, key: str) -> AppSettingDTO:
        return AppSettingDTO(
            id="setting_1",
            key=key,
            value="default_val",
            description="Mock setting"
        )

    def update_setting(self, key: str, value: str) -> AppSettingDTO:
        return AppSettingDTO(
            id="setting_1",
            key=key,
            value=value,
            description="Mock setting updated"
        )

    def get_secret(self, name: str) -> SecretDTO:
        return SecretDTO(
            id="sec_1",
            name=name,
            provider="ai",
            created_at=datetime.now().isoformat()
        )

    def save_secret(self, request: SecretCreateRequest) -> SecretDTO:
        return SecretDTO(
            id="sec_1",
            name=request.name,
            provider=request.provider,
            created_at=datetime.now().isoformat()
        )

    def get_preference(self, namespace: str, key: str) -> PreferenceDTO:
        return PreferenceDTO(
            id="pref_1",
            namespace=namespace,
            key=key,
            value="pref_val"
        )

    def save_preference(self, namespace: str, key: str, value: str) -> PreferenceDTO:
        return PreferenceDTO(
            id="pref_1",
            namespace=namespace,
            key=key,
            value=value
        )
