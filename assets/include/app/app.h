#pragma once

#include "core/euineo_export.h"

#ifndef GLFW_INCLUDE_NONE
#define GLFW_INCLUDE_NONE
#endif
#include <GLFW/glfw3.h>

namespace app {

EUINEO_API const char* windowTitle();
EUINEO_API bool showFrameCountInTitle();
EUINEO_API double frameRateLimit();
EUINEO_API int initialWindowWidth();
EUINEO_API int initialWindowHeight();
EUINEO_API bool initialize(GLFWwindow* window);
EUINEO_API bool update(GLFWwindow* window, float deltaSeconds, int windowWidth, int windowHeight, float dpiScale, float pointerScale);
EUINEO_API bool isAnimating();
EUINEO_API void render(int windowWidth, int windowHeight, float dpiScale);
EUINEO_API void shutdown();

} // namespace app
