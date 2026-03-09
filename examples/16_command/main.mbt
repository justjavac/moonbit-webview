struct SumPayload {
  left : Int
  right : Int
} derive(ToJson, FromJson, Eq, Show)

struct SumReply {
  total : Int
} derive(ToJson, FromJson, Eq, Show)

struct NativeNotice {
  message : String
} derive(ToJson, FromJson, Eq, Show)

fn main {
  let webview = @webview.Webview::new(debug=1)
  let bridge = @webview.CommandBridge::new(webview)
  bridge.handle("sum", fn(payload : SumPayload) {
    let reply = SumReply::{ total: payload.left + payload.right }
    bridge.send("notice", NativeNotice::{
      message: "MoonBit computed " + reply.total.to_string(),
    })
    reply
  })
  webview.set_title("MoonBit Command Bridge")
  webview.set_size(860, 640, @webview.SizeHint::None)
  webview.set_html(resource)
  webview.run()
}
