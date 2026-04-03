///|
fn fs_helper_script(root_name : String) -> String? {
  Some(
    @runtime.render_js_template(fs_helper_template_resource, [
      @runtime.replacement(
        "__ROOT_NAME_JS__",
        Json::string(root_name).stringify(),
      ),
      @runtime.replacement(
        "__EXTENSION_NAME_JS__",
        Json::string("fs").stringify(),
      ),
    ]),
  )
}

///|
test "fs helper script stays with fs extension assets" {
  let script = match fs_helper_script("__MoonBit__") {
    Some(script) => script
    None => fail("expected fs helper script")
  }
  assert_true(script.contains("const rootName = \"__MoonBit__\";"))
  assert_true(script.contains("const extensionName = \"fs\";"))
  assert_true(script.contains("@@nodeStyleFs"))
}
