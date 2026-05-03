#include "gui/dhquant_dashboard_state.h"

#include <utility>

namespace app::dashboard {
namespace {

DashboardState gState;

} // namespace

DashboardState& state() {
    return gState;
}

const char* pageLabel(Page page) {
    switch (page) {
        case Page::Overview: return "系统总览";
        case Page::Watchlist: return "实时盯盘";
        case Page::Account: return "账户持仓";
        case Page::Strategy: return "策略中心";
        case Page::Backtest: return "回测工作台";
        case Page::Risk: return "风控中心";
        case Page::Agent: return "AI 决策台";
        case Page::Journal: return "日志与 Journal";
    }
    return "未知页面";
}

const char* pageHint(Page page) {
    switch (page) {
        case Page::Overview: return "服务健康、事件延迟、最近告警将在这里展开。";
        case Page::Watchlist: return "自选标的 K 线、成交量和 Kronos 预测将在这里展开。";
        case Page::Account: return "资产摘要、现金、持仓表和盈亏占位曲线将在这里展开。";
        case Page::Strategy: return "策略列表、启停状态和最近信号将在这里展开。";
        case Page::Backtest: return "参数表单、运行按钮、进度和绩效摘要将在这里展开。";
        case Page::Risk: return "规则开关、拒单记录和暴露摘要将在这里展开。";
        case Page::Agent: return "建议流、证据链状态、采纳和忽略操作将在这里展开。";
        case Page::Journal: return "事件表、topic 过滤和错误日志将在这里展开。";
    }
    return "当前页面暂无说明。";
}

unsigned int pageIcon(Page page) {
    switch (page) {
        case Page::Overview: return 0xF624;
        case Page::Watchlist: return 0xF1E5;
        case Page::Account: return 0xF555;
        case Page::Strategy: return 0xF140;
        case Page::Backtest: return 0xF201;
        case Page::Risk: return 0xF3ED;
        case Page::Agent: return 0xF544;
        case Page::Journal: return 0xF02D;
    }
    return 0xF111;
}

const char* runtimeLabel(RuntimeState runtime) {
    switch (runtime) {
        case RuntimeState::Stopped: return "Stopped";
        case RuntimeState::Starting: return "Starting";
        case RuntimeState::Running: return "Running";
        case RuntimeState::Error: return "Error";
    }
    return "Unknown";
}

void showToast(std::string title, std::string message) {
    auto& dashboardState = state();
    dashboardState.toast.visible = true;
    dashboardState.toast.title = std::move(title);
    dashboardState.toast.message = std::move(message);
}

void dismissToast() {
    auto& dashboardState = state();
    dashboardState.toast.visible = false;
    dashboardState.toast.title.clear();
    dashboardState.toast.message.clear();
}

void startRuntimeMock() {
    auto& dashboardState = state();
    dashboardState.runtime = RuntimeState::Running;
    dashboardState.runId = "paper-20260503-001";
    showToast("Runtime Started", "Mock runtime is now running");
}

void requestStopRuntime() {
    state().confirmStopVisible = true;
}

void cancelStopRuntime() {
    state().confirmStopVisible = false;
}

void confirmStopRuntime() {
    state().runtime = RuntimeState::Stopped;
    state().confirmStopVisible = false;
    showToast("Runtime Stopped", "Mock runtime has been stopped");
}

void toggleSidebar() {
    state().sidebarCollapsed = !state().sidebarCollapsed;
}

} // namespace app::dashboard
