# server/shared/storage/duckdb.py
from __future__ import annotations
from pathlib import Path
import duckdb
from server.shared.config.settings import get_settings


def get_duckdb() -> duckdb.DuckDBPyConnection:
    """返回 DuckDB 连接（用完自己关）。"""
    s = get_settings()
    s.duckdb_path.parent.mkdir(parents=True, exist_ok=True)
    return duckdb.connect(str(s.duckdb_path))


def query_bars(instrument_id: str, period: str, sql: str) -> list[dict]:
    """
    用 DuckDB 直接查询 Parquet 文件。
    sql 里可以用 {parquet_path} 占位符引用 Parquet 文件。
    
    示例 sql：
        SELECT date_trunc('month', timestamp) AS month, AVG(close) AS avg_close
        FROM '{parquet_path}'
        GROUP BY 1 ORDER BY 1
    """
    s = get_settings()
    dir_path = s.parquet_root / instrument_id / period
    
    # 鲁棒性检查：如果目录不存在，或者目录下没有任何 parquet 文件，直接返回空列表
    if not dir_path.exists() or not any(dir_path.glob("*.parquet")):
        return []
        
    parquet_glob = str(dir_path / "*.parquet")
    
    with get_duckdb() as conn:
        try:
            result = conn.execute(
                sql.replace("{parquet_path}", parquet_glob)
            ).fetchall()
            columns = [desc[0] for desc in conn.description]
            return [dict(zip(columns, row)) for row in result]
        except Exception:
            # 捕获可能的查询错误并优雅返回空列表
            return []
