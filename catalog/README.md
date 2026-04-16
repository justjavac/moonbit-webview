# lepus_catalog

Metadata discovery and link-planning helpers for Lepus extensions.

`lepus_catalog` is intentionally metadata-only.

- it scans explicit search roots for `extension.json`
- it loads descriptors and schemas without importing extension code
- it builds deterministic link plans from metadata dependencies

Built-in and third-party extensions use the same catalog path: if they expose
the same metadata files, they can be discovered the same way.
