# webview_runtime

`justjavac/webview_runtime` is the low-level host layer that turns native ops
into JavaScript-facing runtime extensions.

Use:

- `justjavac/webview` for the raw native `Webview`
- `justjavac/webview_runtime` for `Extension`, `ExtensionHost`, `App`, ops
  dispatch, and the `window.__MoonBit__` bridge
- `justjavac/webview_bootstrap` for `app.json` parsing and editable config
  documents
- `justjavac/webview_app` for high-level app creation and extension ordering

This package does not decide which extensions are installed. That composition
step now lives in `justjavac/webview_app`, while built-in extension packages
live in the sibling [`extensions/`](../extensions) workspace.

## JavaScript Surface

The runtime installs a single global object:

- `window.__MoonBit__.core.ops.*`
- `window.__MoonBit__.events.on(...)`
- `window.__MoonBit__.extension("<name>")`
- `window.__MoonBit__.<extension>.*`

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
  "extensions/path" @path,
  "justjavac/webview" @webview,
  "justjavac/webview_runtime" @runtime,
}

fn main {
  let webview = @webview.Webview::new(debug=1)
  @runtime.install_extension(webview, @path.extension())
  webview.run()
}
```

For normal app-style startup, prefer `justjavac/webview_app`:

```moonbit
import {
  "extensions/fs" @fs,
  "extensions/path" @path,
  "justjavac/webview_app" @app,
}

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
