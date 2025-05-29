# justjavac/webview

MoonBit bindings for webview, a tiny library for creating web-based desktop
GUIs.

![moonbit webview demo](examples/asserts/moonbit-webview.png)

```bash
cmake -G Ninja -B build -S . -D CMAKE_BUILD_TYPE=Release
cmake --build build
export DYLD_LIBRARY_PATH="$(pwd)/build/lib"
```
