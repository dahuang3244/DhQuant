# server/shared/redis/serialization.py
from __future__ import annotations
import json
from datetime import datetime, date
from typing import Any
from pydantic import BaseModel


class _ExtendedEncoder(json.JSONEncoder):
    def default(self, obj: Any) -> Any:
        if isinstance(obj, datetime):
            return {"__type__": "datetime", "value": obj.isoformat()}
        if isinstance(obj, date):
            return {"__type__": "date", "value": obj.isoformat()}
        if isinstance(obj, BaseModel):
            return obj.model_dump()
        return super().default(obj)


def _object_hook(d: dict) -> Any:
    if "__type__" in d:
        if d["__type__"] == "datetime":
            return datetime.fromisoformat(d["value"])
        if d["__type__"] == "date":
            return date.fromisoformat(d["value"])
    return d


def to_json(obj: Any) -> str:
    return json.dumps(obj, cls=_ExtendedEncoder, ensure_ascii=False)


def from_json(s: str) -> Any:
    return json.loads(s, object_hook=_object_hook)
