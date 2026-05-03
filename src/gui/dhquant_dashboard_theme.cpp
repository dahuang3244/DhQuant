#include "gui/dhquant_dashboard_theme.h"

namespace app::dashboard {

components::theme::ThemeColorTokens dashboardTheme() {
    auto tokens = components::theme::DarkThemeColors();
    tokens.background = {0.045f, 0.052f, 0.060f, 1.0f};
    tokens.surface = {0.070f, 0.082f, 0.094f, 1.0f};
    tokens.surfaceHover = {0.100f, 0.116f, 0.132f, 1.0f};
    tokens.surfaceActive = {0.120f, 0.150f, 0.158f, 1.0f};
    tokens.primary = {0.180f, 0.620f, 0.520f, 1.0f};
    tokens.border = {0.180f, 0.220f, 0.245f, 1.0f};
    tokens.text = {0.900f, 0.940f, 0.935f, 1.0f};
    return tokens;
}

core::Color navIconColor(Page page, const components::theme::ThemeColorTokens& tokens) {
    if (state().page == page) {
        return tokens.primary;
    }
    return {0.620f, 0.700f, 0.700f, 1.0f};
}

core::Color runtimeColor(RuntimeState runtime, const components::theme::ThemeColorTokens& tokens) {
    switch (runtime) {
        case RuntimeState::Running:
            return tokens.primary;
        case RuntimeState::Starting:
            return {0.760f, 0.620f, 0.300f, 1.0f};
        case RuntimeState::Error:
            return {0.820f, 0.280f, 0.260f, 1.0f};
        case RuntimeState::Stopped:
            return {0.460f, 0.510f, 0.540f, 1.0f};
    }
    return tokens.border;
}

} // namespace app::dashboard
