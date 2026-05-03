include_guard(GLOBAL)

get_filename_component(EUINEO_SDK_DIR "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)

add_library(euineo::euineo SHARED IMPORTED GLOBAL)
set_target_properties(euineo::euineo PROPERTIES
    IMPORTED_LOCATION "${EUINEO_SDK_DIR}/lib/libeuineo.dylib"
    INTERFACE_INCLUDE_DIRECTORIES "${EUINEO_SDK_DIR}/include"
)

add_library(euineo::glfw SHARED IMPORTED GLOBAL)
set_target_properties(euineo::glfw PROPERTIES
    IMPORTED_LOCATION "${EUINEO_SDK_DIR}/lib/libglfw.3.dylib"
    INTERFACE_INCLUDE_DIRECTORIES "${EUINEO_SDK_DIR}/include"
)

function(euineo_configure_app target_name)
    target_link_libraries(${target_name} PRIVATE euineo::euineo euineo::glfw)

    if(APPLE)
        target_link_libraries(${target_name} PRIVATE
            "-framework OpenGL"
            "-framework Cocoa"
            "-framework IOKit"
            "-framework CoreFoundation"
        )
        set_target_properties(${target_name} PROPERTIES
            BUILD_RPATH "@loader_path/assets/lib;${EUINEO_SDK_DIR}/lib"
            INSTALL_RPATH "@loader_path/assets/lib"
        )
    endif()

    add_custom_command(TARGET ${target_name} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory
        "$<TARGET_FILE_DIR:${target_name}>/assets/lib"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${EUINEO_SDK_DIR}/lib/libeuineo.dylib"
        "$<TARGET_FILE_DIR:${target_name}>/assets/lib/libeuineo.dylib"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${EUINEO_SDK_DIR}/lib/libglfw.3.dylib"
        "$<TARGET_FILE_DIR:${target_name}>/assets/lib/libglfw.3.dylib"
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${EUINEO_SDK_DIR}/fonts"
        "$<TARGET_FILE_DIR:${target_name}>/assets/fonts"
    )
endfunction()
