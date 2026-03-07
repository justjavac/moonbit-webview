# Plugins

This workspace contains reusable MoonBit plugins built on top of
`justjavac/webview`'s plugin system.

Most applications should install them directly on a `Webview` with
`webview.install_plugin(...)`. The lower-level `PluginHost` API is still
available when you need a custom JS namespace or bridge configuration.

## Layout

- `fs/`: handle-based filesystem plugin for native webview applications

## Usage

Add the workspace as a local dependency:

```json
{
  "deps": {
    "plugins": {
      "path": "../plugins"
    }
  }
}
```

Then import the plugin package you want in your `moon.pkg`:

```moonbit
import {
  "plugins/fs",
  "justjavac/webview",
}
```

And install it from your main program:

```moonbit
fn main {
  let webview = @webview.Webview::new(debug=1)
  webview.install_plugin(@fs.plugin())
  webview.set_html("<script>console.log(window.MoonBitPlugins.fs);</script>")
  webview.run()
}
```

## Notes

- These plugins currently target `native`.
- JS calls return `CommandResponse` values, so check `status` before reading
  `payload`.
- Plugins may expose native utility commands in addition to handle-based APIs.
  For example, `fs.resolvePath({ path })` resolves a portable input into a
  platform-specific absolute path.
- Plugin events are available through `window.MoonBitPlugins.<plugin>["@@on"]`
  and `["@@onEvent"]`.
- Use `webview.plugin_host()` only when you need direct access to the default
  `PluginHost`.
