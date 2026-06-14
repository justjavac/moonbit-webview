name = "justjavac/webview"

version = "0.1.10"

import {
  "justjavac/ffi@0.2.0",
  "moonbitlang/x@0.4.40",
}

readme = "README.md"

repository = "https://github.com/justjavac/moonbit-webview"

license = "MIT"

keywords = [ "webview", "webui", "gui", "web", "desktop-app" ]

description = "MoonBit bindings for webview, a tiny library for creating web-based desktop GUIs."

warnings = ""

preferred_target = "native"

supported_targets = "+native"

options(
  source: "src",
)
