# server/domain/risk/service.py
from __future__ import annotations
from datetime import datetime
from server.shared.schemas.risk import RiskRuleDTO, RiskCheckResultDTO, RiskLogDTO
from server.shared.schemas.trading import OrderIntentDTO

class RiskService:
    def list_rules(self) -> list[RiskRuleDTO]:
        return [
            RiskRuleDTO(
                id="rule_weight_limit",
                name="单票权重限制",
                rule_type="position",
                threshold=0.2,
                current_value=0.05,
                unit="pct",
                status="idle"
            )
        ]

    def update_rule(self, rule_id: str, patch: dict) -> RiskRuleDTO:
        return RiskRuleDTO(
            id=rule_id,
            name="单票权重限制",
            rule_type="position",
            threshold=patch.get("threshold", 0.2),
            current_value=0.05,
            unit="pct",
            status="idle"
        )

    def pre_check(self, order: OrderIntentDTO) -> RiskCheckResultDTO:
        # Mock risk check: always passes unless quantity is 0 or negative
        if order.qty <= 0:
            log = RiskLogDTO(
                id="log_reject_1",
                rule_id="rule_qty_positive",
                instrument_id=order.instrument_id,
                result="rejected",
                level="error",
                message="订单数量必须大于0",
                limit_value=0.0,
                check_value=order.qty,
                created_at=datetime.now().isoformat()
            )
            return RiskCheckResultDTO(
                passed=False,
                action="reject",
                triggered_rules=["rule_qty_positive"],
                message="风控拒绝: 数量不合法",
                details=[log]
            )
        else:
            log = RiskLogDTO(
                id="log_pass_1",
                instrument_id=order.instrument_id,
                result="passed",
                level="info",
                message="订单前置检查通过",
                created_at=datetime.now().isoformat()
            )
            return RiskCheckResultDTO(
                passed=True,
                action="approve",
                triggered_rules=[],
                message="检查通过",
                details=[log]
            )

    def get_exposure(self) -> list[dict]:
        return [
            {"instrument_id": "SZ.000001", "weight": 0.05},
            {"instrument_id": "SH.600000", "weight": 0.08}
        ]

    def get_stats(self) -> dict:
        return {
            "total_exposure": 0.13,
            "max_drawdown": 0.05,
            "margin_usage": 0.15
        }
