///|
/// Installs a runtime script both for future page loads and the current document.
fn install_runtime_script(webview : @webview.Webview, script : String) -> Unit {
  webview.init(script)
  webview.dispatch(fn() { webview.eval(script) })
}
