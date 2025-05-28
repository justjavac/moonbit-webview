cmake_minimum_required(VERSION 3.16)
project(webview-builder LANGUAGES C CXX)

if(NOT CMAKE_BUILD_TYPE)
  message(STATUS "No CMAKE_BUILD_TYPE specified, defaulting to Debug")
  set(CMAKE_BUILD_TYPE Debug CACHE STRING "Build type" FORCE)
endif()

set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/target/native/release/build/main")

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")

include(FetchContent)

set(WEBVIEW_BUILD_TESTS             OFF     CACHE BOOL   "" FORCE)
set(WEBVIEW_BUILD_EXAMPLES          OFF     CACHE BOOL   "" FORCE)
set(WEBVIEW_USE_CLANG_TOOLS         OFF     CACHE BOOL   "" FORCE)
set(WEBVIEW_ENABLE_CHECKS           OFF     CACHE BOOL   "" FORCE)
set(WEBVIEW_USE_CLANG_TIDY          OFF     CACHE BOOL   "" FORCE)
set(WEBVIEW_BUILD_DOCS              OFF     CACHE BOOL   "" FORCE)
set(WEBVIEW_USE_CLANG_FORMAT        OFF     CACHE BOOL   "" FORCE)
set(WEBVIEW_BUILD_SHARED_LIBRARY    ON      CACHE BOOL   "" FORCE)
set(WEBVIEW_BUILD_STATIC_LIBRARY    ON     CACHE BOOL   "" FORCE)
set(WEBVIEW_PACKAGE_HEADERS         ON      CACHE BOOL   "" FORCE)
set(WEBVIEW_INSTALL_TARGETS         ON      CACHE BOOL   "" FORCE)

FetchContent_Declare(
    webview
    GIT_REPOSITORY https://github.com/webview/webview
    GIT_TAG master)

FetchContent_MakeAvailable(webview)
