#pragma once

#include "components/theme.h"
#include "core/dsl.h"

namespace app::dashboard {

void renderTopbar(core::dsl::Ui& ui, const components::theme::ThemeColorTokens& tokens, float width);

} // namespace app::dashboard
