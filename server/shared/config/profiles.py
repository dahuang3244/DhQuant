from __future__ import annotations
from dataclasses import dataclass
import os
from pathlib import Path

@dataclass(frozen=True)
class ProfileConfig:
    name: str
    sqlite_suffix: str #文件名后缀，比如：_dev, _prod等
    redis_db: int #redis数据库编号

_PROFILES: dict[str, ProfileConfig] = {
    "dev":        ProfileConfig("dev",        "",       0),
    "test":       ProfileConfig("test",       "_test",  1),
    "prod_local": ProfileConfig("prod_local", "_prod",  0),
}


def get_profile(profile_name: str | None = None) -> ProfileConfig:
    """获取环境配置，优先级：参数 > 环境变量 > 默认值(dev)"""
    name = profile_name or os.getenv("DHQUANT_PROFILE", "dev")
    if name not in _PROFILES:
        raise ValueError(f"Unknown profile: {name}, 可选值: {list(_PROFILES.keys())}")
    return _PROFILES[name]
