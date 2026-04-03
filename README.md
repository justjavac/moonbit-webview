# MoonBit WebView

MoonBit bindings for [webview](https://github.com/webview/webview), plus a native app/runtime layer for building desktop apps with JS-facing extensions.

The repository is organized into five main layers:

- `justjavac/webview`: low-level native webview binding
- `justjavac/webview_runtime`: runtime host, op bridge, `App`, `Extension`
- `justjavac/webview_bootstrap`: `app.json` parsing and editable config documents
- `justjavac/webview_app`: app composition and extension installation
- `extensions/*`: built-in extensions such as `fs`, `path`, `dialog`, `clipboard`, `shell`, `notification`, `tray`, and `globalHotkey`

JavaScript now uses a single global entry:

- `window.__MoonBit__`

## Quick Start

Low-level usage stays very small:

```moonbit
fn main {
  @webview.Webview::new(debug=1)
  ..set_title("MoonBit WebView")
  ..set_size(800, 600, @webview.SizeHint::None)
  ..set_html("<html><body><h1>Hello</h1></body></html>")
  .run()
}
```

App-style startup now goes through `justjavac/webview_app`:

```moonbit
import {
  "extensions/fs" @fs,
  "extensions/path" @path,
  "justjavac/webview_app" @app,
  "justjavac/webview_bootstrap" @bootstrap,
  "justjavac/webview_runtime" @wvrt,
}

fn main {
  let config = @bootstrap.BootstrapAppConfig::new(
    @wvrt.WindowConfig::new("Demo", 900, 700),
    @wvrt.AppEntry::Html("<html></html>"),
    debug=1,
  )
  let runtime = match
    @app.create_app(
      config,
      extensions=[@fs.app_extension(), @path.app_extension()],
    ) {
    Ok(app) => app
    Err(error) => abort(error)
  }
  runtime.run()
}
```

Or from `app.json`:

```moonbit
fn main {
  let runtime = match
    @app.create_app_from_file(
      "app.json",
      extensions=[@fs.app_extension(), @path.app_extension()],
    ) {
    Ok(app) => app
    Err(error) => abort(error)
  }
  runtime.run()
}
```

`app.json` only carries extension options now. Extension enabling happens in MoonBit code:

```json
{
  "window": {
    "title": "Demo",
    "width": 960,
    "height": 720
  },
  "entry": {
    "kind": "file",
    "value": "app.html"
  },
  "extensions": {
    "fs": {},
    "path": {}
  },
  "debug": 1
}
```

## JavaScript Surface

The runtime installs one global object:

- `window.__MoonBit__.core.ops.*`
- `window.__MoonBit__.events.on(...)`
- `window.__MoonBit__.<extension>.*`
- `window.__MoonBit__.extension("<name>")`

Example:

```js
await window.__MoonBit__.fs.readFile("demo.txt");
await window.__MoonBit__.path.resolve({ path: "." });
window.__MoonBit__.events.on("fs.activity", console.log);
```

## Native Notes

This repo targets `native` only.

- Windows uses vendored static `webview.lib`
- macOS uses system `WebKit`
- Linux needs `pkg-config`, `libgtk-3-dev`, and `libwebkit2gtk-4.1-dev`
- Windows users still need Microsoft WebView2 Runtime installed
- `clipboard` comes from the published Mooncakes package `justjavac/clipboard`.
- WIP: `dialog`, `shell`, `notification`, `tray`, and `globalHotkey` are currently Windows-native in this repository.

## License

MIT. See [LICENSE.md](LICENSE.md).
