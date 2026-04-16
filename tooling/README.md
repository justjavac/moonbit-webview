# lepus_tooling

AI- and developer-facing helpers built on top of Lepus metadata.

`lepus_tooling` currently focuses on two jobs:

- query extension metadata from explicit search roots
- turn selected extension ids into explicit, reviewable registry-module edits

The generated registry workflow is intentionally build-time only:

- `moon.pkg` import edits stay explicit
- generated `.mbt` source stays explicit
- no runtime plugin loading is introduced
