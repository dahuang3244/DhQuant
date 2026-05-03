#pragma once

#include "components/theme.h"
#include "core/dsl.h"

namespace app::dashboard {

void renderOverlays(core::dsl::Ui& ui, const components::theme::ThemeColorTokens& tokens, const core::dsl::Screen& screen);

} // namespace app::dashboard
