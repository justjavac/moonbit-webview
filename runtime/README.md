# lepus_runtime

`justjavac/lepus_runtime` is the lifecycle layer for app and window orchestration.
It sits on top of `justjavac/lepus_core`, which now owns the native/JS bridge,
ops runtime, resource tables, and low-level extension installation.

Use:

- `justjavac/lepus` for the raw native `Webview`
- `justjavac/lepus_core` for `Extension`, `ExtensionSpec`, low-level install,
  and the `window.__MoonBit__` bridge
- `justjavac/lepus_runtime` for `App`, `AppWindow`, and multi-window lifecycle
- `justjavac/lepus_bootstrap` for manifest loading/editing
- `justjavac/lepus_app` for registry-driven app planning and creation

This package does not decide which extensions are installed. That composition
step now lives in `justjavac/lepus_app`, while built-in extension packages
live in the sibling [`extensions/`](../extensions) workspace.

## JavaScript Surface

The runtime installs a single global object:

- `window.__MoonBit__.events.on(...)`
- `window.__MoonBit__.<extension>.*`
- `window.__MoonBit__.core.invokeOp(name, payload)` for low-level debugging

Built-in and custom extensions use the same shape. For example:

```js
await window.__MoonBit__.fs.readFile("demo.txt");
await window.__MoonBit__.echo.ping({ text: "hello" });
window.__MoonBit__.events.on("fs.activity", console.log);
```

## Typical Usage

For direct installation on a raw webview:

```moonbit
import {
  "justjavac/lepus_core" @core,
  "extensions/path" @path,
  "justjavac/lepus" @webview,
}

fn main {
  let webview = @webview.Webview::new(debug=1)
  @core.install_extension(webview, @path.extension())
  webview.run()
}
```

For normal app-style startup, prefer `justjavac/lepus_app`:

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
