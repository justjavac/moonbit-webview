# Extensions

This workspace contains the built-in extension packages that plug into
`justjavac/lepus_core` and `justjavac/lepus_app`.

They now participate in app startup through `justjavac/lepus_app`, and each
package exposes a `spec()` builder for registry-driven installation.

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
  "justjavac/lepus_core" @core,
  "extensions/path" @path,
  "justjavac/lepus" @webview,
}

fn main {
  let webview = @webview.Webview::new()
  @core.install_extension(webview, @path.extension())
  webview.run()
}
```

### App-style installation

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

In this model:

- MoonBit code registers which extensions are available.
- `justjavac/lepus_tooling` can generate the same explicit registry-module edits from metadata when you do not want to hand-maintain the registry.
- `app.json.extensions` enables or disables registered extensions and can pass options.
- JavaScript talks to one global object: `window.__MoonBit__`.
- Each extension owns `extension.json` and `options.schema.json` for machine-readable metadata.

Example config:

```json
{
  "window": { "title": "Demo", "width": 900, "height": 700 },
  "entry": { "kind": "file", "value": "app.html" },
  "extensions": {
    "justjavac/lepus-fs": true,
    "justjavac/lepus-path": {}
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

## Notes

- These extensions currently target `native`.
- `fs.open(...)` and `fs.openFile(...)` return a resource id in the `rid` field.
- `path` is pure and side-effect free.
- `dialog`, `shell`, `notification`, `tray`, and `globalHotkey` currently ship
  Windows-native implementations in this repository.
- `clipboard` follows the upstream
  [`justjavac/clipboard`](https://mooncakes.io/docs/justjavac/clipboard)
  platform matrix.


