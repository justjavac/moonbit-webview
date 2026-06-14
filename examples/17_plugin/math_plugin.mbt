///|
struct SumPayload {
  left : Int
  right : Int
} derive(ToJson, FromJson, Eq, Debug)

///|
struct SumReply {
  total : Int
} derive(ToJson, FromJson, Eq, Debug)

///|
struct ComputedNotice {
  message : String
} derive(ToJson, FromJson, Eq, Debug)

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
