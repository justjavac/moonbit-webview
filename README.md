# Lepus

MoonBit framework for building Tauri/Electron-style desktop apps on top of [webview](https://github.com/webview/webview), with a small runtime, manifest-driven control plane, and opt-in JS-facing extensions so applications only link the native capabilities they actually use.

The repository is organized into these layers:

- `justjavac/lepus`: low-level native webview binding
- `justjavac/lepus_manifest`: declarative `app.json` contract types
- `justjavac/lepus_core`: native/JS bridge, ops runtime, resource tables, extension host
- `justjavac/lepus_runtime`: `App`, windows, and lifecycle orchestration
- `justjavac/lepus_bootstrap`: `app.json` loading, editing, and validation helpers
- `justjavac/lepus_app`: high-level app composition and runtime construction
- `justjavac/lepus_catalog`: metadata discovery, schema loading, and explicit link planning
- `justjavac/lepus_tooling`: catalog queries plus generated registry-module edits
- `extensions/*`: built-in extensions such as `fs`, `path`, `dialog`, `clipboard`, `shell`, `notification`, `tray`, and `globalHotkey`

The product direction is:

- keep the runtime small
- keep extension linking explicit
- keep AI support in metadata, manifests, diagnostics, and tooling rather than in every shipped runtime

In one sentence: Lepus is aiming for "small runtime, rich control plane".

## Direction

The near-term direction is:

- keep Lepus framework-first rather than app-template-first
- keep extensions opt-in so shipped binaries stay small
- add AI support in metadata, tooling, diagnostics, and manifest control-plane layers rather than the default runtime of every app
- simplify the public app surface around `create_app(...)` and `create_app_from_file(...)`

JavaScript now uses a single global entry:

- `window.__MoonBit__`

## Project Model

Lepus separates declaration, linking, and runtime state:

- `app.json` declares app shape and extension configuration
- application code or generated project files explicitly link the extensions that should ship
- the runtime only installs the extensions that were actually linked and selected

This separation is important for binary size. Metadata and manifests may help AI discover and configure extensions, but they should not imply that every built-in extension gets linked automatically.

## Quick Start

Low-level usage stays very small:

```moonbit
fn main {
  @webview.Webview::new(debug=1)
  ..set_title("Lepus")
  ..set_size(800, 600, @webview.SizeHint::None)
  ..set_html("<html><body><h1>Hello</h1></body></html>")
  .run()
}
```

App-style startup now goes through `justjavac/lepus_app`:

Explicit linking can still be written by hand with `ExtensionRegistry`, or generated through `justjavac/lepus_tooling` as explicit `moon.pkg` imports plus a checked-in registry module.

```moonbit
import {
  "extensions/fs" @fs,
  "extensions/path" @path,
  "justjavac/lepus_app" @app,
  "justjavac/lepus_manifest" @manifest,
  "justjavac/lepus_runtime" @wvrt,
}

fn main {
  let manifest = @manifest.AppManifest::new(
    @manifest.WindowManifest::new("Demo", 900, 700),
    @manifest.AppEntry::Html("<html></html>"),
    debug=1,
  )
  let registry = @app.ExtensionRegistry::new()
  let _ = registry.register(@fs.spec())
  let _ = registry.register(@path.spec())
  let runtime : @wvrt.App = match @app.create_app(manifest, registry) {
    Ok(app) => app
    Err(error) => abort(error)
  }
  runtime.run()
}
```

Or from `app.json`:

```moonbit
fn main {
  let registry = @app.ExtensionRegistry::new()
  let _ = registry.register(@fs.spec())
  let _ = registry.register(@path.spec())
  let runtime = match @app.create_app_from_file("app.json", registry) {
    Ok(app) => app
    Err(error) => abort(error)
  }
  runtime.run()
}
```

`app.json` declares which linked extensions are enabled and can pass per-extension options:

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
    "justjavac/lepus-fs": true,
    "justjavac/lepus-path": {}
  },
  "debug": 1
}
```

The important rule is:

- `app.json` configures extensions
- explicit project code or generated registry code links extensions

Even when catalog or tooling generates those edits, the final project should still make extension linking explicit and reviewable.

## JavaScript Surface

The runtime installs one global object:

- `window.__MoonBit__.events.on(...)`
- `window.__MoonBit__.<extension>.*`
- `window.__MoonBit__.core.invokeOp(name, payload)` for low-level debugging and custom experiments

Example:

```js
await window.__MoonBit__.fs.readFile("demo.txt");
await window.__MoonBit__.path.resolve({ path: "." });
await window.__MoonBit__.core.invokeOp("ext:path/resolve", { path: "." });
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
