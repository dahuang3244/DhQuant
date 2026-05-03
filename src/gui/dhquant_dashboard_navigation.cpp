#include "gui/dhquant_dashboard_navigation.h"

#include "gui/dhquant_dashboard_layout.h"
#include "gui/dhquant_dashboard_state.h"
#include "gui/dhquant_dashboard_theme.h"
#include "components/components.h"

#include <array>
#include <string>

namespace app::dashboard {
namespace {

struct NavItem {
    Page page;
    const char* id;
};

constexpr std::array<NavItem, 8> kNavItems = {{
    {Page::Overview, "dhq.sidebar.overview"},
    {Page::Watchlist, "dhq.sidebar.watchlist"},
    {Page::Account, "dhq.sidebar.account"},
    {Page::Strategy, "dhq.sidebar.strategy"},
    {Page::Backtest, "dhq.sidebar.backtest"},
    {Page::Risk, "dhq.sidebar.risk"},
    {Page::Agent, "dhq.sidebar.agent"},
    {Page::Journal, "dhq.sidebar.journal"},
}};

} // namespace

void renderSidebar(core::dsl::Ui& ui, const components::theme::ThemeColorTokens& tokens, float height) {
    const float slideX = state().sidebarCollapsed
        ? -(layout::kSidebarWidth - layout::kSidebarCollapsedWidth)
        : 0.0f;
    const float contentOpacity = state().sidebarCollapsed ? 0.0f : 1.0f;
    const float compactOpacity = state().sidebarCollapsed ? 1.0f : 0.0f;
    const auto sidebarTransition = core::Transition::make(0.24f, core::Ease::OutCubic)
        .animate(core::AnimProperty::Transform | core::AnimProperty::Opacity);

    ui.stack("dhq.sidebar")
        .x(slideX)
        .y(0.0f)
        .size(layout::kSidebarWidth, height)
        .transition(sidebarTransition)
        .animate(core::AnimProperty::Frame)
        .content([&] {
            ui.rect("dhq.sidebar.bg")
                .size(layout::kSidebarWidth, height)
                .color(tokens.surface)
                .border(1.0f, {0.120f, 0.150f, 0.165f, 1.0f})
                .build();

            components::button(ui, "dhq.sidebar.toggle")
                .size(36.0f, 36.0f)
                .text("")
                .icon(state().sidebarCollapsed ? 0xF054 : 0xF053)
                .fontSize(17.0f)
                .iconSize(14.0f)
                .radius(9.0f)
                .colors(tokens.surfaceHover, tokens.surfaceActive, tokens.surface)
                .textColor(tokens.text)
                .border(1.0f, tokens.border)
                .shadow(0.0f, 0.0f, 0.0f, {0.0f, 0.0f, 0.0f, 0.0f})
                .translate(layout::kSidebarWidth - 46.0f, 18.0f)
                .transition(0.16f)
                .pressScale(0.98f)
                .onClick(toggleSidebar)
                .build();

            components::text(ui, "dhq.sidebar.title", tokens)
                .x(24.0f)
                .y(26.0f)
                .size(210.0f, 34.0f)
                .text("DhQuant")
                .fontSize(24.0f)
                .fontWeight(700)
                .opacity(contentOpacity)
                .transition(sidebarTransition)
                .animate(core::AnimProperty::Opacity)
                .color(tokens.text)
                .build();

            float y = 96.0f;
            for (const auto& item : kNavItems) {
                const bool selected = state().page == item.page;
                components::button(ui, item.id)
                    .size(224.0f, 42.0f)
                    .text(pageLabel(item.page))
                    .fontSize(15.0f)
                    .radius(9.0f)
                    .colors(selected ? tokens.surfaceActive : tokens.surface,
                            tokens.surfaceHover,
                            tokens.surfaceActive)
                    .textColor(selected ? tokens.text : core::Color{0.620f, 0.690f, 0.700f, 1.0f})
                    .border(1.0f, selected ? tokens.border : core::Color{0.0f, 0.0f, 0.0f, 0.0f})
                    .shadow(0.0f, 0.0f, 0.0f, {0.0f, 0.0f, 0.0f, 0.0f})
                    .opacity(contentOpacity)
                    .translate(24.0f, y)
                    .transition(sidebarTransition)
                    .pressScale(0.98f)
                    .onClick([page = item.page] {
                        state().page = page;
                    })
                    .build();
                y += 52.0f;
            }

            y = 96.0f;
            for (const auto& item : kNavItems) {
                const bool selected = state().page == item.page;
                components::button(ui, std::string(item.id) + ".compact")
                    .size(36.0f, 36.0f)
                    .text("")
                    .icon(pageIcon(item.page))
                    .iconSize(15.0f)
                    .radius(9.0f)
                    .colors(selected ? tokens.surfaceActive : tokens.surface,
                            tokens.surfaceHover,
                            tokens.surfaceActive)
                    .iconColor(navIconColor(item.page, tokens))
                    .textColor(navIconColor(item.page, tokens))
                    .border(1.0f, selected ? tokens.border : core::Color{0.0f, 0.0f, 0.0f, 0.0f})
                    .shadow(0.0f, 0.0f, 0.0f, {0.0f, 0.0f, 0.0f, 0.0f})
                    .opacity(compactOpacity)
                    .disabled(!state().sidebarCollapsed)
                    .translate(layout::kSidebarWidth - layout::kSidebarCollapsedWidth + 10.0f, y + 3.0f)
                    .transition(sidebarTransition)
                    .pressScale(0.98f)
                    .onClick([page = item.page] {
                        state().page = page;
                    })
                    .build();
                y += 52.0f;
            }
        })
        .build();
}

} // namespace app::dashboard
