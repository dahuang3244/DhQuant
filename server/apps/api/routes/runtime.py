# server/apps/api/routes/runtime.py
from __future__ import annotations
from fastapi import APIRouter, Depends, HTTPException
from server.apps.api.dependencies import get_runtime_service
from server.domain.runtime.service import RuntimeService
from server.shared.schemas.runtime import RuntimeStatusDTO, ServiceInfoDTO

router = APIRouter(prefix="/runtime", tags=["runtime"])


@router.get("/status", response_model=RuntimeStatusDTO)
def get_runtime_status(runtime_service: RuntimeService = Depends(get_runtime_service)):
    """获取运行时的整体状态与指标。"""
    return runtime_service.get_status()


@router.get("/services", response_model=list[ServiceInfoDTO])
def list_runtime_services(runtime_service: RuntimeService = Depends(get_runtime_service)):
    """列出本机多进程服务的心跳健康状态。"""
    return runtime_service.list_services()


@router.post("/start")
def start_service(service_name: str):
    """启动/唤醒指定服务（通过 Supervisor 间接执行）。"""
    # 骨架版本，返回提示
    return {"message": f"Service {service_name} start command received (mocked)."}


@router.post("/stop")
def stop_service(service_name: str):
    """停止指定服务。"""
    # 骨架版本，返回提示
    return {"message": f"Service {service_name} stop command received (mocked)."}
