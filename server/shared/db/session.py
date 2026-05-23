from __future__ import annotations
from contextlib import contextmanager
from typing import Generator

from sqlalchemy import create_engine,event,text
from sqlalchemy.orm import Session, sessionmaker

from server.shared.config.settings import get_settings

def _make_engine():
    s= get_settings()
    engine = create_engine(
        f"sqlite:///{s.sqlite_path}",
        connect_args={"check_same_thread": False},
        echo=False,
    )

    # 确保启用 WAL 模式以支持并发访问
    @event.listens_for(engine, "connect")
    def set_sqlite_pragma(dbapi_connection, connection_record):
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA journal_mode=WAL;")
        cursor.execute("PRAGMA foreign_keys=ON;")
        cursor.close()

    return engine

engine = _make_engine()
SessionLocal = sessionmaker(bind=engine, autocommit=False, autoflush=False)

@contextmanager
def get_session() -> Generator[Session, None, None]:
    session = SessionLocal()
    try:
        yield session
        session.commit()
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()


def ping_db() -> bool:
    try:
        with get_session() as session:
            session.execute(text("SELECT 1"))
        return True
    except Exception:
        return False