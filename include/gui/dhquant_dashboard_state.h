#pragma once

#include <string>

namespace app::dashboard {

enum class Page {
    Overview,
    Watchlist,
    Account,
    Strategy,
    Backtest,
    Risk,
    Agent,
    Journal
};

enum class RuntimeState {
    Stopped,
    Starting,
    Running,
    Error
};

struct ToastState {
    bool visible = false;
    std::string title;
    std::string message;
};

struct DashboardState {
    Page page = Page::Overview;
    RuntimeState runtime = RuntimeState::Stopped;
    bool sidebarCollapsed = false;
    bool confirmStopVisible = false;
    std::string runId = "paper-20260503-001";
    std::string connection = "mock";
    ToastState toast;
};

DashboardState& state();

const char* pageLabel(Page page);
const char* pageHint(Page page);
unsigned int pageIcon(Page page);
const char* runtimeLabel(RuntimeState runtime);

void showToast(std::string title, std::string message);
void dismissToast();
void startRuntimeMock();
void requestStopRuntime();
void cancelStopRuntime();
void confirmStopRuntime();
void toggleSidebar();

} // namespace app::dashboard
