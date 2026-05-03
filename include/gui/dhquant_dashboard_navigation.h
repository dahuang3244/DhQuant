#pragma once

#include "components/theme.h"
#include "core/dsl.h"

namespace app::dashboard {

void renderSidebar(core::dsl::Ui& ui, const components::theme::ThemeColorTokens& tokens, float height);

} // namespace app::dashboard
