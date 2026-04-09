///|
/// Host name used for the in-process asset origin on Windows/WebView2.
let asset_origin_host_name = "app.localhost"

///|
/// Opaque native asset origin state managed by the Windows runtime shim.
#external
priv type AssetOriginState

///|
extern "C" fn asset_origin_is_windows_ffi() -> Bool = "lepus_runtime_asset_origin_is_windows"

///|
extern "C" fn asset_origin_state_is_null_ffi(state : AssetOriginState) -> Bool = "moonbit_is_null"

///|
#borrow(host, root_dir, default_entry)
extern "C" fn asset_origin_install_ffi(
  controller : Int64,
  host : Bytes,
  root_dir : Bytes,
  default_entry : Bytes,
) -> AssetOriginState = "lepus_runtime_asset_origin_install"

///|
/// Loads a file-backed frontend bundle through a synthetic secure origin.
fn load_asset_entry(webview : @webview.Webview, raw_path : String) -> Unit {
  guard asset_origin_is_windows_ffi() else {
    abort("AppEntry::Asset currently supports Windows native builds only")
  }
  let entry_path : @path.Path = raw_path
  let resolved_entry = normalize_asset_origin_path(
    entry_path.resolve().to_string(),
  )
  let (root_dir, default_entry) = split_asset_entry_path(resolved_entry)
  guard default_entry != "" else {
    abort("AppEntry::Asset requires a file path, got directory: " + raw_path)
  }
  let state = asset_origin_install_ffi(
    webview.get_native_handle(@webview.NativeHandleKind::Browser),
    @ffi.to_wstr(asset_origin_host_name),
    @ffi.to_wstr(root_dir),
    @ffi.to_wstr(default_entry),
  )
  guard !asset_origin_state_is_null_ffi(state) else {
    abort(
      "AppEntry::Asset failed to install the Windows asset origin for: " +
      raw_path,
    )
  }
  webview.navigate(asset_origin_url())
}

///|
/// Returns the secure in-process URL used for asset-backed entries.
fn asset_origin_url() -> String {
  "https://" + asset_origin_host_name + "/"
}

///|
/// Rewrites path separators so asset origin splitting is stable on Windows.
fn normalize_asset_origin_path(path : String) -> String {
  let builder = StringBuilder::new(size_hint=path.length())
  for _, ch in path {
    builder.write_char(if ch == '\\' { '/' } else { ch })
  }
  builder.to_string()
}

///|
/// Splits an absolute asset entry path into the bundle root directory and the
/// file name used as the synthetic origin's default document.
fn split_asset_entry_path(resolved_entry : String) -> (String, String) {
  let mut last_separator = -1
  for index, ch in resolved_entry {
    if ch == '/' {
      last_separator = index
    }
  }
  guard last_separator >= 0 else {
    abort("AppEntry::Asset resolved to an unexpected path: " + resolved_entry)
  }
  (
    resolved_entry.unsafe_substring(start=0, end=last_separator),
    resolved_entry.unsafe_substring(
      start=last_separator + 1,
      end=resolved_entry.length(),
    ),
  )
}
