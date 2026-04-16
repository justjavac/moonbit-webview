///|
/// Renders the JavaScript helper that exposes Node-style convenience wrappers for `path`.
fn path_helper_script() -> String {
  @core.render_js_template(path_helper_template_resource, [
    @core.replacement(
      "__ROOT_NAME_JS__",
      Json::string(@core.moonbit_global_name()).stringify(),
    ),
    @core.replacement("__EXTENSION_NAME_JS__", Json::string("path").stringify()),
    @core.replacement(
      "__PATH_SEP_JS__",
      Json::string("\{@mbpath.sep}").stringify(),
    ),
    @core.replacement(
      "__PATH_DELIMITER_JS__",
      Json::string("\{@mbpath.delimiter}").stringify(),
    ),
  ])
}
