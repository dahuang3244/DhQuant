# server/apps/api/routes/strategy.py
from __future__ import annotations
from fastapi import APIRouter, Depends, HTTPException, status
from server.apps.api.dependencies import get_strategy_service, get_factor_service
from server.domain.strategy.service import StrategyService, FactorService
from server.shared.schemas.strategy import (
    StrategyDTO, FactorDTO, StrategyCreateRequest, StrategyUpdateRequest
)

router = APIRouter(tags=["strategy"])


@router.get("/strategies", response_model=list[StrategyDTO])
def list_strategies(strategy_service: StrategyService = Depends(get_strategy_service)):
    """获取所有可用策略列表。"""
    return strategy_service.list_strategies()


@router.post("/strategies", response_model=StrategyDTO, status_code=status.HTTP_201_CREATED)
def create_strategy(
    request: StrategyCreateRequest,
    strategy_service: StrategyService = Depends(get_strategy_service)
):
    """创建新的量化交易策略。"""
    return strategy_service.create_strategy(request)


@router.get("/strategies/{strategy_id}", response_model=StrategyDTO)
def get_strategy_by_id(
    strategy_id: str,
    strategy_service: StrategyService = Depends(get_strategy_service)
):
    """获取策略详情。"""
    return strategy_service.get_strategy(strategy_id)


@router.patch("/strategies/{strategy_id}", response_model=StrategyDTO)
def update_strategy(
    strategy_id: str,
    patch: StrategyUpdateRequest,
    strategy_service: StrategyService = Depends(get_strategy_service)
):
    """更新策略参数或配置。"""
    return strategy_service.update_strategy(strategy_id, patch)


@router.delete("/strategies/{strategy_id}")
def delete_strategy(
    strategy_id: str,
    strategy_service: StrategyService = Depends(get_strategy_service)
):
    """删除策略。"""
    success = strategy_service.delete_strategy(strategy_id)
    if not success:
        raise HTTPException(status_code=404, detail="Strategy not found")
    return {"message": f"Strategy {strategy_id} deleted successfully."}


@router.get("/factors", response_model=list[FactorDTO])
def list_factors(factor_service: FactorService = Depends(get_factor_service)):
    """获取可用特征因子库。"""
    return factor_service.list_factors()
