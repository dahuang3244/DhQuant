# server/apps/api/routes/settings.py
from __future__ import annotations
from fastapi import APIRouter, Depends
from server.apps.api.dependencies import get_settings_service
from server.domain.settings.service import SettingsService
from server.shared.schemas.settings import (
    AppSettingDTO, SecretDTO, PreferenceDTO, SecretCreateRequest
)

router = APIRouter(prefix="/settings", tags=["settings"])


@router.get("", response_model=list[AppSettingDTO])
def list_settings(settings_service: SettingsService = Depends(get_settings_service)):
    """列出当前所有系统通用配置项。"""
    return [settings_service.get_setting("datasource.token")]


@router.post("", response_model=AppSettingDTO)
def update_setting(
    key: str,
    value: str,
    settings_service: SettingsService = Depends(get_settings_service)
):
    """更改或保存系统通用配置项的值。"""
    return settings_service.update_setting(key, value)


@router.get("/secrets", response_model=list[SecretDTO])
def list_secrets(settings_service: SettingsService = Depends(get_settings_service)):
    """获取外部系统连接凭证列表（加密存储，不显示密文）。"""
    return [settings_service.get_secret("openai_api_key")]


@router.post("/secrets", response_model=SecretDTO)
def save_secret_credential(
    request: SecretCreateRequest,
    settings_service: SettingsService = Depends(get_settings_service)
):
    """加密保存第三方 API Key 或 Broker 登录凭证。"""
    return settings_service.save_secret(request)


@router.get("/preferences", response_model=PreferenceDTO)
def get_user_preference(
    key: str,
    namespace: str = "global",
    settings_service: SettingsService = Depends(get_settings_service)
):
    """获取用户界面偏好配置。"""
    return settings_service.get_preference(namespace, key)


@router.post("/preferences", response_model=PreferenceDTO)
def save_user_preference(
    key: str,
    value: str,
    namespace: str = "global",
    settings_service: SettingsService = Depends(get_settings_service)
):
    """保存用户界面偏好配置。"""
    return settings_service.save_preference(namespace, key, value)
