# Repository Guidelines

## Project Structure
- `src/`: low-level `justjavac/webview` binding and native support.
- `runtime/`: `justjavac/webview_runtime`; owns `App`, `Extension`, ops dispatch, JS bridge, and `window.__MoonBit__`.
- `bootstrap/`: `justjavac/webview_bootstrap`; owns `app.json` parsing, editing, and config documents.
- `app/`: `justjavac/webview_app`; owns high-level app creation, extension ordering, and app-style installation.
- `catalog/`: `justjavac/webview_catalog`; owns built-in extension metadata and lookup helpers.
- `extensions/`: built-in webview extensions such as `fs`, `path`, `dialog`, `clipboard`.
- `examples/`: runnable demos; prefer keeping [examples/Readme.md](examples/Readme.md) in sync with the actual examples.
- `test/`: root integration tests.
- `lib/`, `build/`, `_build/`, `target/`: generated or vendored artifacts.

## Build And Test
- `moon check --target native`
- `moon -C runtime check --target native`
- `moon -C bootstrap check --target native`
- `moon -C app check --target native`
- `moon -C catalog test --target native`
- `moon -C extensions test --target native`
- `moon -C test test --target native`
- `moon -C examples build --target native`
- `moon fmt` or `moon fmt --check`
- `moon info --target native`, `moon -C runtime info --target native`, `moon -C bootstrap info --target native`, `moon -C app info --target native`, `moon -C catalog info --target native`, `moon -C extensions info --target native`

Use the smallest relevant validation set while iterating, then run the broader native checks before handing off larger refactors.

## Coding Conventions
- Use MoonBit with 2-space indentation and `///|` top-level separators.
- Keep public APIs documented with `///|` comments.
- Use `PascalCase` for types and enum variants, `snake_case` for functions, methods, fields, and locals.
- Prefer small JSON bridge structs deriving `ToJson`, `FromJson`, `Eq`, and `Show`.
- Follow the current public API shape:
  - low-level: `Webview::new(...)`
  - runtime: `install_extension(...)`, `Extension::new(...)`
  - bootstrap: `BootstrapAppConfig::new(...)`
  - app: `AppExtension::new(...)`, `create_app(...)`, `create_app_from_file(...)`
- Keep JS-facing examples and docs aligned with the current runtime surface:
  - `window.__MoonBit__.core.ops.*`
  - `window.__MoonBit__.events.on(...)`
  - `window.__MoonBit__.<extension>.*`

## Commit And PR Guidance
- Use Conventional Commit style such as `feat(app):`, `fix(examples):`, `docs:`.
- Keep subjects imperative and scoped.
- In PRs, summarize behavior changes, note platform-specific impact, and list the validation commands you ran.
