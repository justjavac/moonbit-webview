# justjavac/webview

MoonBit bindings for webview, a tiny library for creating web-based desktop
GUIs.

> ⚠️ This project is still in development.

![moonbit webview demo](asserts/moonbit-webview.png)

## Installation

Add `justjavac/webview` to your dependencies:

```shell
moon update
moon add justjavac/webview
```

## Config

Config your `moon.pkg.json` file:

```json
{
  "is-main": true,
  "link": {
    "native": {
      "cc-flags": "-fwrapv -fsanitize=address -fsanitize=undefined",
      "cc-link-flags": "-L .mooncakes/justjavac/webview/lib -lwebview"
    }
  }
}
```

## Setup Env

On macOS, you need to tell the dynamic linker where to find your compiled `.dylib` files. From the project root, run:

```shell
export DYLD_LIBRARY_PATH="$(pwd)/.mooncakes/justjavac/webview/lib"
```

On Windows, you need to set the `PATH` environment variable to include the directory where the `webview.dll` is located.

```bat
set _CL_=/link /LIBPATH:.mooncakes\justjavac\webview\lib webview.lib /DEBUG
set PATH=%PATH%;.mooncakes\justjavac\webview\lib
```

Or power shell:

```powershell
$env:_CL_="/link /LIBPATH:.mooncakes\justjavac\webview\lib webview.lib /DEBUG"
$env:PATH="$env:PATH;.mooncakes\justjavac\webview\lib"
```

## Usage

```moonbit
let html =
  #| <html>
  #|   <body>
  #|     Hello, Moonbit!
  #|   </body>
  #| </html>

fn main {
  @webview.Webview::new(debug=1)
  ..set_title("Moonbit Webview Example")
  ..set_size(800, 600, @webview.SizeHint::None)
  ..set_html(html)
  ..run()
}
```

## Development

Build and test:

```shell
cmake -G Ninja -B build -S . -D CMAKE_BUILD_TYPE=Release
cmake --build build
export DYLD_LIBRARY_PATH="$(pwd)/lib"
# Or on Windows
# set _CL_=/link /LIBPATH:lib webview.lib /DEBUG
# set PATH=%PATH%;lib
# Or on Windows PowerShell
# $env:_CL_="/link /LIBPATH:lib webview.lib /DEBUG"
# $env:PATH="$env:PATH;lib"

moon update
moon install
moon run --target native -C examples 02_local
```

## License

MIT © justjavac
