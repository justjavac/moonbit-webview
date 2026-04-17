# Repository Guidelines

## Project Structure
- `src/`: low-level `justjavac/lepus` binding and native support.
- `manifest/`: `justjavac/lepus_manifest`; owns `app.json`-style manifest types and declarative extension settings.
- `core/`: `justjavac/lepus_core`; owns ops dispatch, JS bridge installation, extension host, and `window.__MoonBit__`.
- `runtime/`: `justjavac/lepus_runtime`; owns `App`, window lifecycle, and extension installation on top of `core`.
- `bootstrap/`: `justjavac/lepus_bootstrap`; owns manifest parsing, editing, and config documents.
- `app/`: `justjavac/lepus_app`; owns high-level app composition from manifests plus explicitly linked extensions. `create_app(...)` and `create_app_from_file(...)` are the preferred public story; planning helpers do not need to remain public in future breaking refactors.
- `extensions/`: built-in webview extensions such as `fs`, `path`, `dialog`, `clipboard`; each extension owns its own metadata plus JS/MBT binding and is intended for opt-in linking so apps only ship the capabilities they use.
- `catalog/`: discovery, indexing, schema validation, and linking-plan helpers for metadata-driven tooling.
- `tooling/`: AI- and developer-facing catalog queries plus generated registry-module edits; future expansion can add scaffold, install, doctor, and manifest mutation workflows.
- `examples/`: runnable demos; prefer keeping [examples/Readme.md](examples/Readme.md) in sync with the actual examples.
- `test/`: root integration tests.
- `lib/`, `build/`, `_build/`, `target/`: generated or vendored artifacts.

## Build And Test
- `moon check --target native`
- `moon -C manifest check --target native`
- `moon -C core check --target native`
- `moon -C runtime check --target native`
- `moon -C bootstrap check --target native`
- `moon -C app check --target native`
- `moon -C catalog check --target native`
- `moon -C tooling check --target native`
- `moon -C extensions test --target native`
- `moon -C test test --target native`
- `moon -C examples build --target native`
- `moon fmt` or `moon fmt --check`
- `moon info --target native`, `moon -C manifest info --target native`, `moon -C core info --target native`, `moon -C runtime info --target native`, `moon -C bootstrap info --target native`, `moon -C app info --target native`, `moon -C catalog info --target native`, `moon -C tooling info --target native`, `moon -C extensions info --target native`

Use the smallest relevant validation set while iterating, then run the broader native checks before handing off larger refactors.

## Coding Conventions
- Use MoonBit with 2-space indentation and `///|` top-level separators.
- Keep public APIs documented with `///|` comments.
- Use `PascalCase` for types and enum variants, `snake_case` for functions, methods, fields, and locals.
- Prefer small JSON bridge structs deriving `ToJson`, `FromJson`, `Eq`, and `Show`.
- Prefer the public API shape:
  - low-level: `Webview::new(...)`
  - core: `install_extension(...)`, `Extension::new(...)`, `ExtensionSpec::new(...)`
  - manifest: `AppManifest::new(...)`
  - bootstrap: `AppManifestDocument::new(...)`
  - app: `create_app(...)`, `create_app_from_file(...)`
- Treat `plan_app(...)`, `plan_app_document(...)`, and `AppPlan` as removable implementation details unless a strong external use case clearly survives review.
- Keep JS-facing examples and docs aligned with the current runtime surface:
  - `window.__MoonBit__.core.invokeOp(...)`
  - `window.__MoonBit__.events.on(...)`
  - `window.__MoonBit__.<extension>.*`

## Architectural Rules
- Keep dependencies acyclic and flowing downward: `src <- core <- runtime <- app`, `manifest <- bootstrap`, `core <- extensions`.
- `bootstrap` must stay declarative; it should parse and edit manifest data, not install extensions or create windows.
- `runtime` should orchestrate lifecycle only; JS bridge plumbing, op registration, and extension host behavior belong in `core`.
- Treat Lepus as a framework first: applications should link only the extensions they explicitly choose so shipped binaries stay small.
- Keep linking explicit at build time. Metadata, catalogs, and tools may generate project edits or registry code, but they must not imply auto-linking every built-in extension.
- `app` should stay focused on ergonomic composition from `manifest + explicitly linked extensions` into a runtime app, with a small and clear public API.
- AI support should primarily live in metadata, catalog/discovery, diagnostics, scaffolding, and manifest-editing tooling rather than in the default runtime of every app.
- Treat runtime introspection as a debug aid, not as the main composition mechanism.
- Each built-in extension should keep its own `extension.json` and `options.schema.json`, plus its own JS/MBT binding files, so AI and tooling can reason about extensions locally.

## Commit And PR Guidance
- Use Conventional Commit style such as `feat(app):`, `fix(examples):`, `docs:`.
- Keep subjects imperative and scoped.
- In PRs, summarize behavior changes, note platform-specific impact, and list the validation commands you ran.
