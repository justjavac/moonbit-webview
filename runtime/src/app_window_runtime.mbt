///|
fn create_app_window(
  id : String,
  config : WindowConfig,
  entry : AppEntry,
  debug : Int,
) -> AppWindow {
  let webview = @webview.Webview::new(debug~)
  install_moonbit_core_runtime(webview)
  apply_window_config(webview, config)
  AppWindow::{ id, webview, config, entry }
}

///|
fn install_existing_extensions(
  webview : @webview.Webview,
  extensions : Array[Extension],
) -> Unit {
  for extension in extensions {
    install_extension(webview, extension)
  }
}

///|
fn app_window_destroy_hook_name(window_id : String) -> String {
  "app-window:" + window_id
}

///|
fn apply_window_config(
  webview : @webview.Webview,
  config : WindowConfig,
) -> Unit {
  webview.set_title(config.title)
  webview.set_size(config.width, config.height, config.size_hint)
}

///|
fn load_app_entry(webview : @webview.Webview, entry : AppEntry) -> Unit {
  match entry {
    Html(html) => webview.set_html(html)
    Url(url) => webview.navigate(url)
    File(path) => webview.navigate(make_file_url(path))
  }
}

///|
fn make_file_url(raw_path : String) -> String {
  let path : @path.Path = raw_path
  let resolved = path.resolve().to_string()
  let normalized = normalize_file_url_path(resolved)
  if normalized.has_prefix("//") {
    "file:" + normalized
  } else if normalized.has_prefix("/") {
    "file://" + normalized
  } else {
    "file:///" + normalized
  }
}

///|
fn normalize_file_url_path(path : String) -> String {
  let builder = StringBuilder::new(size_hint=path.length())
  for _, ch in path {
    builder.write_char(if ch == '\\' { '/' } else { ch })
  }
  builder.to_string()
}
