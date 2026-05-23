# server/shared/storage/parquet.py
from __future__ import annotations
from pathlib import Path
from datetime import date
import pyarrow as pa
import pyarrow.parquet as pq
import pyarrow.compute as pc
import pandas as pd
from server.shared.config.settings import get_settings


# 定义统一的 K 线 Schema，确保空表和读写时 schema 一致
BAR_SCHEMA = pa.schema([
    ("instrument_id", pa.string()),
    ("period", pa.string()),
    ("open", pa.float64()),
    ("high", pa.float64()),
    ("low", pa.float64()),
    ("close", pa.float64()),
    ("volume", pa.int64()),
    ("turnover", pa.float64()),
    ("timestamp", pa.timestamp("us", tz="Asia/Shanghai")),
    ("year", pa.int32()),
])


def _bar_path(instrument_id: str, period: str, year: int) -> Path:
    s = get_settings()
    return s.parquet_root / instrument_id / period / f"{year}.parquet"


def write_bars(instrument_id: str, period: str, table: pa.Table) -> None:
    """
    写入 K 线数据到对应 Parquet 文件。
    如果文件已存在，追加写入并按 timestamp 去重。
    """
    if len(table) == 0:
        return
    
    # 动态补充 year 字段（如果不存在）
    if "year" not in table.schema.names:
        timestamps = table.column("timestamp")
        # 兼容不同类型的 timestamp
        if pa.types.is_timestamp(timestamps.type) or pa.types.is_date(timestamps.type):
            years_array = pc.year(timestamps)
        else:
            # 兼容字符串格式 timestamp
            years_array = pa.array([pd.to_datetime(t).year for t in timestamps.to_pylist()], type=pa.int32())
        table = table.append_column("year", years_array)

    # 统一 Cast 到标准的 BAR_SCHEMA 以免字段类型不匹配
    try:
        table = table.cast(BAR_SCHEMA)
    except Exception:
        # 如果 cast 失败，尝试以 loose 方式转换
        pass

    # 按年分组写入
    years = table.column("year").to_pylist()
    for year in set(years):
        mask = pc.equal(table.column("year"), year)
        year_table = table.filter(mask)
        path = _bar_path(instrument_id, period, year)
        path.parent.mkdir(parents=True, exist_ok=True)
        
        if path.exists():
            existing = pq.read_table(path)
            combined = pa.concat_tables([existing, year_table])
            
            # 高性能去重：转换为 pandas，并保留最后更新的记录
            df = combined.to_pandas()
            df = df.drop_duplicates(subset=["timestamp"], keep="last")
            df = df.sort_values("timestamp")
            
            combined_deduped = pa.Table.from_pandas(df, schema=combined.schema, preserve_index=False)
            pq.write_table(combined_deduped, path, compression="snappy")
        else:
            # 新写入时先排序
            df = year_table.to_pandas().sort_values("timestamp")
            sorted_table = pa.Table.from_pandas(df, schema=year_table.schema, preserve_index=False)
            pq.write_table(sorted_table, path, compression="snappy")


def read_bars(instrument_id: str, period: str, start: date, end: date) -> pa.Table:
    """读取指定时间范围的 K 线数据。"""
    years = range(start.year, end.year + 1)
    tables = []
    for year in years:
        path = _bar_path(instrument_id, period, year)
        if path.exists():
            tables.append(pq.read_table(path))
    
    if not tables:
        return pa.Table.from_batches([], schema=BAR_SCHEMA)
    
    combined = pa.concat_tables(tables)
    
    # 过滤时间范围
    df = combined.to_pandas()
    # 确保能够安全比较
    ts_col = pd.to_datetime(df["timestamp"]).dt.tz_localize(None)
    start_dt = pd.to_datetime(start).tz_localize(None)
    end_dt = pd.to_datetime(end).tz_localize(None)
    
    mask = (ts_col >= start_dt) & (ts_col <= end_dt)
    filtered_df = df[mask]
    
    return pa.Table.from_pandas(filtered_df, schema=combined.schema, preserve_index=False)
