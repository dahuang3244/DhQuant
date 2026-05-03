#include "gui/dhquant_dashboard_workspace.h"

#include "gui/dhquant_dashboard_layout.h"
#include "gui/dhquant_dashboard_state.h"
#include "components/components.h"

namespace app::dashboard {

void renderWorkspace(core::dsl::Ui& ui, const components::theme::ThemeColorTokens& tokens, float width, float height) {
    ui.stack("dhq.workspace")
        .x(0.0f)
        .y(layout::kTopbarHeight)
        .size(width, height)
        .content([&] {
            ui.rect("dhq.workspace.bg")
                .size(width, height)
                .color(tokens.background)
                .build();

            ui.rect("dhq.workspace.placeholder")
                .x(layout::kOuterPadding)
                .y(layout::kOuterPadding)
                .size(width - layout::kOuterPadding * 2.0f, 220.0f)
                .radius(layout::kPanelRadius)
                .color(tokens.surface)
                .border(1.0f, tokens.border)
                .build();

            components::text(ui, "dhq.workspace.title", tokens)
                .x(layout::kOuterPadding + 24.0f)
                .y(layout::kOuterPadding + 24.0f)
                .size(width - 96.0f, 34.0f)
                .text(pageLabel(state().page))
                .fontSize(26.0f)
                .fontWeight(700)
                .color(tokens.text)
                .build();

            components::text(ui, "dhq.workspace.hint", tokens)
                .x(layout::kOuterPadding + 24.0f)
                .y(layout::kOuterPadding + 72.0f)
                .size(width - 96.0f, 64.0f)
                .text(pageHint(state().page))
                .fontSize(16.0f)
                .lineHeight(22.0f)
                .wrap(true)
                .color({0.620f, 0.700f, 0.700f, 1.0f})
                .build();
        })
        .build();
}

} // namespace app::dashboard
