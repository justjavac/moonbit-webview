///|
fn install_runtime_script(webview : @webview.Webview, script : String) -> Unit {
  webview.init(script)
  webview.dispatch(fn() { webview.eval(script) })
}

///|
fn install_optional_runtime_script(
  webview : @webview.Webview,
  script : String?,
) -> Unit {
  match script {
    Some(script) => install_runtime_script(webview, script)
    None => ()
  }
}
