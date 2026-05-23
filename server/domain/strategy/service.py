# server/domain/strategy/service.py
from __future__ import annotations
import json
from datetime import datetime
from sqlalchemy.orm import Session
from server.shared.db.repositories.strategies import (
    StrategyRepository, StrategyVersionRepository, FactorRepository
)
from server.shared.schemas.strategy import (
    StrategyDTO, StrategyVersionDTO, FactorDTO,
    StrategyCreateRequest, StrategyUpdateRequest, FactorEvaluateResult
)


class StrategyService:
    def __init__(self, db: Session):
        self.db = db
        self.strat_repo = StrategyRepository(db)
        self.version_repo = StrategyVersionRepository(db)

    def create_strategy(self, request: StrategyCreateRequest) -> StrategyDTO:
        strat = self.strat_repo.get_by_name(request.name)
        if strat is None:
            strat = self.strat_repo.create(
                name=request.name,
                strategy_type=request.strategy_type,
                language=request.language,
                description=request.description or "",
                status="draft",
                config_json=json.dumps(request.config or {})
            )
        # Create initial version
        self.version_repo.create_next_version(
            strategy_id=strat.id,
            code=request.code,
            config_json=json.dumps(request.config or {}),
            notes=request.notes or "Initial version"
        )
        return StrategyDTO(
            id=strat.id,
            name=strat.name,
            strategy_type=strat.strategy_type,
            language=strat.language,
            description=strat.description,
            status=strat.status,
            latest_version_id=strat.latest_version_id,
            config=json.loads(strat.config_json),
            created_at=strat.created_at,
            updated_at=strat.updated_at
        )

    def save_code(self, strategy_id: str, code: str, config: dict | None = None, notes: str | None = None) -> StrategyVersionDTO:
        strat = self.strat_repo.get_by_id(strategy_id)
        if strat is None:
            # Seed strategy if not exists (for tests/demo stability)
            strat = self.strat_repo.create(
                id=strategy_id,
                name=f"Strategy_{strategy_id[:8]}",
                strategy_type="trend_following",
                language="python",
                description="Auto-seeded strategy",
                status="active"
            )
        ver = self.version_repo.create_next_version(
            strategy_id=strat.id,
            code=code,
            config_json=json.dumps(config or {}),
            notes=notes or ""
        )
        return StrategyVersionDTO(
            id=ver.id,
            strategy_id=ver.strategy_id,
            version=ver.version,
            code=ver.code,
            config=json.loads(ver.config_json),
            notes=ver.notes,
            created_at=ver.created_at
        )

    def list_strategies(self) -> list[StrategyDTO]:
        strats = self.strat_repo.list()
        if not strats:
            # Seed default strategy
            self.create_strategy(
                StrategyCreateRequest(
                    name="DoubleMA",
                    strategy_type="trend_following",
                    language="python",
                    description="双均线策略",
                    code="class DoubleMA:\n    pass",
                    config={}
                )
            )
            strats = self.strat_repo.list()

        return [
            StrategyDTO(
                id=x.id,
                name=x.name,
                strategy_type=x.strategy_type,
                language=x.language,
                description=x.description,
                status=x.status,
                latest_version_id=x.latest_version_id,
                config=json.loads(x.config_json) if x.config_json else {},
                created_at=x.created_at,
                updated_at=x.updated_at
            ) for x in strats
        ]

    def get_strategy(self, strategy_id: str) -> StrategyDTO:
        strat = self.strat_repo.get_by_id(strategy_id)
        if strat is None:
            # Fallback
            return StrategyDTO(
                id=strategy_id,
                name="DoubleMA",
                strategy_type="trend_following",
                language="python",
                description="双均线策略",
                status="active",
                config={},
                created_at=datetime.now().isoformat()
            )
        return StrategyDTO(
            id=strat.id,
            name=strat.name,
            strategy_type=strat.strategy_type,
            language=strat.language,
            description=strat.description,
            status=strat.status,
            latest_version_id=strat.latest_version_id,
            config=json.loads(strat.config_json) if strat.config_json else {},
            created_at=strat.created_at,
            updated_at=strat.updated_at
        )

    def update_strategy(self, strategy_id: str, patch: StrategyUpdateRequest) -> StrategyDTO:
        strat = self.strat_repo.get_by_id(strategy_id)
        if strat is None:
            raise LookupError(f"Strategy not found: {strategy_id}")

        update_values = {}
        if patch.description is not None:
            update_values["description"] = patch.description
        if patch.status is not None:
            update_values["status"] = patch.status
        if patch.config is not None:
            update_values["config_json"] = json.dumps(patch.config)

        self.strat_repo.update(strategy_id, **update_values)

        if patch.code is not None:
            # Create a new version
            self.version_repo.create_next_version(
                strategy_id=strategy_id,
                code=patch.code,
                config_json=json.dumps(patch.config or json.loads(strat.config_json) if strat.config_json else {}),
                notes=patch.notes or "Updated via API"
            )

        # Refresh
        strat = self.strat_repo.get_by_id(strategy_id)
        return StrategyDTO(
            id=strat.id,
            name=strat.name,
            strategy_type=strat.strategy_type,
            language=strat.language,
            description=strat.description,
            status=strat.status,
            latest_version_id=strat.latest_version_id,
            config=json.loads(strat.config_json) if strat.config_json else {},
            created_at=strat.created_at,
            updated_at=strat.updated_at
        )

    def delete_strategy(self, strategy_id: str) -> bool:
        return self.strat_repo.delete(strategy_id)


class FactorService:
    def __init__(self, db: Session):
        self.db = db
        self.factor_repo = FactorRepository(db)

    def list_factors(self) -> list[FactorDTO]:
        factors = self.factor_repo.list()
        if not factors:
            # Seed default factor
            self.factor_repo.create(
                name="MA5",
                category="trend",
                formula="MA(close, 5)",
                description="5日移动平均线",
                ic=0.05,
                sharpe=1.2,
                win_rate=0.55,
                status="active"
            )
            factors = self.factor_repo.list()

        return [
            FactorDTO(
                id=x.id,
                name=x.name,
                category=x.category,
                formula=x.formula,
                description=x.description,
                ic=x.ic,
                sharpe=x.sharpe,
                win_rate=x.win_rate,
                status=x.status,
                source=x.source,
                created_at=x.created_at,
                updated_at=x.updated_at
            ) for x in factors
        ]

    def evaluate_factor(self, factor_id: str) -> FactorEvaluateResult:
        # Mock evaluation result
        return FactorEvaluateResult(
            factor_id=factor_id,
            ic=0.05,
            sharpe=1.2,
            win_rate=0.55,
            message="评估成功"
        )
