///|
/// Installs the JavaScript namespace bootstrap for one extension.
fn install_extension_namespace(
  webview : @webview.Webview,
  extension_namespace : String,
) -> Unit {
  install_runtime_script(
    webview,
    make_extension_namespace_script(extension_namespace),
  )
}

///|
/// Installs extension-owned JavaScript helper scripts.
fn install_extension_scripts(
  webview : @webview.Webview,
  scripts : Array[String],
) -> Unit {
  for script in scripts {
    install_runtime_script(webview, script)
  }
}

///|
/// Builds the JavaScript snippet that ensures an extension namespace exists.
fn make_extension_namespace_script(extension_namespace : String) -> String {
  let moonbit_name_js = Json::string(moonbit_global_name_value).stringify()
  let extension_name_js = Json::string(extension_namespace).stringify()
  "(function() {" +
  "  const moonbitName = " +
  moonbit_name_js +
  ";" +
  "  const extensionName = " +
  extension_name_js +
  ";" +
  "  const moonbit = window[moonbitName];" +
  "  if (moonbit && typeof moonbit['@@ensureExtension'] === 'function') {" +
  "    moonbit['@@ensureExtension'](extensionName);" +
  "  }" +
  "})();"
}

///|
/// Builds the JavaScript snippet that emits one extension event payload.
fn make_extension_emit_script(
  extension_namespace : String,
  event_name : String,
  payload_json : String,
) -> String {
  let moonbit_name_js = Json::string(moonbit_global_name_value).stringify()
  let extension_name_js = Json::string(extension_namespace).stringify()
  let event_name_js = Json::string(event_name).stringify()
  "(function() {" +
  "  const moonbit = window[" +
  moonbit_name_js +
  "];" +
  "  if (!moonbit || !moonbit.events || typeof moonbit.events['@@emitExtensionEvent'] !== 'function') {" +
  "    return;" +
  "  }" +
  "  moonbit.events['@@emitExtensionEvent'](" +
  extension_name_js +
  ", " +
  event_name_js +
  ", " +
  payload_json +
  ");" +
  "})();"
}
