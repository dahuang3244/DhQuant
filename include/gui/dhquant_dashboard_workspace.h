#pragma once

#include "components/theme.h"
#include "core/dsl.h"

namespace app::dashboard {

void renderWorkspace(core::dsl::Ui& ui, const components::theme::ThemeColorTokens& tokens, float width, float height);

} // namespace app::dashboard
