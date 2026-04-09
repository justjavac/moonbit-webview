///|
/// Converts one manifest size hint into the runtime size hint enum.
fn runtime_size_hint(size_hint : @manifest.WindowSizeHint) -> @webview.SizeHint {
  match size_hint {
    None => @webview.SizeHint::None
    Fixed => @webview.SizeHint::Fixed
    Min => @webview.SizeHint::Min
    Max => @webview.SizeHint::Max
  }
}

///|
/// Converts one manifest window into the runtime window config shape.
fn runtime_window_config(
  window : @manifest.WindowManifest,
) -> @wvrt.WindowConfig {
  @wvrt.WindowConfig::new(
    window.title,
    window.width,
    window.height,
    size_hint=runtime_size_hint(window.size_hint),
  )
}

///|
/// Converts one manifest entry into the runtime entry shape.
fn runtime_entry(entry : @manifest.AppEntry) -> @wvrt.AppEntry {
  match entry {
    Html(html) => @wvrt.AppEntry::Html(html)
    Url(url) => @wvrt.AppEntry::Url(url)
    File(path) => @wvrt.AppEntry::File(path)
    Asset(path) => @wvrt.AppEntry::Asset(path)
  }
}

///|
/// Converts one manifest secondary window into the runtime config shape.
fn runtime_window_manifest(
  window : @manifest.AppWindowManifest,
) -> @wvrt.AppWindowConfig {
  @wvrt.AppWindowConfig::new(
    window.id,
    runtime_window_config(window.window),
    runtime_entry(window.entry),
  )
}

///|
/// Converts a full manifest into the lower-level runtime config shape.
fn runtime_config_from_manifest(
  manifest : @manifest.AppManifest,
) -> @wvrt.AppConfig {
  @wvrt.AppConfig::new(
    runtime_window_config(manifest.window),
    runtime_entry(manifest.entry),
    debug=manifest.debug,
    windows=manifest.windows.map(window => runtime_window_manifest(window)),
  )
}
