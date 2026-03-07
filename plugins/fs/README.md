# FS Plugin

Native filesystem plugin for `justjavac/webview` applications.

It exposes a handle-based API under `window.MoonBitPlugins.fs` and is intended
to be installed through `Webview::install_plugin(...)`.

This is a reusable MoonBit module, so applications can add it as a dependency
and install it without wiring command bindings manually.

## Install

```moonbit
import {
  "plugins/fs",
  "justjavac/webview",
}

fn main {
  let webview = @webview.Webview::new(debug=1)
  webview.install_plugin(@fs.plugin())
  webview.run()
}
```

## JavaScript API

All fs commands resolve to `CommandResponse`:

```js
const response = await window.MoonBitPlugins.fs.open({
  path: "demo.txt",
  mode: "w+b",
});

if (response.status === "ok") {
  console.log(response.payload);
} else {
  console.error(response.error);
}
```

### Commands

- `fs.open({ path, mode })`
  Returns `{ handle }`.
- `fs.read({ handle, size })`
  Returns `{ content, bytes_read, eof }`.
- `fs.write({ handle, content })`
  Returns `{ bytes_written }`.
- `fs.seek({ handle, offset, whence })`
  `whence` is `"set"`, `"current"`, or `"end"`.
- `fs.fstat({ handle })`
  Returns `{ path, size, position, eof, exists, is_file, is_dir }`.
- `fs.flush({ handle })`
  Flushes buffered writes.
- `fs.close({ handle })`
  Closes the open handle.
- `fs.exists({ path })`
  Returns `{ exists }`.
- `fs.resolvePath({ path })`
  Returns `{ path }` with the native absolute path for the given input.
- `fs.readDir({ path })`
  Returns `{ entries }`.
- `fs.removeFile({ path })`
  Returns `{ removed }`.

## Events

The plugin emits an `activity` event after successful operations:

```js
window.MoonBitPlugins.fs["@@onEvent"]("activity", (event) => {
  console.log(event);
});
```

Event payload shape:

```js
{
  operation: "open" | "read" | "write" | "seek" | "fstat" | "flush" | "close" | "readDir" | "removeFile",
  path: string | null,
  handle: number | null,
  bytes: number | null
}
```

## Notes

- This plugin currently targets the native backend.
- Use relative paths like `demo.txt` for portable examples across macOS, Linux,
  and Windows.
- `open` stores the resolved absolute path for each handle, so `fstat({ handle
  })` reports an absolute `path`.
- `read` and `write` use UTF-8 text payloads.
- `fstat` is handle-based; if you also want path-based metadata, add a separate
  `stat` command.
