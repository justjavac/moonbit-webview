# FS Extension

Native filesystem extension for `justjavac/lepus` applications.

It exposes a Node-first API under `window.__MoonBit__.fs` and keeps a rid-based
streaming API for streaming and binary-style workflows.

This is a reusable MoonBit module, so applications can add it as a dependency
and install it without wiring command bindings manually.

## Install

```moonbit
import {
  "extensions/fs" @fs,
  "justjavac/lepus_core" @core,
  "justjavac/lepus" @webview,
}

fn main {
  let webview = @webview.Webview::new(debug=1)
  @core.install_extension(webview, @fs.extension())
  webview.run()
}
```

For app-style startup, install it through `justjavac/lepus_app`:

```moonbit
import {
  "extensions/fs" @fs,
  "justjavac/lepus_app" @app,
  "justjavac/lepus_manifest" @manifest,
  "justjavac/lepus_runtime" @wvrt,
}

fn main {
  let manifest = @manifest.AppManifest::new(
    @manifest.WindowManifest::new("FS Demo", 900, 700),
    @manifest.AppEntry::Html("<html></html>"),
    debug=1,
  )
  let registry = @app.ExtensionRegistry::new()
  let _ = registry.register(@fs.spec())
  let runtime : @wvrt.App = match @app.create_app(manifest, registry) {
    Ok(app) => app
    Err(error) => abort(error)
  }
  runtime.run()
}
```

## JavaScript API

```js
await window.__MoonBit__.fs.writeFile("demo.txt", "Hello from MoonBit");

const loaded = await window.__MoonBit__.fs.readFile("demo.txt");

const stat = await window.__MoonBit__.fs.stat("demo.txt");
```

If you want the native absolute path before opening a file, ask `stat` not to
throw on missing entries:

```js
const stat = await window.__MoonBit__.fs.stat("demo.txt", {
  throwIfNoEntry: false,
});
```

### Commands

- `fs.readFile(path, options?)`
  Returns `{ path, content, bytes_read }`.
- `fs.readTextFile(path, options?)`
  Tauri-style alias for `readFile`.
- `fs.writeFile(path, content, options?)`
  Returns `{ path, written, bytes_written }`.
- `fs.writeTextFile(path, content, options?)`
  Tauri-style alias for `writeFile`.
- `fs.appendFile(path, content, options?)`
  Returns `{ path, written, bytes_written }`.
- `fs.stat(path, options?)`
  Returns `{ path, exists, size, is_file, is_dir, is_readonly }`.
- `fs.readdir(path, options?)`
  Returns `{ path, entries }`.
- `fs.mkdir(path, options?)`
  Returns `{ path, created }`.
- `fs.unlink(path)`
  Returns `{ removed }`.
- `fs.rm(path, options?)`
  Returns `{ path, removed }`.
- `fs.rename(oldPath, newPath)`
  Returns `{ old_path, new_path, renamed }`.
- `fs.copyFile(src, dest, options?)`
  Returns `{ src, dest, copied, bytes_copied }`.
- `fs.realpath(path)`
  Returns `{ path }` and follows the native filesystem resolution rules.
- `fs.truncate(path, lenOrOptions?)`
  Returns `{ path, size, truncated }`. `len` defaults to `0`.
- `fs.size(path)`
  Returns `{ path, size }`. Files report byte size; directories sum descendant file sizes recursively.
- `fs.open(path, mode?)`
  Returns `{ rid }`.
- `fs.openFile(path, options?)`
  Node/Tauri-style opener that maps common flags/options onto the rid-based streaming API and returns `{ rid }`.
- `fs.read(rid, size)`
  Returns `{ content, bytes_read, eof }`.
- `fs.write(rid, content)`
  Returns `{ bytes_written }`.
- `fs.seek(rid, offset, whence?)`
  `whence` is `"set"`, `"current"`, or `"end"`.
- `fs.fstat(rid)`
  Returns `{ path, size, position, eof, exists, is_file, is_dir }`.
- `fs.flush(rid)`
  Flushes buffered writes.
- `fs.close(rid)`
  Closes the open resource.
- `fs.exists(path)`
  Returns `{ exists }`.

## Events

The extension emits an `activity` event after successful operations:

```js
window.__MoonBit__.events.on("fs.activity", (event) => {
  console.log(event);
});
```

Event payload shape:

```js
{
  operation: "readFile" | "writeFile" | "appendFile" | "stat" | "readdir" | "mkdir" | "unlink" | "rm" | "open" | "read" | "write" | "seek" | "fstat" | "flush" | "close",
  path: string | null,
  rid: number | null,
  bytes: number | null
}
```

## Notes

- This extension currently targets the native backend.
- This extension exposes direct host filesystem access. Only use it with trusted,
  local HTML/JavaScript content; do not install it in webviews that navigate to
  untrusted or remote pages.
- Use relative paths like `demo.txt` for portable examples across macOS, Linux,
  and Windows.
- Use `fs.stat(path, { throwIfNoEntry: false })` when the UI should display the
  resolved absolute location before the file exists.
- `open` stores the resolved absolute path for each resource id, so
  `fstat({ rid })` reports an absolute `path`.
- Installing `fs` grants direct host filesystem access for that webview or app.
- `read` and `write` use UTF-8 text payloads.
- `readFile`, `writeFile`, and `appendFile` are UTF-8 text helpers. For
  streaming or binary-oriented workflows, keep using the rid-based API with
  `open`, `read`, `write`, `seek`, and `flush`.
- The path API is intentionally closer to Node.js `fs/promises`, with a few
  Tauri-style aliases such as `readTextFile`, `writeTextFile`, and `remove`.
- `openFile` currently supports common Node-style flags and read/write/append
  option combinations, but does not yet model every lower-level open semantic
  such as strict `create_new`.

