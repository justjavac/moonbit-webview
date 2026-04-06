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
  let script = make_moonbit_register_op_script("ext:demo/sum")
  assert_true(script.contains("const opName = \"ext:demo/sum\";"))
  assert_false(script.contains("__OP_NAME_JS__"))
}

///|
test "js template renderer replaces repeated tokens" {
  let rendered = render_js_template("before __TOKEN__ middle __TOKEN__ after", [
    replacement("__TOKEN__", "value"),
  ])
  assert_eq(rendered, "before value middle value after")
}
