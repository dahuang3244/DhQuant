from __future__ import annotations

import json
import random
import sqlite3
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any

from PySide6.QtCore import QObject, Property, Signal, Slot


_MOCK_SYMBOLS = [
    ("600036", "招商银行", 43.80),
    ("000858", "五粮液", 169.40),
    ("600519", "贵州茅台", 1688.00),
    ("002475", "立讯精密", 28.15),
    ("AAPL", "Apple Inc.", 184.20),
    ("NVDA", "NVIDIA", 912.50),
    ("300750", "宁德时代", 196.35),
    ("510300", "沪深300ETF", 3.78),
    ("TSLA", "Tesla", 178.64),
    ("MSFT", "Microsoft", 421.18),
]

_FILTER_DAYS: dict[str, int] = {"1D": 1, "1W": 7, "1M": 30, "3M": 90, "ALL": 0}
_UNIT_DAYS:   dict[str, int] = {"日": 1, "周": 7, "月": 30}


def _safe_pct(curr: float, prev: float) -> float:
    if prev == 0:
        return 0.0
    return round((curr - prev) / abs(prev) * 100.0, 1)


class JournalController(QObject):
    stateChanged     = Signal()
    unifiedChanged   = Signal()
    comparisonChanged = Signal()

    def __init__(self) -> None:
        super().__init__()
        self._quick_filter    = "1M"
        self._compare_mode    = "环比"   # 同比 / 环比
        self._compare_unit    = "月"     # 日 / 周 / 月
        self._panel_open      = False
        self._report_ready    = False
        self._analysis_filter = ""
        self._source          = "mock"
        self._events:         list[dict] = []
        self._unified_rows:   list[dict] = []
        self._comparison:     dict       = {}
        self._summary:        dict       = {}
        # stats cache
        self._event_count = 0
        self._trade_count = 0
        self._win_count   = 0
        self._loss_count  = 0
        self._total_pnl   = 0.0
        self.refresh()

    # ── Properties ────────────────────────────────────────────────────────────
    @Property(str, notify=stateChanged)
    def quickFilter(self) -> str:
        return self._quick_filter

    @Property(str, notify=stateChanged)
    def compareMode(self) -> str:
        return self._compare_mode

    @Property(str, notify=stateChanged)
    def compareUnit(self) -> str:
        return self._compare_unit

    @Property(bool, notify=stateChanged)
    def panelOpen(self) -> bool:
        return self._panel_open

    @Property(bool, notify=stateChanged)
    def reportReady(self) -> bool:
        return self._report_ready and self._analysis_filter == self._quick_filter

    @Property(str, notify=stateChanged)
    def source(self) -> str:
        return self._source

    @Property(int, notify=stateChanged)
    def eventCount(self) -> int:
        return self._event_count

    @Property(int, notify=stateChanged)
    def tradeCount(self) -> int:
        return self._trade_count

    @Property(int, notify=stateChanged)
    def winCount(self) -> int:
        return self._win_count

    @Property(int, notify=stateChanged)
    def lossCount(self) -> int:
        return self._loss_count

    @Property(float, notify=stateChanged)
    def winRate(self) -> float:
        if self._trade_count == 0:
            return 0.0
        return round(self._win_count / self._trade_count * 100.0, 1)

    @Property(float, notify=stateChanged)
    def totalPnl(self) -> float:
        return self._total_pnl

    @Property("QVariantList", notify=unifiedChanged)
    def unifiedRows(self) -> list[dict]:
        return self._unified_rows

    @Property("QVariantMap", notify=comparisonChanged)
    def comparisonResult(self) -> dict:
        return self._comparison

    @Property("QVariantMap", notify=comparisonChanged)
    def summaryResult(self) -> dict:
        return self._summary

    # ── Slots ─────────────────────────────────────────────────────────────────
    @Slot(str)
    def setQuickFilter(self, value: str) -> None:
        if value not in _FILTER_DAYS or value == self._quick_filter:
            return
        self._quick_filter = value
        self._panel_open = False
        self._report_ready = False
        self._analysis_filter = ""
        self._rebuild()

    @Slot(str)
    def setCompareMode(self, mode: str) -> None:
        if mode not in ("同比", "环比"):
            return
        self._compare_mode = mode
        self._rebuild_comparison()
        self.stateChanged.emit()

    @Slot(str)
    def setCompareUnit(self, unit: str) -> None:
        if unit not in _UNIT_DAYS:
            return
        self._compare_unit = unit
        self._rebuild_comparison()
        self.stateChanged.emit()

    @Slot(str)
    def openPanel(self, mode: str) -> None:
        self.openSummary(mode)

    @Slot()
    @Slot(str)
    def openSummary(self, mode: str = "") -> None:
        if not self.reportReady:
            self._apply_row_analysis()
        if mode in ("同比", "环比"):
            self._compare_mode = mode
        self._panel_open = True
        self._rebuild_summary()
        self._rebuild_comparison()
        self.stateChanged.emit()
        self.comparisonChanged.emit()

    @Slot()
    def closePanel(self) -> None:
        self._panel_open = False
        self.stateChanged.emit()

    @Slot()
    def refresh(self) -> None:
        self._panel_open = False
        self._report_ready = False
        self._analysis_filter = ""
        db_rows = self._load_database_events()
        if db_rows:
            self._events = db_rows
        else:
            self._source = "mock"
            self._events = self._mock_events()
        self._rebuild()

    @Slot()
    def runAnalysis(self) -> None:
        self._apply_row_analysis()
        self.unifiedChanged.emit()
        self.stateChanged.emit()

    def _apply_row_analysis(self) -> None:
        analyzed = []
        for row in self._unified_rows:
            enriched = dict(row)
            enriched["analysisReady"] = True
            enriched.update(self._row_analysis(enriched))
            analyzed.append(enriched)
        self._unified_rows = analyzed
        self._report_ready = True
        self._analysis_filter = self._quick_filter
        self._rebuild_summary()
        self._rebuild_comparison()

    # ── Internal: rebuild unified rows + stats ────────────────────────────────
    def _rebuild(self) -> None:
        cutoff = self._cutoff_for(self._quick_filter)
        rows: list[dict] = []
        for event in self._events:
            ts = self._parse_time(str(event.get("time", "")))
            if cutoff is not None and ts is not None and ts < cutoff:
                continue
            row = self._enrich(dict(event))
            if self.reportReady:
                row["analysisReady"] = True
                row.update(self._row_analysis(row))
            rows.append(row)

        rows.sort(key=lambda r: str(r.get("time", "")), reverse=True)
        self._unified_rows = rows

        buy_rows = [r for r in rows if r.get("hasPnl")]
        self._event_count = len(rows)
        self._trade_count = len(buy_rows)
        self._win_count   = sum(1 for r in buy_rows if float(r.get("pnl", 0)) >= 0)
        self._loss_count  = self._trade_count - self._win_count
        self._total_pnl   = round(sum(float(r.get("pnl", 0)) for r in buy_rows), 2)
        self._rebuild_summary()

        self.unifiedChanged.emit()
        self._rebuild_comparison()
        self.stateChanged.emit()

    def _enrich(self, row: dict) -> dict:
        row["hasPnl"] = False
        row.setdefault("pnl", 0.0)
        row.setdefault("pnlPct", 0.0)
        row.setdefault("status", "")
        row.setdefault("analysisReady", False)
        row.setdefault("analysisScore", 0)
        row.setdefault("riskLevel", "")
        row.setdefault("analysisTitle", "")
        row.setdefault("analysisText", "")
        row.setdefault("actionHint", "")
        row.setdefault("analysisPnlText", "")
        row.setdefault("analysisPnlPctText", "")
        row.setdefault("analysisMarketValueText", "")
        row.setdefault("analysisContributionText", "")
        row.setdefault("analysisResultText", "")
        row.setdefault("analysisPricePairText", "")
        row.setdefault("analysisFormulaText", "")
        row.setdefault("signalStrategy", self._strategy_from_message(str(row.get("message") or "")))

        side = row.get("side")
        trade_p = float(row.get("price", 0) or 0)
        cur_p = float(row.get("currentPrice", 0) or 0)
        qty = int(float(row.get("qty", 0) or 0))
        if side in ("买入", "卖出") and trade_p > 0 and cur_p > 0 and qty > 0:
            if side == "卖出":
                unit_delta = trade_p - cur_p
                formula = "卖出价 - 今日价"
            else:
                unit_delta = cur_p - trade_p
                formula = "今日价 - 买入价"
            pnl = unit_delta * qty
            pnl_pct = unit_delta / trade_p * 100
            row["pnl"] = round(pnl, 2)
            row["pnlPct"] = round(pnl_pct, 2)
            row["status"] = "盈利" if pnl >= 0 else "亏损"
            row["hasPnl"] = True
        return row

    # ── Internal: comparison analytics ───────────────────────────────────────
    def _rebuild_comparison(self) -> None:
        cur_rows     = self._rows_in_window(self._quick_filter, offset_years=0)
        cur_metrics  = self._metrics(cur_rows)

        if self._compare_mode == "同比":
            cur_label = self._label_current() + "（今年）"
            ref_label = self._label_current() + "（去年）"
            ref_metrics = self._synthetic(cur_metrics, seed=3001)
        else:
            unit_days  = _UNIT_DAYS.get(self._compare_unit, 30)
            cur_rows2  = self._rows_in_unit_window(unit_days, offset=0)
            ref_rows   = self._rows_in_unit_window(unit_days, offset=unit_days)
            cur_metrics  = self._metrics(cur_rows2)
            ref_metrics  = self._metrics(ref_rows)
            # If reference window has no real data, use synthetic
            if ref_metrics["tradeCount"] == 0:
                ref_metrics = self._synthetic(cur_metrics, seed=4002)
            cur_label = {"日": "今日", "周": "本周", "月": "本月"}.get(self._compare_unit, "当前")
            ref_label = {"日": "昨日", "周": "上周", "月": "上月"}.get(self._compare_unit, "上期")

        self._comparison = {
            "mode":         self._compare_mode,
            "unit":         self._compare_unit,
            "currentLabel": cur_label,
            "refLabel":     ref_label,
            "current":      cur_metrics,
            "ref":          ref_metrics,
            "delta":        self._delta(cur_metrics, ref_metrics),
        }
        self.comparisonChanged.emit()

    def _row_analysis(self, row: dict) -> dict:
        symbol = str(row.get("symbol") or "该标的")
        side = str(row.get("side") or "事件")
        pnl = float(row.get("pnl", 0) or 0)
        pnl_pct = float(row.get("pnlPct", 0) or 0)
        qty = int(float(row.get("qty", 0) or 0))

        if not row.get("hasPnl"):
            return {
                "analysisScore": 50,
                "riskLevel": "待确认",
                "analysisTitle": f"{symbol} {side}记录",
                "analysisText": "该记录缺少可计算盈亏的成交字段，先保留为事件型 journal，后续可补充成交价、现价和数量后纳入统计。",
                "actionHint": "补齐成交字段后再做收益归因。",
                "analysisPnlText": "不可计算",
                "analysisPnlPctText": "—",
                "analysisMarketValueText": "—",
                "analysisContributionText": "—",
                "analysisResultText": "事件记录",
                "analysisPricePairText": "—",
                "analysisFormulaText": "缺少成交字段",
                "signalStrategy": self._strategy_from_message(str(row.get("message") or "")),
            }

        trade_price = float(row.get("price", 0) or 0)
        today_price = float(row.get("currentPrice", 0) or 0)
        market_value = qty * float(row.get("currentPrice", 0) or 0)
        contribution = pnl / self._total_pnl * 100.0 if self._total_pnl else 0.0
        formula = "卖出价 - 今日价" if side == "卖出" else "今日价 - 买入价"
        price_pair = f"{trade_price:.2f} -> {today_price:.2f}"
        signal_strategy = self._strategy_from_message(str(row.get("message") or ""))
        score = max(0, min(100, int(50 + pnl_pct * 5)))
        if pnl_pct >= 2.5:
            risk = "有效信号"
            text = f"{symbol} {side}后收益率 {pnl_pct:.2f}%，该信号对当前筛选窗口形成正贡献。"
            hint = "记录入场理由与止盈计划，避免盈利回撤。"
        elif pnl_pct <= -2.5:
            risk = "信号偏弱"
            text = f"{symbol} {side}后收益率 {pnl_pct:.2f}%，该笔交易拖累区间表现。"
            hint = "复盘触发条件、价格区间和仓位大小。"
        else:
            risk = "接近持平"
            text = f"{symbol} {side}后价格变化不大，单笔贡献有限。"
            hint = "继续观察信号后的量价确认。"

        return {
            "analysisScore": score,
            "riskLevel": risk,
            "analysisTitle": f"{symbol} {side}复盘",
            "analysisText": text,
            "actionHint": hint,
            "analysisPnlText": f"{pnl:+,.2f}",
            "analysisPnlPctText": f"{pnl_pct:+.2f}%",
            "analysisMarketValueText": f"{market_value:,.2f}",
            "analysisContributionText": f"{contribution:+.1f}%",
            "analysisResultText": "盈利" if pnl >= 0 else "亏损",
            "analysisPricePairText": price_pair,
            "analysisFormulaText": formula,
            "signalStrategy": signal_strategy,
        }

    def _strategy_from_message(self, message: str) -> str:
        head = message.split(":", 1)[0].split("：", 1)[0].strip()
        return head if 0 < len(head) <= 16 else "未标注策略"

    def _rebuild_summary(self) -> None:
        rows = [dict(row) for row in self._unified_rows]
        metrics = self._metrics(rows)
        event_count = len(rows)
        analyzable = metrics["tradeCount"]
        missing_count = event_count - analyzable
        total_exposure = round(
            sum(float(r.get("qty", 0) or 0) * float(r.get("currentPrice", 0) or 0) for r in rows if r.get("hasPnl")),
            2,
        )
        loss_rows = [r for r in rows if r.get("hasPnl") and float(r.get("pnl", 0) or 0) < 0]
        profit_rows = [r for r in rows if r.get("hasPnl") and float(r.get("pnl", 0) or 0) >= 0]
        best_row = max(profit_rows, key=lambda r: float(r.get("pnl", 0) or 0), default={})
        worst_row = min(loss_rows, key=lambda r: float(r.get("pnl", 0) or 0), default={})
        profit_total = sum(float(r.get("pnl", 0) or 0) for r in profit_rows)
        loss_total = abs(sum(float(r.get("pnl", 0) or 0) for r in loss_rows))
        profit_loss_ratio = round(profit_total / loss_total, 2) if loss_total else 0.0

        if analyzable == 0:
            conclusion = "当前筛选窗口没有可计算盈亏的交易项，需要补齐成交价、现价和数量后再做汇总。"
        elif metrics["totalPnl"] >= 0:
            conclusion = f"当前筛选窗口合计盈利 {metrics['totalPnl']:+,.2f}，胜率 {metrics['winRate']:.1f}%，主要贡献来自 {best_row.get('symbol', '—')}。"
        else:
            conclusion = f"当前筛选窗口合计亏损 {metrics['totalPnl']:+,.2f}，胜率 {metrics['winRate']:.1f}%，优先复盘 {worst_row.get('symbol', '—')} 的亏损来源。"

        self._summary = {
            **metrics,
            "eventCount": event_count,
            "missingCount": missing_count,
            "totalExposure": total_exposure,
            "profitLossRatio": profit_loss_ratio,
            "bestSymbol": best_row.get("symbol", "—") or "—",
            "worstSymbol": worst_row.get("symbol", "—") or "—",
            "filterLabel": self._label_current(),
            "conclusion": conclusion,
        }
        self.comparisonChanged.emit()

    def _rows_in_window(self, filter_key: str, offset_years: int) -> list[dict]:
        cutoff = self._cutoff_for(filter_key)
        rows   = []
        for event in self._events:
            ts = self._parse_time(str(event.get("time", "")))
            if cutoff is not None and ts is not None and ts < cutoff:
                continue
            rows.append(self._enrich(dict(event)))
        return rows

    def _rows_in_unit_window(self, days: int, offset: int) -> list[dict]:
        now  = datetime.now()
        end  = now - timedelta(days=offset)
        start = end - timedelta(days=days)
        rows = []
        for event in self._events:
            ts = self._parse_time(str(event.get("time", "")))
            if ts is None:
                continue
            if start <= ts <= end:
                rows.append(self._enrich(dict(event)))
        return rows

    def _metrics(self, rows: list[dict]) -> dict:
        buy_rows    = [r for r in rows if r.get("hasPnl")]
        trade_count = len(buy_rows)
        win_count   = sum(1 for r in buy_rows if float(r.get("pnl", 0)) >= 0)
        loss_count  = trade_count - win_count
        win_rate    = round(win_count / trade_count * 100.0, 1) if trade_count else 0.0
        total_pnl   = round(sum(float(r.get("pnl", 0)) for r in buy_rows), 2)
        avg_pnl     = round(total_pnl / trade_count, 2) if trade_count else 0.0
        pnls        = [float(r.get("pnl", 0)) for r in buy_rows]
        best_pnl    = round(max(pnls), 2) if pnls else 0.0
        worst_pnl   = round(min(pnls), 2) if pnls else 0.0
        return {
            "tradeCount": trade_count,
            "winCount":   win_count,
            "lossCount":  loss_count,
            "winRate":    win_rate,
            "totalPnl":   total_pnl,
            "avgPnl":     avg_pnl,
            "bestPnl":    best_pnl,
            "worstPnl":   worst_pnl,
        }

    def _synthetic(self, base: dict, seed: int) -> dict:
        rnd         = random.Random(seed + abs(hash(self._compare_unit)) % 200)
        trade_count = max(1, int(base["tradeCount"] * rnd.uniform(0.6, 1.4)))
        win_rate    = max(0.0, min(100.0, base["winRate"] + rnd.uniform(-20, 20)))
        win_count   = round(trade_count * win_rate / 100)
        loss_count  = trade_count - win_count
        total_pnl   = round(base["totalPnl"] * rnd.uniform(0.45, 1.55), 2)
        avg_pnl     = round(total_pnl / trade_count, 2) if trade_count else 0.0
        best_pnl    = round(abs(base["bestPnl"]) * rnd.uniform(0.5, 1.5), 2)
        worst_pnl   = round(-abs(base["worstPnl"]) * rnd.uniform(0.5, 1.5), 2)
        return {
            "tradeCount": trade_count,
            "winCount":   win_count,
            "lossCount":  loss_count,
            "winRate":    round(win_rate, 1),
            "totalPnl":   total_pnl,
            "avgPnl":     avg_pnl,
            "bestPnl":    best_pnl,
            "worstPnl":   worst_pnl,
        }

    def _delta(self, cur: dict, ref: dict) -> dict:
        return {
            "tradeCount":    cur["tradeCount"] - ref["tradeCount"],
            "tradeCountPct": _safe_pct(cur["tradeCount"], ref["tradeCount"]),
            "winRate":       round(cur["winRate"] - ref["winRate"], 1),
            "totalPnl":      round(cur["totalPnl"] - ref["totalPnl"], 2),
            "totalPnlPct":   _safe_pct(cur["totalPnl"], ref["totalPnl"]),
            "avgPnl":        round(cur["avgPnl"] - ref["avgPnl"], 2),
            "avgPnlPct":     _safe_pct(cur["avgPnl"], ref["avgPnl"]),
            "bestPnl":       round(cur["bestPnl"] - ref["bestPnl"], 2),
            "worstPnl":      round(cur["worstPnl"] - ref["worstPnl"], 2),
        }

    def _label_current(self) -> str:
        return {"1D": "今日", "1W": "本周", "1M": "本月", "3M": "近三月", "ALL": "全部"}.get(
            self._quick_filter, "当前"
        )

    def _cutoff_for(self, key: str) -> datetime | None:
        days = _FILTER_DAYS.get(key, 0)
        return None if days == 0 else datetime.now() - timedelta(days=days)

    # ── Mock data ─────────────────────────────────────────────────────────────
    def _mock_events(self) -> list[dict]:
        now = datetime.now().replace(microsecond=0)
        rnd = random.Random(20260510)
        rows: list[dict] = []
        topics = ["trade.filled", "order.filled", "position.adjusted", "risk.note"]
        strategies = ["突破回踩", "均线反转", "财报事件", "ETF 定投", "AI 动量", "低吸试仓"]
        notes = [
            "按计划成交，等待下一根K线确认。",
            "成交后波动放大，需要复盘仓位是否过重。",
            "价格触发预设区间，记录入场依据。",
            "盘口流动性一般，后续观察滑点影响。",
            "与指数方向一致，先按区间交易处理。",
            "信号强度一般，重点检查止损纪律。",
        ]

        for i in range(72):
            symbol, name, current = _MOCK_SYMBOLS[i % len(_MOCK_SYMBOLS)]
            side = "买入" if i % 5 in (0, 2, 3) else "卖出"
            qty = [100, 200, 300, 500, 800, 1000][i % 6]
            drift = rnd.uniform(-0.06, 0.052)
            if i % 11 == 0:
                drift -= 0.055
            if i % 13 == 0:
                drift += 0.065
            price = current * (1 + drift)
            ts = now - timedelta(hours=i * 6 + rnd.randint(0, 4), minutes=rnd.choice((0, 5, 15, 30, 45)))
            strategy = strategies[i % len(strategies)]
            note = notes[(i + rnd.randint(0, 3)) % len(notes)]
            rows.append({
                "time":         ts.strftime("%Y-%m-%d %H:%M:%S"),
                "topic":        topics[i % len(topics)] if side == "买入" else "order.updated",
                "level":        "INFO",
                "symbol":       symbol,
                "name":         name,
                "side":         side,
                "qty":          qty,
                "price":        round(price, 2),
                "currentPrice": round(current, 2),
                "message":      f"{strategy}: {symbol} {side} {qty}股 @ {price:.2f}。{note}",
            })
        return rows

    # ── DB loading (unchanged) ────────────────────────────────────────────────
    def _load_database_events(self) -> list[dict]:
        for db_path in self._candidate_db_paths():
            rows = self._read_sqlite_events(db_path)
            if rows:
                self._source = str(db_path)
                return rows
        return []

    def _candidate_db_paths(self) -> list[Path]:
        root = Path(__file__).resolve().parents[2]
        candidates = [
            root / "data" / "dhquant.db",
            root / "data" / "journal.db",
            root / "journal.db",
            root / "dhquant.db",
            root / "build" / "dhquant.db",
        ]
        candidates.extend(root.glob("**/*journal*.sqlite"))
        candidates.extend(root.glob("**/*journal*.db"))
        candidates.extend(root.glob("**/*.sqlite3"))
        seen: set[Path] = set()
        unique: list[Path] = []
        for path in candidates:
            if path in seen or not path.exists() or not path.is_file():
                continue
            seen.add(path)
            unique.append(path)
        return unique

    def _read_sqlite_events(self, path: Path) -> list[dict]:
        try:
            conn = sqlite3.connect(path)
            conn.row_factory = sqlite3.Row
            tables = conn.execute("select name from sqlite_master where type='table'").fetchall()
            table_names = [str(row["name"]) for row in tables]
            preferred = [n for n in table_names if "journal" in n.lower() or "event" in n.lower()]
            for table in preferred + [n for n in table_names if n not in preferred]:
                rows = self._read_table(conn, table)
                if rows:
                    return rows
        except sqlite3.Error:
            return []
        finally:
            try:
                conn.close()
            except Exception:
                pass
        return []

    def _read_table(self, conn: sqlite3.Connection, table: str) -> list[dict]:
        try:
            qt = self._quote_ident(table)
            cols = [r["name"] for r in conn.execute(f"pragma table_info({qt})").fetchall()]
            if not cols:
                return []
            order_col = self._first(cols, ("timestamp", "time", "created_at", "ts", "id", "offset"))
            order_sql = f" order by {self._quote_ident(order_col)} desc" if order_col else ""
            raw_rows = conn.execute(f"select * from {qt}{order_sql} limit 500").fetchall()
        except sqlite3.Error:
            return []
        return [r for r in (self._normalize_db_row(dict(row), table) for row in raw_rows) if r]

    def _normalize_db_row(self, row: dict[str, Any], table: str) -> dict:
        payload = self._payload(row)
        merged  = {**row, **payload}
        topic   = str(merged.get("topic") or merged.get("event_type") or merged.get("type") or table)
        side    = self._side(merged)
        symbol  = str(merged.get("symbol") or merged.get("security") or merged.get("instrument") or "")
        price   = self._number(merged, ("price", "fill_price", "avg_price", "trade_price"))
        qty     = self._number(merged, ("qty", "quantity", "volume", "shares"))
        current = self._number(merged, ("current_price", "last_price", "mark_price"))
        if current <= 0 and symbol:
            current = self._mock_current_price(symbol, price)
        return {
            "time":         self._time_text(merged),
            "topic":        topic,
            "level":        str(merged.get("level") or "INFO").upper(),
            "symbol":       symbol,
            "name":         str(merged.get("name") or merged.get("security_name") or symbol),
            "side":         side,
            "qty":          int(qty),
            "price":        round(price, 2),
            "currentPrice": round(current, 2),
            "message":      str(merged.get("message") or merged.get("msg") or topic),
        }

    def _payload(self, row: dict[str, Any]) -> dict:
        for key in ("payload", "data", "body", "event"):
            raw = row.get(key)
            if not isinstance(raw, str) or not raw.strip():
                continue
            try:
                v = json.loads(raw)
            except json.JSONDecodeError:
                continue
            if isinstance(v, dict):
                return v
        return {}

    def _mock_current_price(self, symbol: str, fallback: float) -> float:
        for sym, _, price in _MOCK_SYMBOLS:
            if sym == symbol:
                return price
        if fallback <= 0:
            return 0.0
        rnd = random.Random(abs(hash(symbol)) % 10_000)
        return fallback * (1 + rnd.uniform(-0.035, 0.045))

    def _time_text(self, row: dict[str, Any]) -> str:
        raw = row.get("timestamp") or row.get("time") or row.get("created_at") or row.get("ts") or ""
        if isinstance(raw, (int, float)):
            v = float(raw)
            if v > 10_000_000_000:
                v /= 1000.0
            return datetime.fromtimestamp(v).strftime("%Y-%m-%d %H:%M:%S")
        return str(raw)

    def _parse_time(self, value: str) -> datetime | None:
        for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d %H:%M", "%Y-%m-%d", "%m-%d %H:%M"):
            try:
                parsed = datetime.strptime(value, fmt)
                if fmt.startswith("%m"):
                    parsed = parsed.replace(year=datetime.now().year)
                return parsed
            except ValueError:
                continue
        return None

    def _side(self, row: dict[str, Any]) -> str:
        raw = str(row.get("side") or row.get("direction") or row.get("action") or "").lower()
        if raw in ("buy", "bid", "long", "b", "买", "买入"):
            return "买入"
        if raw in ("sell", "ask", "short", "s", "卖", "卖出"):
            return "卖出"
        return str(row.get("side") or "")

    def _number(self, row: dict[str, Any], keys: tuple[str, ...]) -> float:
        for key in keys:
            try:
                return float(row.get(key) or 0.0)
            except (TypeError, ValueError):
                continue
        return 0.0

    def _first(self, cols: list[str], names: tuple[str, ...]) -> str:
        lower = {col.lower(): col for col in cols}
        for name in names:
            if name in lower:
                return lower[name]
        return ""

    def _quote_ident(self, value: str) -> str:
        return '"' + value.replace('"', '""') + '"'
