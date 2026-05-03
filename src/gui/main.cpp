#include "app/app.h"

#include <glad/glad.h>

#ifndef GLFW_INCLUDE_NONE
#define GLFW_INCLUDE_NONE
#endif
#include <GLFW/glfw3.h>

#include <algorithm>
#include <chrono>
#include <cstdio>
#include <string>
#include <thread>

namespace {

float dpiScaleFor(GLFWwindow* window, int framebufferWidth, int framebufferHeight) {
    int windowWidth = 0;
    int windowHeight = 0;
    glfwGetWindowSize(window, &windowWidth, &windowHeight);
    if (windowWidth <= 0 || windowHeight <= 0) {
        return 1.0f;
    }

    const float scaleX = static_cast<float>(framebufferWidth) / static_cast<float>(windowWidth);
    const float scaleY = static_cast<float>(framebufferHeight) / static_cast<float>(windowHeight);
    return std::max(1.0f, (scaleX + scaleY) * 0.5f);
}

void updateWindowTitle(GLFWwindow* window, const char* baseTitle, double fps) {
    if (!app::showFrameCountInTitle()) {
        return;
    }

    char title[160];
    std::snprintf(title, sizeof(title), "%s  %.1f FPS", baseTitle, fps);
    glfwSetWindowTitle(window, title);
}

} // namespace

int main() {
    if (!glfwInit()) {
        std::fprintf(stderr, "Failed to initialize GLFW.\n");
        return 1;
    }

    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
#ifdef __APPLE__
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GLFW_TRUE);
#endif

    GLFWwindow* window = glfwCreateWindow(
        app::initialWindowWidth(),
        app::initialWindowHeight(),
        app::windowTitle(),
        nullptr,
        nullptr);

    if (window == nullptr) {
        std::fprintf(stderr, "Failed to create GLFW window.\n");
        glfwTerminate();
        return 1;
    }

    glfwMakeContextCurrent(window);
    glfwSwapInterval(0);

    if (!gladLoadGLLoader(reinterpret_cast<GLADloadproc>(glfwGetProcAddress))) {
        std::fprintf(stderr, "Failed to initialize GLAD.\n");
        glfwDestroyWindow(window);
        glfwTerminate();
        return 1;
    }

    if (!app::initialize(window)) {
        std::fprintf(stderr, "Failed to initialize DhQuant GUI app.\n");
        glfwDestroyWindow(window);
        glfwTerminate();
        return 1;
    }

    using Clock = std::chrono::steady_clock;
    auto previous = Clock::now();
    auto fpsWindowStart = previous;
    int frames = 0;

    while (!glfwWindowShouldClose(window)) {
        const auto now = Clock::now();
        const float deltaSeconds = std::chrono::duration<float>(now - previous).count();
        previous = now;

        int framebufferWidth = 0;
        int framebufferHeight = 0;
        glfwGetFramebufferSize(window, &framebufferWidth, &framebufferHeight);
        const float dpiScale = dpiScaleFor(window, framebufferWidth, framebufferHeight);
        const float pointerScale = dpiScale;

        const bool shouldRender = app::update(
            window,
            deltaSeconds,
            framebufferWidth,
            framebufferHeight,
            dpiScale,
            pointerScale);

        if (shouldRender) {
            app::render(framebufferWidth, framebufferHeight, dpiScale);
            glfwSwapBuffers(window);
            ++frames;
        }

        const auto fpsElapsed = std::chrono::duration<double>(Clock::now() - fpsWindowStart).count();
        if (fpsElapsed >= 1.0) {
            updateWindowTitle(window, app::windowTitle(), static_cast<double>(frames) / fpsElapsed);
            frames = 0;
            fpsWindowStart = Clock::now();
        }

        const bool animate = app::isAnimating();
        const double fpsLimit = app::frameRateLimit();
        if (animate) {
            if (fpsLimit > 0.0) {
                const auto frameDuration = std::chrono::duration<double>(1.0 / fpsLimit);
                const auto workDuration = Clock::now() - now;
                if (workDuration < frameDuration) {
                    std::this_thread::sleep_for(frameDuration - workDuration);
                }
            }
            glfwPollEvents();
        } else {
            glfwWaitEvents();
        }
    }

    app::shutdown();
    glfwDestroyWindow(window);
    glfwTerminate();
    return 0;
}
