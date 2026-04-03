///|
fn path_helper_script(root_name : String) -> String? {
  Some(
    @runtime.render_js_template(path_helper_template_resource, [
      @runtime.replacement(
        "__ROOT_NAME_JS__",
        Json::string(root_name).stringify(),
      ),
      @runtime.replacement(
        "__EXTENSION_NAME_JS__",
        Json::string("path").stringify(),
      ),
      @runtime.replacement(
        "__PATH_SEP_JS__",
        Json::string("\{@mbpath.sep}").stringify(),
      ),
      @runtime.replacement(
        "__PATH_DELIMITER_JS__",
        Json::string("\{@mbpath.delimiter}").stringify(),
      ),
    ]),
  )
}

///|
test "path helper script stays with path extension assets" {
  let script = match path_helper_script("__MoonBit__") {
    Some(script) => script
    None => fail("expected path helper script")
  }
  assert_true(script.contains("const rootName = \"__MoonBit__\";"))
  assert_true(script.contains("const extensionName = \"path\";"))
  assert_true(script.contains("@@nodeStylePath"))
}
