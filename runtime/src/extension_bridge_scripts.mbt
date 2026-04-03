///|
fn install_extension_namespace(
  webview : @webview.Webview,
  extension_name : String,
) -> Unit {
  install_runtime_script(
    webview,
    make_extension_namespace_script(extension_name),
  )
}

///|
fn make_extension_namespace_script(extension_name : String) -> String {
  let moonbit_name_js = Json::string(moonbit_global_name).stringify()
  let extension_name_js = Json::string(extension_name).stringify()
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
fn make_extension_emit_script(
  extension_name : String,
  event_name : String,
  payload_json : String,
) -> String {
  let moonbit_name_js = Json::string(moonbit_global_name).stringify()
  let extension_name_js = Json::string(extension_name).stringify()
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
