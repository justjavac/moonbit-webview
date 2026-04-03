///|
let moonbit_global_name = "__MoonBit__"

///|
let moonbit_op_binding_name = "__moonbit_op_dispatch"

///|
fn install_moonbit_core_runtime(webview : @webview.Webview) -> Unit {
  install_runtime_script(webview, make_moonbit_core_script())
}

///|
fn register_moonbit_op(webview : @webview.Webview, op_name : String) -> Unit {
  install_runtime_script(webview, make_moonbit_register_op_script(op_name))
}

///|
fn make_moonbit_core_script() -> String {
  render_js_template(moonbit_core_template_resource, [
    replacement(
      "__MOONBIT_NAME_JS__",
      Json::string(moonbit_global_name).stringify(),
    ),
    replacement(
      "__BINDING_NAME_JS__",
      Json::string(moonbit_op_binding_name).stringify(),
    ),
  ])
}

///|
fn make_moonbit_register_op_script(op_name : String) -> String {
  render_js_template(moonbit_register_op_template_resource, [
    replacement(
      "__MOONBIT_NAME_JS__",
      Json::string(moonbit_global_name).stringify(),
    ),
    replacement("__OP_NAME_JS__", Json::string(op_name).stringify()),
  ])
}

///|
test "moonbit core script renders embedded template" {
  let script = make_moonbit_core_script()
  assert_true(script.contains("const moonbitName = \"__MoonBit__\";"))
  assert_true(script.contains("const bindingName = \"__moonbit_op_dispatch\";"))
  assert_false(script.contains("__MOONBIT_NAME_JS__"))
  assert_false(script.contains("__BINDING_NAME_JS__"))
}

///|
test "moonbit register op script renders embedded template" {
  let script = make_moonbit_register_op_script("op_demo_sum")
  assert_true(script.contains("const opName = \"op_demo_sum\";"))
  assert_false(script.contains("__OP_NAME_JS__"))
}
