# EUI-NEO SDK for DhQuant

This folder is the decoupled EUI-NEO SDK used by DhQuant in Runtime/Core mode.
DhQuant owns and compiles its own pages, while EUI-NEO provides reusable runtime
headers, components, OpenGL primitives, image/text/network implementations, and
runtime assets.

## Layout

```text
assets/
  cmake/EuineoSdk.cmake
  include/
    app/
    core/
    components/
    3rd/
    GLFW/
    glad/
    KHR/
  lib/
    libeuineo.dylib
    libglfw.3.dylib
  fonts/
```

The top-level `include/app.h` and `include/euineo_export.h` are compatibility
forwarders. New code should include the structured paths directly.

## CMake Usage

```cmake
include("${CMAKE_SOURCE_DIR}/assets/cmake/EuineoSdk.cmake")

add_executable(dhquant_gui
    main.cpp
    app/dhquant_dashboard.cpp
)

euineo_configure_app(dhquant_gui)
```

Application pages should keep using EUI-NEO's DSL pattern:

```cpp
#include "app/dsl_app.h"
#include "components/components.h"

namespace app {

const DslAppConfig& dslAppConfig();
void compose(core::dsl::Ui& ui, const core::dsl::Screen& screen);

} // namespace app
```

## Runtime Notes

- The final executable must be able to load `assets/lib/libeuineo.dylib` and
  `assets/lib/libglfw.3.dylib`.
- `euineo_configure_app()` sets macOS rpaths and copies the required runtime
  libraries and fonts beside the executable.
- Do not add `EUI-NEO-main` to DhQuant include paths. If that is required, the
  SDK package is incomplete.
