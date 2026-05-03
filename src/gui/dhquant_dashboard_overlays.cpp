#include "gui/dhquant_dashboard_overlays.h"

#include "gui/dhquant_dashboard_state.h"
#include "components/components.h"

namespace app::dashboard {

void renderOverlays(core::dsl::Ui& ui, const components::theme::ThemeColorTokens& tokens, const core::dsl::Screen& screen) {
    components::dialog(ui, "dhq.overlays.confirmStop")
        .open(state().confirmStopVisible)
        .screen(screen.width, screen.height)
        .size(430.0f, 220.0f)
        .title("停止 mock runtime")
        .message("当前只是 P1 mock 状态，但这里先保留真实运行时停止前的确认路径。")
        .primaryText("停止")
        .secondaryText("取消")
        .theme(tokens)
        .onPrimary(confirmStopRuntime)
        .onSecondary(cancelStopRuntime)
        .onClose(cancelStopRuntime)
        .build();

    components::toast(ui, "dhq.overlays.toast")
        .visible(state().toast.visible)
        .screen(screen.width, screen.height)
        .title(state().toast.title)
        .message(state().toast.message)
        .theme(tokens)
        .duration(2.8f)
        .onDismiss(dismissToast)
        .onAutoDismiss(dismissToast)
        .build();
}

} // namespace app::dashboard
