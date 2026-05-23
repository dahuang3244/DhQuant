# server/shared/schemas/common.py
from __future__ import annotations
from typing import Generic, TypeVar, Any
from datetime import datetime
from pydantic import BaseModel, Field

T = TypeVar("T")


class ApiResponse(BaseModel, Generic[T]):
    """
    所有 API 的统一返回格式。
    
    成功：ApiResponse(success=True, data=<结果>)
    失败：ApiResponse(success=False, error=ErrorResponse(...))
    """
    success: bool
    data: T | None = None
    error: ErrorResponse | None = None
    request_id: str | None = None


class ErrorResponse(BaseModel):
    code: str          # 错误码，如 "INSTRUMENT_NOT_FOUND"
    message: str       # 人读的错误信息
    detail: Any = None # 可选的调试信息


class PageRequest(BaseModel):
    page: int = Field(default=1, ge=1)
    page_size: int = Field(default=20, ge=1, le=200)


class PageResult(BaseModel, Generic[T]):
    items: list[T]
    total: int
    page: int
    page_size: int
    has_more: bool


class TimeRange(BaseModel):
    start: datetime
    end: datetime
