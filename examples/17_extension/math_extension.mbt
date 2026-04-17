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
pub fn extension() -> @core.Extension {
  @core.Extension::new("examples/math", "math", fn(extension) {
    extension.op("sum", fn(payload : SumPayload) {
      let reply = SumReply::{ total: payload.left + payload.right }
      extension.emit("computed", ComputedNotice::{
        message: "MoonBit computed " + reply.total.to_string(),
      })
      reply
    })
  })
}
