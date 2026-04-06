///|
/// Installs the core `window.__MoonBit__` runtime helpers into a webview.
fn install_moonbit_core_runtime(webview : @webview.Webview) -> Unit {
  install_runtime_script(webview, make_moonbit_core_script())
}

///|
/// Registers one op name with the JavaScript runtime bridge.
fn register_moonbit_op(webview : @webview.Webview, op_name : String) -> Unit {
  install_runtime_script(webview, make_moonbit_register_op_script(op_name))
}

///|
/// Renders the embedded core runtime JavaScript template.
fn make_moonbit_core_script() -> String {
  render_js_template(moonbit_core_template_resource, [
    replacement(
      "__MOONBIT_NAME_JS__",
      Json::string(moonbit_global_name_value).stringify(),
    ),
    replacement(
      "__BINDING_NAME_JS__",
      Json::string(moonbit_op_binding_name_value).stringify(),
    ),
  ])
}

///|
/// Renders the embedded op-registration JavaScript template for one op name.
fn make_moonbit_register_op_script(op_name : String) -> String {
  render_js_template(moonbit_register_op_template_resource, [
    replacement(
      "__MOONBIT_NAME_JS__",
      Json::string(moonbit_global_name_value).stringify(),
    ),
    replacement("__OP_NAME_JS__", Json::string(op_name).stringify()),
  ])
}
