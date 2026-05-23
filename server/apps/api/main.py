# server/apps/api/main.py
from __future__ import annotations
from contextlib import asynccontextmanager
import threading
import time
import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from server.shared.config.settings import get_settings
from server.shared.logging.setup import setup_logging, get_logger
from server.shared.redis.heartbeat import write_heartbeat
from server.apps.api.routes import api_router
from server.apps.api.websocket import router as ws_router

logger = get_logger("api.main")

# 全局退出标志，用于停止心跳线程
_stop_event = threading.Event()


def _heartbeat_loop():
    """定期上报 API 进程自身心跳的后台线程。"""
    while not _stop_event.is_set():
        try:
            write_heartbeat("api")
        except Exception as e:
            logger.warn(f"Failed to write API heartbeat: {e}")
        # 每 5 秒写一次心跳
        _stop_event.wait(5.0)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # ── 启动初始化 ──────────────────────────────────────────────────────────
    logger.info("Starting DhQuant API Server...")
    
    # 启动后台心跳上报线程
    _stop_event.clear()
    t = threading.Thread(target=_heartbeat_loop, name="api_heartbeat", daemon=True)
    t.start()
    
    yield
    
    # ── 关闭清理 ──────────────────────────────────────────────────────────
    logger.info("Shutting down DhQuant API Server...")
    _stop_event.set()
    t.join(timeout=2.0)


def create_app() -> FastAPI:
    s = get_settings()
    setup_logging("api", s.log_dir)

    app = FastAPI(
        title="DhQuant API Gateway",
        description="DhQuant 个人量化系统服务端控制网关",
        version="1.0.0",
        lifespan=lifespan
    )

    # 跨域配置
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # 注册路由
    app.include_router(api_router)
    app.include_router(ws_router)

    return app


app = create_app()

if __name__ == "__main__":
    s = get_settings()
    uvicorn.run(
        "server.apps.api.main:app",
        host=s.api_host,
        port=s.api_port,
        reload=True
    )
