#include "app/dsl_app.h"
#include "gui/dhquant_dashboard_layout.h"
#include "gui/dhquant_dashboard_navigation.h"
#include "gui/dhquant_dashboard_overlays.h"
#include "gui/dhquant_dashboard_state.h"
#include "gui/dhquant_dashboard_theme.h"
#include "gui/dhquant_dashboard_topbar.h"
#include "gui/dhquant_dashboard_workspace.h"

namespace app {

const DslAppConfig& dslAppConfig() {
    static const DslAppConfig config = DslAppConfig{}
        .title("DhQuant")
        .pageId("dhquant_dashboard")
        .clearColor({0.045f, 0.052f, 0.060f, 1.0f})
        .windowSize(1440, 900)
        .fps(90.0)
        .fonts("assets/fonts/YouSheBiaoTiHei-2.ttf",
               "assets/fonts/Font Awesome 7 Free-Solid-900.otf");
    return config;
}

void compose(core::dsl::Ui& ui, const core::dsl::Screen& screen) {
    const auto tokens = dashboard::dashboardTheme();
    const float activeSidebarWidth = dashboard::state().sidebarCollapsed
        ? dashboard::layout::kSidebarCollapsedWidth
        : dashboard::layout::kSidebarWidth;
    const float mainWidth = screen.width - activeSidebarWidth;
    const float workspaceHeight = screen.height - dashboard::layout::kTopbarHeight;
    const core::dsl::Screen mainScreen{mainWidth, screen.height};

    ui.stack("dhq.root")
        .size(screen.width, screen.height)
        .content([&] {
            ui.rect("dhq.background")
                .size(screen.width, screen.height)
                .color(tokens.background)
                .build();

            dashboard::renderSidebar(ui, tokens, screen.height);

            ui.stack("dhq.main")
                .x(activeSidebarWidth)
                .y(0.0f)
                .size(mainWidth, screen.height)
                .content([&] {
                    dashboard::renderTopbar(ui, tokens, mainWidth);
                    dashboard::renderWorkspace(ui, tokens, mainWidth, workspaceHeight);
                    dashboard::renderOverlays(ui, tokens, mainScreen);
                })
                .build();
        })
        .build();
}

} // namespace app
