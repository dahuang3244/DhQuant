# server/apps/api/routes/ai.py
from __future__ import annotations
from fastapi import APIRouter, Depends
from server.apps.api.dependencies import get_ai_service
from server.domain.ai.service import AiService
from server.shared.schemas.ai import (
    NewsAiAnalysisResultDTO, StrategyAiAnalysisDTO,
    FactorScoresDTO, AiSignalDTO, StrategyGenRequest
)

router = APIRouter(prefix="/ai", tags=["ai"])


@router.get("/models")
def list_ai_models():
    """获取可用的大语言模型列表。"""
    return {
        "providers": {
            "deepseek": ["deepseek-chat", "deepseek-coder"],
            "openai": ["gpt-4o", "gpt-3.5-turbo"],
            "anthropic": ["claude-3-5-sonnet"]
        },
        "default": "deepseek-chat"
    }


@router.post("/news/analyze", response_model=NewsAiAnalysisResultDTO)
def analyze_news_item(
    news_id: str,
    ai_service: AiService = Depends(get_ai_service)
):
    """即时调用 AI 分析单条新闻的宏观/个股影响。"""
    return ai_service.analyze_news(news_id)


@router.post("/strategy/write")
def write_strategy_code(
    request: StrategyGenRequest,
    ai_service: AiService = Depends(get_ai_service)
):
    """根据自然语言 Prompt 和策略类型生成 Python 策略代码。"""
    code = ai_service.write_strategy(request.prompt, request.strategy_type)
    return {"code": code, "strategy_type": request.strategy_type}


@router.post("/strategy/analyze", response_model=StrategyAiAnalysisDTO)
def analyze_strategy_code(
    strategy_id: str,
    ai_service: AiService = Depends(get_ai_service)
):
    """分析已有策略的代码逻辑与改进建议。"""
    return ai_service.analyze_strategy(strategy_id)


@router.post("/scores", response_model=FactorScoresDTO)
def calculate_factor_scores(
    instrument_id: str,
    ai_service: AiService = Depends(get_ai_service)
):
    """通过 AI 融合计算特定标的的因子得分。"""
    return ai_service.compute_scores(instrument_id)


@router.post("/signals")
def scan_ai_signals(
    instrument_id: str,
    threshold: float = 0.5,
    ai_service: AiService = Depends(get_ai_service)
):
    """手动扫描标的以生成 AI 自主交易信号。"""
    scores = ai_service.compute_scores(instrument_id)
    sig = ai_service.generate_signal(instrument_id, scores, threshold)
    if sig:
        return {"signal_generated": True, "signal": sig.dict()}
    return {"signal_generated": False, "reason": "Scores do not meet threshold"}
