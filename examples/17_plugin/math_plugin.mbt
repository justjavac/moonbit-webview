///|
struct SumPayload {
  left : Int
  right : Int
} derive(ToJson, FromJson, Eq, Show)

///|
struct SumReply {
  total : Int
} derive(ToJson, FromJson, Eq, Show)

///|
struct ComputedNotice {
  message : String
} derive(ToJson, FromJson, Eq, Show)

///|
pub fn plugin() -> @webview.Plugin {
  @webview.Plugin::new("math", fn(plugin) {
    plugin.command("sum", fn(payload : SumPayload) {
      let reply = SumReply::{ total: payload.left + payload.right }
      plugin.emit("computed", ComputedNotice::{
        message: "MoonBit computed " + reply.total.to_string(),
      })
      reply
    })
  })
}
