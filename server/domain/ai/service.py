# server/domain/ai/service.py
from __future__ import annotations
from datetime import datetime
from server.shared.schemas.ai import NewsAiAnalysisResultDTO, StrategyAiAnalysisDTO, FactorScoresDTO, AiSignalDTO

class AiService:
    def analyze_news(self, news_id: str) -> NewsAiAnalysisResultDTO:
        return NewsAiAnalysisResultDTO(
            summary="今日大盘反弹",
            impact="对证券、银行板块利好",
            sentiment_score=0.8,
            confidence=0.9,
            evidence=["成交量放大", "政策利好"]
        )

    def analyze_strategy(self, strategy_id: str) -> StrategyAiAnalysisDTO:
        return StrategyAiAnalysisDTO(
            strategy_id=strategy_id,
            analysis="该策略在震荡行情中表现良好，但在单边行情中可能面临较大回撤。",
            code_suggestions="建议加入自适应移动均线以过滤震荡。",
            performance_estimate="预计夏普比率 1.2",
            analyzed_at=datetime.now()
        )

    def write_strategy(self, prompt: str, strategy_type: str = "trend_following") -> str:
        return "# AI Generated Strategy\nclass MyStrategy:\n    pass\n"

    def compute_scores(self, instrument_id: str) -> FactorScoresDTO:
        return FactorScoresDTO(
            instrument_id=instrument_id,
            scores={"momentum": 0.8, "value": 0.4},
            overall_score=0.6,
            calculated_at=datetime.now()
        )

    def generate_signal(self, instrument_id: str, scores: FactorScoresDTO, threshold: float = 0.5) -> AiSignalDTO | None:
        if scores.overall_score >= threshold:
            return AiSignalDTO(
                instrument_id=instrument_id,
                direction="buy_long",
                confidence=scores.overall_score,
                reason="综合因子评分超过阈值",
                generated_at=datetime.now()
            )
        return None
