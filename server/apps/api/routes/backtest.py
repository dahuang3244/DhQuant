# server/apps/api/routes/backtest.py
from __future__ import annotations
from fastapi import APIRouter, Depends, HTTPException, status
from server.apps.api.dependencies import get_backtest_service
from server.domain.backtest.service import BacktestService
from server.shared.schemas.backtest import BacktestRunRequest, BacktestRunDTO, BacktestTradeDTO

router = APIRouter(prefix="/backtest", tags=["backtest"])


@router.post("/runs", response_model=BacktestRunDTO, status_code=status.HTTP_201_CREATED)
def create_backtest_run(
    request: BacktestRunRequest,
    backtest_service: BacktestService = Depends(get_backtest_service)
):
    """创建并投递一个新的回测任务。"""
    run = backtest_service.create_run(request)
    
    # 异步投递 Dramatiq 队列（骨架版本，通过动态导入避免模块循环依赖）
    try:
        from server.apps.backtest_worker.runner import run_backtest_task
        run_backtest_task.send(run.id)
    except Exception as e:
        # 如果 Dramatiq 未完全设置，仅作打印，不影响骨架启动
        pass

    return run


@router.get("/runs", response_model=list[BacktestRunDTO])
def list_backtest_runs(backtest_service: BacktestService = Depends(get_backtest_service)):
    """获取所有历史回测运行记录摘要。"""
    return backtest_service.list_runs()


@router.get("/runs/{run_id}", response_model=BacktestRunDTO)
def get_backtest_run(
    run_id: str,
    backtest_service: BacktestService = Depends(get_backtest_service)
):
    """获取指定回测任务状态与汇总指标。"""
    return backtest_service.get_run(run_id)


@router.get("/runs/{run_id}/trades", response_model=list[BacktestTradeDTO])
def get_backtest_trades(
    run_id: str,
    backtest_service: BacktestService = Depends(get_backtest_service)
):
    """获取回测产生的交易明细明细。"""
    # 骨架版本，返回 mock 交易明细
    return [
        BacktestTradeDTO(
            id="t_1",
            run_id=run_id,
            instrument_id="SZ.000001",
            entry_time="2024-01-05 10:00:00",
            exit_time="2024-01-10 15:00:00",
            side="buy_long",
            qty=100.0,
            entry_price=10.0,
            exit_price=10.5,
            pnl=50.0,
            return_pct=0.05,
            hold_days=5.0
        )
    ]


@router.get("/runs/{run_id}/equity")
def get_backtest_equity_curve(
    run_id: str,
    backtest_service: BacktestService = Depends(get_backtest_service)
):
    """获取回测产生的权益曲线 Parquet 路径。"""
    return {
        "run_id": run_id,
        "format": "parquet",
        "equity_curve_path": f"data/parquet/backtest/{run_id}_equity.parquet"
    }
