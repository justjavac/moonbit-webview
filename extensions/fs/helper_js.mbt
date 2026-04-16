///|
/// Renders the JavaScript helper that exposes Node-style convenience wrappers for `fs`.
fn fs_helper_script() -> String {
  @core.render_js_template(fs_helper_template_resource, [
    @core.replacement(
      "__ROOT_NAME_JS__",
      Json::string(@core.moonbit_global_name()).stringify(),
    ),
    @core.replacement("__EXTENSION_NAME_JS__", Json::string("fs").stringify()),
  ])
}
