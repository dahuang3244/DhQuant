# server/apps/api/routes/broker.py
from __future__ import annotations
from fastapi import APIRouter, Depends
from server.apps.api.dependencies import get_broker_service
from server.domain.trading.service import BrokerService
from server.shared.schemas.trading import (
    AccountDTO, PositionDTO, OrderDTO, ApprovedOrderDTO
)

router = APIRouter(prefix="/broker", tags=["broker"])


@router.post("/connect")
def connect_broker(
    broker_id: str = "sim_broker",
    broker_service: BrokerService = Depends(get_broker_service)
):
    """连接到指定券商网关柜台。"""
    return broker_service.connect(broker_id)


@router.post("/disconnect")
def disconnect_broker(
    broker_id: str = "sim_broker",
    broker_service: BrokerService = Depends(get_broker_service)
):
    """断开券商网关连接。"""
    return broker_service.disconnect(broker_id)


@router.get("/account", response_model=AccountDTO)
def get_broker_account(
    account_id: str = "sim_account",
    broker_service: BrokerService = Depends(get_broker_service)
):
    """获取资产及可用资金快照。"""
    return broker_service.get_account(account_id)


@router.get("/positions", response_model=list[PositionDTO])
def get_broker_positions(
    account_id: str = "sim_account",
    broker_service: BrokerService = Depends(get_broker_service)
):
    """获取当前所有持仓详情。"""
    return broker_service.get_positions(account_id)


@router.post("/orders", response_model=OrderDTO)
def place_approved_order(
    order: ApprovedOrderDTO,
    broker_service: BrokerService = Depends(get_broker_service)
):
    """提交通过风控认证的订单进行交易。"""
    return broker_service.place_order(order)


@router.post("/orders/{order_id}/cancel", response_model=OrderDTO)
def cancel_broker_order(
    order_id: str,
    broker_service: BrokerService = Depends(get_broker_service)
):
    """撤销已提交的订单。"""
    return broker_service.cancel_order(order_id)
