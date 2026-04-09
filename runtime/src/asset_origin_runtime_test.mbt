///|
struct AssetOriginReport {
  href : String
  origin : String
  is_secure_context : Bool
  cross_origin_isolated : Bool
  shared_array_buffer_type : String
  shared_array_buffer_length : Int?
} derive(ToJson, FromJson, Eq, Debug)

///|
fn asset_origin_test_path(relative_path : String) -> String {
  let root : @path.Path = "testdata/asset_origin"
  root.join(relative_path).resolve().to_string()
}

///|
test "AppEntry::Asset loads through a secure isolated origin" {
  let expected = AssetOriginReport::{
    href: "https://app.localhost/",
    origin: "https://app.localhost",
    is_secure_context: true,
    cross_origin_isolated: true,
    shared_array_buffer_type: "function",
    shared_array_buffer_length: Some(16),
  }
  let config = @lepus_runtime.AppConfig::new(
    @lepus_runtime.WindowConfig::new("runtime-asset-origin", 800, 600),
    @lepus_runtime.AppEntry::Asset(asset_origin_test_path("index.html")),
  )
  let app = @lepus_runtime.App::new(config)
  let webview = app.webview()
  let mut report : AssetOriginReport? = None
  let mut js_error : String? = None
  webview.bind("reportAssetOriginFailure", fn(id, req) {
    let request_id = @ffi.from_cstr(id)
    let message_result : Result[String, String] = decode_single_argument(req)
    match message_result {
      Ok(message) => js_error = Some(message)
      Err(message) =>
        js_error = Some(
          "Failed to decode asset origin failure payload: " + message,
        )
    }
    webview.response(request_id, 0, "null")
    webview.terminate()
  })
  webview.bind("reportAssetOriginResult", fn(id, req) {
    let request_id = @ffi.from_cstr(id)
    let report_result : Result[AssetOriginReport, String] = decode_single_argument(
      req,
    )
    match report_result {
      Ok(value) => report = Some(value)
      Err(message) =>
        js_error = Some(
          "Failed to decode asset origin report payload: " + message,
        )
    }
    webview.response(request_id, 0, "null")
    webview.terminate()
  })
  app.run()
  assert_eq(js_error, None)
  assert_true(report == Some(expected))
}
