# server/domain/strategy/service.py
from __future__ import annotations
from datetime import datetime
from server.shared.schemas.strategy import (
    StrategyDTO, StrategyVersionDTO, FactorDTO,
    StrategyCreateRequest, StrategyUpdateRequest, FactorEvaluateResult
)

class StrategyService:
    def create_strategy(self, request: StrategyCreateRequest) -> StrategyDTO:
        return StrategyDTO(
            id="strat_1",
            name=request.name,
            strategy_type=request.strategy_type,
            language=request.language,
            description=request.description,
            status="draft",
            latest_version_id="ver_1",
            config=request.config,
            created_at=datetime.now().isoformat()
        )

    def save_code(self, strategy_id: str, code: str, config: dict | None = None, notes: str | None = None) -> StrategyVersionDTO:
        return StrategyVersionDTO(
            id="ver_1",
            strategy_id=strategy_id,
            version=1,
            code=code,
            config=config or {},
            notes=notes,
            created_at=datetime.now().isoformat()
        )

    def list_strategies(self) -> list[StrategyDTO]:
        return [
            StrategyDTO(
                id="strat_1",
                name="DoubleMA",
                strategy_type="trend_following",
                language="python",
                description="双均线策略",
                status="active",
                latest_version_id="ver_1",
                config={},
                created_at=datetime.now().isoformat()
            )
        ]

    def get_strategy(self, strategy_id: str) -> StrategyDTO:
        return StrategyDTO(
            id=strategy_id,
            name="DoubleMA",
            strategy_type="trend_following",
            language="python",
            description="双均线策略",
            status="active",
            latest_version_id="ver_1",
            config={},
            created_at=datetime.now().isoformat()
        )

    def update_strategy(self, strategy_id: str, patch: StrategyUpdateRequest) -> StrategyDTO:
        return StrategyDTO(
            id=strategy_id,
            name="DoubleMA",
            strategy_type="trend_following",
            language="python",
            description=patch.description or "双均线策略",
            status=patch.status or "active",
            latest_version_id="ver_1",
            config=patch.config or {},
            created_at=datetime.now().isoformat()
        )

    def delete_strategy(self, strategy_id: str) -> bool:
        return True


class FactorService:
    def list_factors(self) -> list[FactorDTO]:
        return [
            FactorDTO(
                id="factor_ma5",
                name="MA5",
                category="trend",
                description="5日移动平均线",
                ic=0.05,
                sharpe=1.2,
                win_rate=0.55
            )
        ]

    def evaluate_factor(self, factor_id: str) -> FactorEvaluateResult:
        return FactorEvaluateResult(
            factor_id=factor_id,
            ic=0.05,
            sharpe=1.2,
            win_rate=0.55,
            message="评估成功"
        )
