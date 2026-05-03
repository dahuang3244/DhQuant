#include "gui/dhquant_dashboard_topbar.h"

#include "gui/dhquant_dashboard_layout.h"
#include "gui/dhquant_dashboard_state.h"
#include "gui/dhquant_dashboard_theme.h"
#include "components/components.h"

namespace app::dashboard {

void renderTopbar(core::dsl::Ui& ui, const components::theme::ThemeColorTokens& tokens, float width) {
    ui.stack("dhq.topbar")
        .x(0.0f)
        .y(0.0f)
        .size(width, layout::kTopbarHeight)
        .content([&] {
            ui.rect("dhq.topbar.bg")
                .size(width, layout::kTopbarHeight)
                .color(tokens.background)
                .border(1.0f, {0.120f, 0.150f, 0.165f, 1.0f})
                .build();

            ui.rect("dhq.topbar.status.dot")
                .x(24.0f)
                .y(30.0f)
                .size(10.0f, 10.0f)
                .radius(5.0f)
                .color(runtimeColor(state().runtime, tokens))
                .build();

            components::text(ui, "dhq.topbar.status.text", tokens)
                .x(44.0f)
                .y(22.0f)
                .size(280.0f, 28.0f)
                .text(runtimeLabel(state().runtime))
                .fontSize(16.0f)
                .color(tokens.text)
                .build();

            components::text(ui, "dhq.topbar.runid", tokens)
                .x(180.0f)
                .y(22.0f)
                .size(360.0f, 28.0f)
                .text("runId: " + state().runId + " / " + state().connection)
                .fontSize(14.0f)
                .color({0.590f, 0.660f, 0.670f, 1.0f})
                .build();

            components::button(ui, "dhq.topbar.start")
                .size(116.0f, 40.0f)
                .text("启动")
                .fontSize(15.0f)
                .radius(9.0f)
                .primaryTheme(tokens)
                .disabled(state().runtime == RuntimeState::Running)
                .translate(width - 260.0f, 16.0f)
                .pressScale(0.98f)
                .onClick(startRuntimeMock)
                .build();

            components::button(ui, "dhq.topbar.stop")
                .size(116.0f, 40.0f)
                .text("停止")
                .fontSize(15.0f)
                .radius(9.0f)
                .secondaryTheme(tokens)
                .disabled(state().runtime != RuntimeState::Running)
                .translate(width - 132.0f, 16.0f)
                .pressScale(0.98f)
                .onClick(requestStopRuntime)
                .build();
        })
        .build();
}

} // namespace app::dashboard
