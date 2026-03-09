# AGENTS Guide

This document provides concise guidance for agents working in this repository. It focuses on build/lint/test workflows, code style, plugin integration, and example usage.

## 1) Build / Lint / Test Commands
- Prerequisites: Moon toolchain installed; run from repo root.

- Formatting and linting
  - `moon fmt --check` (enforce formatting)
  - `moon fmt` (auto-format)

- Type and project checks
  - `moon check --target native` (syntax/semantics for native target)
  - `moon check --target native --deny-warn` (treat warnings as errors)

- Building
  - `moon -C examples build --target native`

- Testing
  - `moon -C test test --target native` (full test suite)
  - `moon test --target native --doc` (documentation tests)
  - Run a single test file (example): `moon -C test test/webview_test.mbt --target native`

- Dependency management
  - `moon update`
  - `moon install`
  - `moon version --all`

- Quick validation (local)
  - `moon fmt --check && moon check --target native && moon -C test test --target native`

## 2) Code Style Guidelines
- Language basics
  - Indentation: 2 spaces
  - Public APIs documented with doc comments using the `///|` style blocks
  - Expose public surface via `pub` declarations

- Types and naming
  - Types: PascalCase (e.g., Webview, NativeHandleKind, SizeHint)
  - Local/members: camelCase
  - Opaque handles: clear naming (e.g., Webview_t)

- Public API style
  - Constructors: `Name::new(...)` or `pub fn Name::new(...)`
  - Methods receive `self` (or specific receiver) as the first parameter
  - Favor explicit return types; avoid unnecessary mutability

- Error handling
  - Guard clauses; use `abort("message")` for unrecoverable issues
  - Return meaningful errors, propagate details in messages

- Imports and module usage
  - Keep surface area small; re-export minimally
  - Fully qualify external bindings to avoid collisions

- Styling and formatting
  - Trailing comma style for multi-line calls
  - Clear line breaks in long signatures
  - Derive explicit JSON (ToJson/FromJson) where cross-boundary data is exchanged

- Documentation and examples
  - Document public APIs with purpose and side effects
  - Include small inline examples as needed using fenced blocks

- Tests
  - Put tests under `test/` and mirror public API surface
  - Use doc tests where feasible
  - Prefer isolated unit tests for easier debugging

- Accessibility and portability
  - Write portable code across GTK/Cocoa/Win32; guard backend-specific calls
  - Avoid hard-coded paths; rely on platform-neutral abstractions

- Examples in this codebase
  - Refer to `src/webview.mbt` for a well-documented public API example

## 3) Plugins Guide

### Overview
- Moon-based plugin system to expose host functionality to JavaScript in the embedded webview.
- Plugins export a `plugin()` function returning `@webview.Plugin`.
- Install via `webview.install_plugin(@<name>.plugin())` to expose under `window.MoonBitPlugins` in JS.

### Structure & conventions
- Plugins live under `plugins/<name>/` and export `plugin()`.
- Public commands: `plugin.command_result("cmd", fn(payload : PayloadType) { ... })`.
- Payloads should be JSON-derivable via `ToJson`/`FromJson` (and Show/Eq as needed).
- Plugins may emit activity via `plugin.emit` for observability.

### Data types & payloads
- Keep payloads small; derive `ToJson`/`FromJson` for cross-boundary use.
- Use stable field names and shapes to avoid JS breakages.

### Registration & usage
- Host example: `webview.install_plugin(@fs.plugin())` exposes `window.MoonBitPlugins.fs` in JS.
- Security: install trusted plugins only; validate inputs.

### Testing & examples
- MBT tests can live in the plugin module or under `test/`.
- Use existing examples as integration tests for plugin behavior.

### Security & permissions
- Gate access; validate inputs; prefer sandboxed operations.

### Examples
- Minimal Plugin Template
  - Quick-start skeleton for a tiny plugin to demonstrate host-JS binding.
  - Code snippet (Moon MBT) for a minimal plugin:
  ```moonbit
  ///|
  pub fn plugin() -> @webview.Plugin {
    @webview.Plugin::new("minimal", fn(plugin) {
      plugin.command_result("ping", fn(payload : PingPayload) {
        Ok(PingReply{ pong: true })
      })
    })
  }
  ///|
  struct PingPayload { } derive(ToJson, FromJson, Show, Eq)
  ///|
  struct PingReply { pong : Bool } derive(ToJson, FromJson, Show, Eq)
  ```
  
  - Host-side usage:
    - Build the plugin module and install from host: `webview.install_plugin(@minimal.plugin())`.
  - In JS (example): `window.MoonBitPlugins.minimal.ping({})` returns `{ pong: true }`.
  - Quick test hints: add a tiny MBT test file under `test/` to validate a ping call.

## 4) Examples Guide

### Structure
- Each example contains: packaging (moon.mod.json or moon.pkg), a `main.mbt` entry, and optional `bundle.mbt`.

### Running
- Build: `moon -C examples build --target native`.
- Run: execute an MBT file or rely on provided test runner.
- Debug: inspect artifacts under `examples/target`.

### Testing & docs
- Run example tests: `moon -C test test --target native`.
- Update `examples/<name>/Readme.md` with current usage.

### Patterns
- Common templates: `examples/12_embed`, `examples/18_plugin_fs`, `examples/17_plugin`.

## 5) Quick References

- Packaging: `moon.mod.json` at repo root for module layout and dependencies.
- Tests: `test/webview_test.mbt`; other tests under `test/`.
- CI: see `.github/workflows/ci.yml` for automated flows.

This document should be kept up to date as the repository evolves. Align guidelines with MoonBit agent guides in the repository as needed.
