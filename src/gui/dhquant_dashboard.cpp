#include "app/dsl_app.h"
#include "components/components.h"

namespace app {
namespace {

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

void statusLine(core::dsl::Ui& ui, const components::theme::ThemeColorTokens& tokens) {
    ui.row("dhq.p0.status")
        .x(48.0f)
        .y(152.0f)
        .size(720.0f, 36.0f)
        .gap(10.0f)
        .alignItems(core::Align::CENTER)
        .content([&] {
            ui.rect("dhq.p0.status.dot")
                .size(10.0f, 10.0f)
                .radius(5.0f)
                .color(tokens.primary)
                .build();

            components::text(ui, "dhq.p0.status.text", tokens)
                .text("P0 shell compiled. Dashboard workspace is ready for P1.")
                .fontSize(17.0f)
                .color({0.660f, 0.740f, 0.735f, 1.0f})
                .build();
        })
        .build();
}

} // namespace

const DslAppConfig& dslAppConfig() {
    static const DslAppConfig config = DslAppConfig{}
        .title("DhQuant")
        .pageId("dhquant_dashboard")
        .clearColor({0.045f, 0.052f, 0.060f, 1.0f})
        .windowSize(1440, 900)
        .fps(90.0)
        .fonts("assets/fonts/YouSheBiaoTiHei-2.ttf",
               "assets/fonts/Font Awesome 7 Free-Solid-900.otf");
    return config;
}

void compose(core::dsl::Ui& ui, const core::dsl::Screen& screen) {
    const auto tokens = dashboardTheme();

    ui.stack("dhq.root")
        .size(screen.width, screen.height)
        .content([&] {
            ui.rect("dhq.background")
                .size(screen.width, screen.height)
                .color(tokens.background)
                .build();

            ui.rect("dhq.p0.panel")
                .x(32.0f)
                .y(32.0f)
                .size(760.0f, 204.0f)
                .radius(10.0f)
                .color(tokens.surface)
                .border(1.0f, {0.160f, 0.205f, 0.220f, 1.0f})
                .build();

            components::text(ui, "dhq.p0.eyebrow", tokens)
                .x(48.0f)
                .y(54.0f)
                .size(520.0f, 24.0f)
                .text("DHQUANT GUI / EUI-NEO SDK")
                .fontSize(13.0f)
                .color(tokens.primary)
                .build();

            components::text(ui, "dhq.p0.title", tokens)
                .x(48.0f)
                .y(86.0f)
                .size(680.0f, 48.0f)
                .text("DhQuant Dashboard")
                .fontSize(34.0f)
                .fontWeight(700)
                .color(tokens.text)
                .build();

            statusLine(ui, tokens);
        })
        .build();
}

} // namespace app
