# Extensions

This workspace contains the built-in extension packages that plug into
`justjavac/webview_runtime`.

They now participate in app startup through `justjavac/webview_app`, and each
package exposes an `app_extension()` helper for app-style installation.

## Layout

- `fs/`: filesystem helpers and rid-based file streaming
- `path/`: path transforms such as `resolve`, `join`, and `dirname`
- `dialog/`: native message and file dialogs
- `clipboard/`: adapter over the published `justjavac/clipboard` package
- `shell/`: open external targets and reveal files
- `notification/`: native notification helpers
- `tray/`: native tray icon helpers
- `global_hotkey/`: native global hotkey helpers

For host-agnostic desktop features, prefer the sibling standalone modules
[`notification/`](../notification), [`tray/`](../tray), and
[`global_hotkey/`](../global_hotkey), plus the published Mooncakes package
[`justjavac/clipboard`](https://mooncakes.io/docs/justjavac/clipboard). The
extensions in this workspace adapt those capabilities into the webview runtime.

## Usage

Add the workspace as a local dependency:

```json
{
  "deps": {
    "extensions": {
      "path": "../extensions"
    }
  }
}
```

### Direct installation on a raw webview

```moonbit
import {
  "extensions/path" @path,
  "justjavac/webview" @webview,
  "justjavac/webview_runtime" @runtime,
}

fn main {
  let webview = @webview.Webview::new()
  @runtime.install_extension(webview, @path.extension())
  webview.run()
}
```

### App-style installation

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

In this model:

- MoonBit code decides which extensions are installed.
- `app.json.extensions` only carries per-extension options.
- JavaScript talks to one global object: `window.__MoonBit__`.

Example config:

```json
{
  "window": { "title": "Demo", "width": 900, "height": 700 },
  "entry": { "kind": "file", "value": "app.html" },
  "extensions": {
    "fs": {},
    "path": {}
  },
  "debug": 1
}
```

## JavaScript Surface

Built-in and custom extensions share the same shape:

```js
await window.__MoonBit__.fs.readFile("demo.txt");
await window.__MoonBit__.path.resolve({ path: "." });
window.__MoonBit__.events.on("fs.activity", console.log);
```

Use `window.__MoonBit__.extension("<name>")` when the extension name is only
known dynamically.

## Notes

- These extensions currently target `native`.
- `fs.open(...)` and `fs.openFile(...)` return a resource id in the `rid` field.
- `path` is pure and side-effect free.
- `dialog`, `shell`, `notification`, `tray`, and `globalHotkey` currently ship
  Windows-native implementations in this repository.
- `clipboard` follows the upstream
  [`justjavac/clipboard`](https://mooncakes.io/docs/justjavac/clipboard)
  platform matrix.


