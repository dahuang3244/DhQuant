# server/apps/api/websocket.py
from __future__ import annotations
import asyncio
import json
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
import redis

from server.apps.api.dependencies import get_redis_client
from server.shared.logging.setup import get_logger

logger = get_logger("api.websocket")
router = APIRouter()


@router.websocket("/stream")
async def websocket_endpoint(websocket: WebSocket, r: redis.Redis = Depends(get_redis_client)):
    """实时事件推送 WebSocket 通道。"""
    await websocket.accept()
    logger.info("WebSocket connection accepted.")

    pubsub = r.pubsub()
    channels = [
        "channel:market", "channel:news", "channel:ai", 
        "channel:backtest", "channel:risk", "channel:orders", "channel:system"
    ]
    pubsub.subscribe(*channels)

    async def send_keep_alive():
        while True:
            try:
                await websocket.send_json({"type": "ping", "message": "keep-alive"})
                await asyncio.sleep(15)
            except Exception:
                break

    # 启动心跳协程
    keep_alive_task = asyncio.create_task(send_keep_alive())

    try:
        while True:
            # 1. 尝试从 Redis PubSub 获取消息并推送到客户端
            # 使用 get_message 轮询，避免阻塞导致无法检测客户端断开
            msg = pubsub.get_message(ignore_subscribe_messages=True, timeout=0.05)
            if msg:
                channel = msg["channel"]
                raw_data = msg["data"]
                try:
                    data = json.loads(raw_data) if isinstance(raw_data, str) else raw_data
                except Exception:
                    data = raw_data
                await websocket.send_json({
                    "type": "event",
                    "channel": channel,
                    "data": data
                })

            # 2. 检查客户端是否发来消息（或断开连接）
            try:
                # 配合 timeout，防止 receive_text 永远阻塞
                client_msg = await asyncio.wait_for(websocket.receive_text(), timeout=0.05)
                logger.debug(f"Received client message: {client_msg}")
            except asyncio.TimeoutError:
                pass

            await asyncio.sleep(0.01)

    except WebSocketDisconnect:
        logger.info("WebSocket client disconnected.")
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
    finally:
        keep_alive_task.cancel()
        try:
            pubsub.unsubscribe()
            pubsub.close()
        except Exception:
            pass
        try:
            await websocket.close()
        except Exception:
            pass
