///|
/// MoonBit bridge example modeled after Tauri Hellworld but in MoonBit style.
/// It exposes a host function `greet` to the frontend and renders a minimal UI.
fn main {
  let webview = @webview.Webview::new(debug=1)
  webview.set_title("MoonBit Tauri-like Hello World")
  webview.set_size(800, 600, @webview.SizeHint::None)
  webview.bind("greet", fn(id, req) {
    let id = @ffi.from_cstr(id)
    let raw_req = @ffi.from_cstr(req)
    let request_json : Result[Json, _] = try? @json.parse(raw_req)
    let name = match request_json {
      Err(_) => "world"
      Ok(request_json) => {
        let args : Result[Array[String], _] = try? @json.from_json(request_json)
        match args {
          Err(_) => "world"
          Ok(args) => if args.length() > 0 { args[0] } else { "world" }
        }
      }
    }
    let result = "{\"message\":\"Hello \{name}, You have been greeted from Moonbit!\", \"req\":" +
      raw_req +
      "}"
    println(id)
    println(raw_req)
    println(result)
    webview.response(id, 0, result)
  })
  // Load embedded HTML resource produced from index.html via pre-build
  webview.set_html(resource)
  webview.run()
}
