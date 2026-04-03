# Scripts

This directory holds small repository maintenance scripts.

## `sync_libwebview.mjs`

Refreshes the vendored native libraries under [`lib/`](lib) from a GitHub Actions run in [`justjavac/libwebview`](https://github.com/justjavac/libwebview).

### Requirements

- Node.js
- GitHub CLI (`gh`)
- access to download workflow artifacts from the target repository

### Usage

Use the latest successful `build` workflow run:

```sh
node ./scripts/sync_libwebview.mjs
```

Use a specific workflow run:

```sh
node ./scripts/sync_libwebview.mjs --run-id 123456789
```

Use a different repository:

```sh
node ./scripts/sync_libwebview.mjs --repo owner/name
```

### What It Updates

- `lib/windows-x64/webview.lib`
- `lib/windows-x64/BUILD_INFO.txt`
- `lib/macos-universal/libwebview.a`
- `lib/macos-universal/BUILD_INFO.txt`
- `lib/linux-x64/libwebview.a`
- `lib/linux-x64/BUILD_INFO.txt`

Downloaded artifacts are staged through `target/libwebview-sync/` and removed before each sync.
