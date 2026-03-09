///|
/// MoonBit bridge example modeled after Tauri Hellworld but in MoonBit style.
/// It exposes a host function `greet` to the frontend and renders a minimal UI.

///|
fn main {
  let webview = @webview.Webview::new(debug=1)
  webview.set_title("MoonBit Tauri-like Hello World")
  webview.set_size(800, 600, @webview.SizeHint::None)
  webview.bind("greet", fn(id, req) {
    let id = @ffi.from_cstr(id)
    let req = @ffi.from_cstr(req)
    let result = "{\"message\":\"Hello \{req}, You have been greeted from Moonbit!\", \"req\":" +
      req +
      "}"
    println(id)
    println(req)
    println(result)
    webview.response(id, 0, result)
  })
  // Load embedded HTML resource produced from index.html via pre-build
  webview.set_html(resource)
  webview.run()
}
