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
pub fn extension() -> @runtime.Extension {
  @runtime.Extension::new("math", fn(extension) {
    extension.op("sum", fn(payload : SumPayload) {
      let reply = SumReply::{ total: payload.left + payload.right }
      extension.emit("computed", ComputedNotice::{
        message: "MoonBit computed " + reply.total.to_string(),
      })
      reply
    })
  })
}
