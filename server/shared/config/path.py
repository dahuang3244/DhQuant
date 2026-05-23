from __future__ import annotations
from pathlib import Path
from .settings import get_settings, Settings

def ensure_dirs(s: Settings) -> None:
    """确保所有路径存在，必要时创建"""
    dirs = [
        s.sqlite_path.parent, #sqlite文件所在目录
        s.parquet_root,      #parquet文件所在目录
        s.duckdb_path.parent,#duckdb文件所在目录
        s.log_dir,          #日志文件所在目录
    ]
    for d in dirs:
        if not d.exists():
            d.mkdir(parents=True, exist_ok=True)


def resolve_project_path(relative: str | Path, settings: Settings) -> Path:
    """将相对路径解析为绝对路径"""
    return settings.project_root / relative
