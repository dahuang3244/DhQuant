# server/apps/api/routes/risk.py
from __future__ import annotations
from fastapi import APIRouter, Depends
from server.apps.api.dependencies import get_risk_service
from server.domain.risk.service import RiskService
from server.shared.schemas.risk import RiskRuleDTO, RiskCheckResultDTO
from server.shared.schemas.trading import OrderIntentDTO

router = APIRouter(prefix="/risk", tags=["risk"])


@router.get("/rules", response_model=list[RiskRuleDTO])
def list_risk_rules(risk_service: RiskService = Depends(get_risk_service)):
    """获取风控规则列表及启用状态。"""
    return risk_service.list_rules()


@router.patch("/rules/{rule_id}", response_model=RiskRuleDTO)
def update_risk_rule(
    rule_id: str,
    patch: dict,
    risk_service: RiskService = Depends(get_risk_service)
):
    """更新风控规则参数或启用状态。"""
    return risk_service.update_rule(rule_id, patch)


@router.post("/pre-check", response_model=RiskCheckResultDTO)
def pre_check_order(
    intent: OrderIntentDTO,
    risk_service: RiskService = Depends(get_risk_service)
):
    """下单意图前置风控评估门禁。"""
    return risk_service.pre_check(intent)


@router.get("/exposure")
def get_portfolio_exposure(risk_service: RiskService = Depends(get_risk_service)):
    """获取当前投资组合敞口数据。"""
    return risk_service.get_exposure()


@router.get("/stats")
def get_risk_statistics(risk_service: RiskService = Depends(get_risk_service)):
    """获取全局组合级风控运行统计。"""
    return risk_service.get_stats()
