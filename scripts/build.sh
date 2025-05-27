cd webview

cmake -G "Ninja Multi-Config" -B build -S . \
    -DCMAKE_BUILD_TYPE=Release \
    -DWEBVIEW_BUILD_TESTS=OFF \
    -DWEBVIEW_BUILD_EXAMPLES=OFF \
    -DWEBVIEW_USE_CLANG_TOOLS=OFF \
    -DWEBVIEW_ENABLE_CHECKS=OFF \
    -DWEBVIEW_USE_CLANG_TIDY=OFF \
    -DWEBVIEW_BUILD_DOCS=OFF \
    -DWEBVIEW_USE_CLANG_FORMAT=OFF

cmake --build build --config Release

cd ..
