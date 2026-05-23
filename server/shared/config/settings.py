from __future__ import annotations

import os
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path
from .profiles import get_profile


def _project_root() -> Path:
    return Path(__file__).resolve().parents[3]


@dataclass(frozen=True)
class Settings:
    project_root: Path
    api_host: str
    api_port: int
    redis_url: str
    sqlite_path: Path
    parquet_root: Path
    duckdb_path: Path
    log_dir: Path

    @property
    def api_base_url(self) -> str:
        return f"http://{self.api_host}:{self.api_port}"


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    root = _project_root()
    profile = get_profile()
    return Settings(
        project_root=root,
        api_host=os.getenv("DHQUANT_API_HOST", "127.0.0.1"),
        api_port=int(os.getenv("DHQUANT_API_PORT", "8765")),
        redis_url=os.getenv(
            "DHQUANT_REDIS_URL",
            f"redis://127.0.0.1:6379/{profile.redis_db}",
        ),
        sqlite_path=root / os.getenv(
            "DHQUANT_SQLITE_PATH",
            f"data/dhquant{profile.sqlite_suffix}.sqlite3",
        ),
        parquet_root=root / os.getenv("DHQUANT_PARQUET_ROOT", "data/parquet"),
        duckdb_path=root / os.getenv("DHQUANT_DUCKDB_PATH", "data/duckdb/dhquant.duckdb"),
        log_dir=root / os.getenv("DHQUANT_LOG_DIR", "logs"),
    )


