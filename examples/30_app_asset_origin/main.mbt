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
fn[Payload : @json.FromJson] decode_single_argument(
  raw_req : Bytes,
) -> Result[Payload, String] {
  let request_json : Result[Json, _] = try? @json.parse(@ffi.from_cstr(raw_req))
  request_json
  .map_err(fn(err) { err.to_string() })
  .bind(fn(request_json) {
    let request_args : Result[Array[Payload], _] = try? @json.from_json(
      request_json,
    )
    request_args
    .map_err(fn(err) { err.to_string() })
    .bind(fn(request_args) {
      if request_args.length() == 1 {
        Ok(request_args[0])
      } else {
        Err("Expected exactly one argument")
      }
    })
  })
}

///|
fn main {
  let manifest = @manifest.AppManifest::new(
    @manifest.WindowManifest::new("MoonBit Asset Origin", 980, 720),
    @manifest.AppEntry::Asset("30_app_asset_origin/index.html"),
    debug=1,
  )
  let app : @wvrt.App = match
    @app.create_app(manifest, @app.ExtensionRegistry::new()) {
    Ok(app) => app
    Err(error) => abort(error)
  }
  let webview : @webview.Webview = app.webview()
  let mut report : AssetOriginReport? = None
  let mut js_error : String? = None
  webview.bind("reportAssetOriginFailure", fn(id, req) {
    let request_id = @ffi.from_cstr(id)
    let message_result : Result[String, String] = decode_single_argument(req)
    match message_result {
      Ok(message) => {
        js_error = Some(message)
        println("[asset-origin] JS failure: " + message)
      }
      Err(message) => {
        let diagnostic = "Failed to decode asset origin failure payload: " +
          message
        js_error = Some(diagnostic)
        println("[asset-origin] " + diagnostic)
      }
    }
    webview.response(request_id, 0, "null")
  })
  webview.bind("reportAssetOriginResult", fn(id, req) {
    let request_id = @ffi.from_cstr(id)
    let report_result : Result[AssetOriginReport, String] = decode_single_argument(
      req,
    )
    match report_result {
      Ok(value) => {
        report = Some(value)
        println("[asset-origin] received report")
        println(value.to_json().stringify())
      }
      Err(message) => {
        let diagnostic = "Failed to decode asset origin report payload: " +
          message
        js_error = Some(diagnostic)
        println("[asset-origin] " + diagnostic)
      }
    }
    webview.response(request_id, 0, "null")
  })
  app.run()
  match report {
    Some(_) => ()
    None =>
      match js_error {
        Some(message) => abort(message)
        None => abort("Asset origin example exited without a report")
      }
  }
}
