#pragma once

#include "gui/dhquant_dashboard_state.h"
#include "components/theme.h"
#include "core/primitive.h"

namespace app::dashboard {

components::theme::ThemeColorTokens dashboardTheme();
core::Color navIconColor(Page page, const components::theme::ThemeColorTokens& tokens);
core::Color runtimeColor(RuntimeState runtime, const components::theme::ThemeColorTokens& tokens);

} // namespace app::dashboard
