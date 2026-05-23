# server/domain/risk/service.py
from __future__ import annotations
from datetime import datetime
from sqlalchemy.orm import Session
from server.shared.db.repositories.risk import RiskRuleRepository, RiskLogRepository
from server.shared.db.repositories.instruments import InstrumentRepository
from server.shared.schemas.risk import RiskRuleDTO, RiskCheckResultDTO, RiskLogDTO
from server.shared.schemas.trading import OrderIntentDTO


class RiskService:
    def __init__(self, db: Session):
        self.db = db
        self.rule_repo = RiskRuleRepository(db)
        self.log_repo = RiskLogRepository(db)
        self.inst_repo = InstrumentRepository(db)

    def list_rules(self) -> list[RiskRuleDTO]:
        rules = self.rule_repo.list()
        if not rules:
            # Seed default rules
            self.rule_repo.create(
                id="rule_weight_limit",
                name="单票权重限制",
                rule_type="position",
                enabled=True,
                threshold=0.2,
                current_value=0.05,
                unit="pct",
                status="idle"
            )
            self.rule_repo.create(
                id="rule_qty_positive",
                name="委托数量大于零",
                rule_type="order",
                enabled=True,
                threshold=0.0,
                current_value=0.0,
                unit="share",
                status="idle"
            )
            rules = self.rule_repo.list()

        return [
            RiskRuleDTO(
                id=x.id,
                name=x.name,
                rule_type=x.rule_type,
                enabled=x.enabled,
                threshold=x.threshold,
                current_value=x.current_value,
                unit=x.unit,
                status=x.status,
                config=x.config_json if isinstance(x.config_json, dict) else {},
                created_at=x.created_at,
                updated_at=x.updated_at
            ) for x in rules
        ]

    def update_rule(self, rule_id: str, patch: dict) -> RiskRuleDTO:
        # Load rule or raise
        rule = self.rule_repo.get_by_id(rule_id)
        if rule is None:
            raise LookupError(f"Risk rule not found: {rule_id}")

        update_values = {}
        if "threshold" in patch:
            update_values["threshold"] = patch["threshold"]
        if "enabled" in patch:
            update_values["enabled"] = patch["enabled"]
        if "status" in patch:
            update_values["status"] = patch["status"]

        self.rule_repo.update(rule_id, **update_values)
        rule = self.rule_repo.get_by_id(rule_id)

        return RiskRuleDTO(
            id=rule.id,
            name=rule.name,
            rule_type=rule.rule_type,
            enabled=rule.enabled,
            threshold=rule.threshold,
            current_value=rule.current_value,
            unit=rule.unit,
            status=rule.status,
            config={},
            created_at=rule.created_at,
            updated_at=rule.updated_at
        )

    def pre_check(self, order: OrderIntentDTO) -> RiskCheckResultDTO:
        client_order_id = order.correlation_id or f"{order.account_id}:{order.instrument_id}:{order.side}:{order.qty}:{order.price}"
        
        lock_acquired = False
        token = None
        lock_key_str = None
        try:
            from server.shared.redis.keys import lock_order
            from server.shared.redis.locks import acquire_lock
            lock_key_str = lock_order(client_order_id)
            token = acquire_lock(lock_key_str, ttl=5)
            if token is None:
                return RiskCheckResultDTO(
                    passed=False,
                    action="reject",
                    triggered_rules=["order_concurrency"],
                    message="风控拒绝: 并发重复订单拦截",
                    details=[]
                )
            lock_acquired = True
        except Exception as e:
            from server.shared.logging.setup import get_logger
            get_logger("risk.service").warning(f"Failed to check lock for order: {e}")

        try:
            inst = self.inst_repo.get_or_create_by_symbol(order.instrument_id)
            is_passed = True
            message = "检查通过"
            triggered_rules = []
            details = []

            rule_qty = self.rule_repo.get_by_id("rule_qty_positive")
            if rule_qty is None or rule_qty.enabled:
                if order.qty <= 0:
                    is_passed = False
                    triggered_rules.append("rule_qty_positive")
                    message = "风控拒绝: 数量不合法"

            if not is_passed:
                log = self.log_repo.create(
                    rule_id="rule_qty_positive",
                    instrument_id=inst.id,
                    result="rejected",
                    level="error",
                    message="订单数量必须大于0",
                    limit_value=0.0,
                    check_value=order.qty
                )
                dto = RiskLogDTO(
                    id=log.id,
                    rule_id=log.rule_id,
                    instrument_id=order.instrument_id,
                    result=log.result,
                    level=log.level,
                    message=log.message,
                    limit_value=log.limit_value,
                    check_value=log.check_value,
                    created_at=log.created_at
                )
                details.append(dto)
                res = RiskCheckResultDTO(
                    passed=False,
                    action="reject",
                    triggered_rules=triggered_rules,
                    message=message,
                    details=details
                )
            else:
                log = self.log_repo.create(
                    instrument_id=inst.id,
                    result="passed",
                    level="info",
                    message="订单前置检查通过"
                )
                dto = RiskLogDTO(
                    id=log.id,
                    rule_id=log.rule_id,
                    instrument_id=order.instrument_id,
                    result=log.result,
                    level=log.level,
                    message=log.message,
                    created_at=log.created_at
                )
                details.append(dto)
                res = RiskCheckResultDTO(
                    passed=True,
                    action="approve",
                    triggered_rules=[],
                    message="检查通过",
                    details=details
                )

            # Redis Broadcast
            try:
                from server.shared.redis.keys import STREAM_RISK, RISK_STATUS_KEY
                from server.shared.redis.streams import xadd_json
                from server.shared.redis.client import get_redis
                from server.shared.redis.serialization import to_json
                
                xadd_json(STREAM_RISK, res)
                
                r = get_redis()
                risk_status = {
                    "status": "CRITICAL" if not res.passed else "IDLE",
                    "max_drawdown": 0.05,
                    "exposure_pct": 0.13,
                    "triggered_rules_count": len(res.triggered_rules),
                    "timestamp": datetime.now().timestamp()
                }
                r.set(RISK_STATUS_KEY, to_json(risk_status), ex=60)
            except Exception as e:
                from server.shared.logging.setup import get_logger
                get_logger("risk.service").warning(f"Failed to broadcast risk check: {e}")

            return res
        finally:
            if lock_acquired and token and lock_key_str:
                try:
                    from server.shared.redis.locks import release_lock
                    release_lock(lock_key_str, token)
                except Exception:
                    pass

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
