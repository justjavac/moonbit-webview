///|
fn install_extension_js_helper(
  webview : @webview.Webview,
  script : String?,
) -> Unit {
  install_optional_runtime_script(webview, script)
}
